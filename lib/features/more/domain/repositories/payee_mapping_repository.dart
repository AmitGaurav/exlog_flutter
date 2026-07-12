import '../entities/payee_mapping.dart';

abstract interface class PayeeMappingRepository {
  Future<List<PayeeMapping>> getMappings();

  Future<String> createMapping(PayeeMapping mapping);

  Future<void> updateMapping(PayeeMapping mapping);

  Future<void> deleteMapping(String mappingId);
}
