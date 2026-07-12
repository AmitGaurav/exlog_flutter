import '../entities/transaction_type_model.dart';

abstract interface class TransactionTypeRepository {
  /// Returns the user's custom types, seeding the 4 defaults on first call
  /// if none exist yet.
  Future<List<TransactionTypeModel>> getTypes();

  Future<String> createType(TransactionTypeModel type);

  Future<void> updateType(TransactionTypeModel type);

  Future<void> deleteType(String typeId);
}
