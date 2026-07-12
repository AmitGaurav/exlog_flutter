import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions();
  Future<String> createTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String transactionId);

  /// Dedup key for SMS-imported transactions — exact match on
  /// `transactionReference`, scoped to the current user, matching iOS.
  Future<Transaction?> findByTransactionReference(String reference);

  /// Display-only usage counter (`users/{uid}/usage/{yyyy-MM}.smsImports`) —
  /// no quota is enforced, this is shown for visual parity with iOS only.
  Future<int> getSmsImportUsageThisMonth();
  Future<void> incrementSmsImportUsage();
}
