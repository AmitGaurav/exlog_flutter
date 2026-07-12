import '../entities/transaction.dart';

/// SMS-detected transactions awaiting user approve/reject on the Transactions
/// page (Android-only auto-detect feature — no iOS analog). Backed by
/// `users/{uid}/pendingSmsTransactions`.
abstract interface class PendingSmsRepository {
  Stream<List<Transaction>> watchPending();

  /// Creates the real transaction (same as a manual/paste-SMS add) and
  /// removes it from the pending queue.
  Future<void> approve(Transaction pending);

  /// Discards the pending entry without creating a transaction.
  Future<void> reject(String pendingId);

  /// Runs newly-arrived `androidSmsInbox` entries through the parsing
  /// pipeline, promoting passing ones to `pendingSmsTransactions`.
  Future<void> processInbox();
}
