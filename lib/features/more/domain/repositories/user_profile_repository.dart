import '../entities/user_profile.dart';

abstract interface class UserProfileRepository {
  /// Reads the current user's `users/{uid}` doc. Missing fields (premiumTier,
  /// isActive, preferredCurrency, aiParserConfig) default client-side via
  /// [UserProfile.fromFirestore] since older docs predate them.
  Future<UserProfile> getProfile();

  Future<void> updatePreferredCurrency(String currencyCode);

  Future<void> updateAIParserConfig(AIParserConfig config);

  Future<void> updateSelfNames(List<String> selfNames);
}
