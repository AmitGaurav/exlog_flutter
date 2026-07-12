import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/admin_repository.dart';

/// Mirrors iOS's AdminManager: every method reads/writes the flat top-level
/// `users` collection directly. Firestore security rules are the real
/// enforcement boundary — the `premiumTier == 'admin'` gate in the UI (see
/// UserProfileBloc) only controls whether this screen is reachable at all.
class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepositoryImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  @override
  Future<AdminStats> getStatistics() async {
    final snapshot = await _users.get();

    var totalUsers = 0;
    var activeUsers = 0;
    var premiumUsers = 0;
    var freeUsers = 0;
    var lifetimeUsers = 0;
    var yearlyUsers = 0;
    var monthlyUsers = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      totalUsers++;

      final isActive = data['isActive'] as bool? ?? true;
      if (isActive) activeUsers++;

      final tier = PremiumTier.fromString(data['premiumTier'] as String?);
      if (tier != PremiumTier.free) {
        premiumUsers++;
        switch (tier) {
          case PremiumTier.lifetime:
          case PremiumTier.admin:
            lifetimeUsers++;
            break;
          case PremiumTier.yearly:
            yearlyUsers++;
            break;
          case PremiumTier.monthly:
            monthlyUsers++;
            break;
          case PremiumTier.free:
            break;
        }
      } else {
        freeUsers++;
      }
    }

    return AdminStats(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      premiumUsers: premiumUsers,
      freeUsers: freeUsers,
      lifetimeUsers: lifetimeUsers,
      yearlyUsers: yearlyUsers,
      monthlyUsers: monthlyUsers,
      conversionRate: totalUsers > 0 ? premiumUsers / totalUsers * 100 : 0,
    );
  }

  @override
  Future<List<AdminUserSummary>> getAllUsers() async {
    final snapshot = await _users.get();
    final users = snapshot.docs.map((doc) {
      final data = doc.data();
      return AdminUserSummary(
        uid: doc.id,
        email: data['email'] as String?,
        displayName: data['displayName'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        premiumTier: PremiumTier.fromString(data['premiumTier'] as String?),
        isActive: data['isActive'] as bool? ?? true,
      );
    }).toList();
    users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return users;
  }

  @override
  Future<void> setUserActive(String uid, bool isActive) => _users.doc(uid).update({
        'isActive': isActive,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> setPremiumTier(String uid, PremiumTier tier) => _users.doc(uid).update({
        'premiumTier': tier.name,
        if (tier == PremiumTier.free) 'premiumRevokedAt': FieldValue.serverTimestamp(),
        if (tier != PremiumTier.free) 'premiumGrantedAt': FieldValue.serverTimestamp(),
      });
}
