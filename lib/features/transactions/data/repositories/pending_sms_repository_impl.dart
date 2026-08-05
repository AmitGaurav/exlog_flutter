import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../more/domain/repositories/payee_mapping_repository.dart';
import '../../../more/domain/repositories/user_profile_repository.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/pending_sms_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/services/sms_parsing_orchestrator.dart';
import '../../../../core/utils/api_key_obfuscator.dart';

class PendingSmsRepositoryImpl implements PendingSmsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserProfileRepository _userProfileRepository;
  final PayeeMappingRepository _payeeMappingRepository;
  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;
  final SmsParsingOrchestrator _orchestrator;

  // Guards against overlapping processInbox() runs — e.g. the foreground
  // poll timer firing again before a slow prior run (network latency, a
  // large unprocessed backlog) has finished. Without this, two concurrent
  // runs could both see the same androidSmsInbox doc as "unprocessed" and
  // both pass the transactionReference dedup check before either has
  // written the resulting pendingSmsTransactions doc, creating a duplicate.
  bool _isProcessingInbox = false;

  PendingSmsRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required UserProfileRepository userProfileRepository,
    required PayeeMappingRepository payeeMappingRepository,
    required CategoryRepository categoryRepository,
    required TransactionRepository transactionRepository,
    SmsParsingOrchestrator? orchestrator,
  })  : _firestore = firestore,
        _auth = auth,
        _userProfileRepository = userProfileRepository,
        _payeeMappingRepository = payeeMappingRepository,
        _categoryRepository = categoryRepository,
        _transactionRepository = transactionRepository,
        _orchestrator = orchestrator ?? SmsParsingOrchestrator();

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User not authenticated');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _pendingCol =>
      _firestore.collection('users').doc(_uid).collection('pendingSmsTransactions');

  CollectionReference<Map<String, dynamic>> get _inboxCol =>
      _firestore.collection('users').doc(_uid).collection('androidSmsInbox');

  @override
  Stream<List<Transaction>> watchPending() {
    return _pendingCol.orderBy('detectedAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(Transaction.fromFirestore).toList(),
        );
  }

  @override
  Future<void> approve(Transaction pending) async {
    if (pending.id == null) throw ArgumentError('Pending transaction id must not be null');
    await _transactionRepository.createTransaction(pending);
    await _transactionRepository.incrementSmsImportUsage();
    await _pendingCol.doc(pending.id).delete();
  }

  @override
  Future<void> reject(String pendingId) => _pendingCol.doc(pendingId).delete();

  @override
  Future<void> processInbox() async {
    if (_isProcessingInbox) return;
    _isProcessingInbox = true;
    try {
      await _processInbox();
    } finally {
      _isProcessingInbox = false;
    }
  }

  Future<void> _processInbox() async {
    final auth = _auth.currentUser;
    if (auth == null) return;

    final unprocessed = await _inboxCol.where('status', isEqualTo: 'unprocessed').get();
    if (unprocessed.docs.isEmpty) return;

    final profile = await _userProfileRepository.getProfile();
    final apiKey = deobfuscateApiKey(profile.aiParserConfig.apiKeyObfuscated);
    final categories = await _categoryRepository.getCategories();
    final mappings = await _payeeMappingRepository.getMappings();

    for (final doc in unprocessed.docs) {
      try {
        final body = doc.data()['body'] as String? ?? '';
        final parsed = await _orchestrator.parse(
          message: body,
          aiConfig: profile.aiParserConfig,
          apiKey: apiKey,
          selfNames: profile.selfNames,
        );

        if (parsed == null) {
          await doc.reference.update({'status': 'not_banking'});
          continue;
        }

        if (parsed.transactionReference != null) {
          final existing = await _transactionRepository.findByTransactionReference(parsed.transactionReference!);
          final existingPending = await _pendingCol
              .where('transactionReference', isEqualTo: parsed.transactionReference)
              .limit(1)
              .get();
          if (existing != null || existingPending.docs.isNotEmpty) {
            await doc.reference.update({'status': 'duplicate'});
            continue;
          }
        }

        String? categoryId;
        String? categoryName = 'Others';
        for (final mapping in mappings) {
          if (mapping.matches(parsed.payee)) {
            categoryId = mapping.categoryId;
            categoryName = mapping.categoryName ?? mapping.categoryId;
            break;
          }
        }

        BucketType? bucket;
        if (categoryId != null) {
          for (final c in categories) {
            if (c.id == categoryId) {
              bucket = c.bucket;
              break;
            }
          }
        }

        final draft = Transaction.create(
          amount: parsed.amount,
          payee: parsed.payee,
          categoryId: categoryId,
          categoryName: categoryName,
          bucket: bucket,
          timestamp: parsed.timestamp ?? DateTime.now(),
          type: parsed.type,
          isManual: false,
          userId: _uid,
          bankName: parsed.bankName,
          accountNumber: parsed.accountNumber,
          transactionReference: parsed.transactionReference,
          parsedByAI: parsed.parsedByAI,
          importSource: 'android_sms_auto',
          smsRaw: body,
        );

        final pendingData = draft.toFirestore()
          ..addAll({
            'smsInboxId': doc.id,
            'detectedAt': FieldValue.serverTimestamp(),
            'status': 'pending',
          });
        await _pendingCol.add(pendingData);
        await doc.reference.update({'status': 'processed'});
      } catch (_) {
        await doc.reference.update({'status': 'error'});
      }
    }
  }
}
