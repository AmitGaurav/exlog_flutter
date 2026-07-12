import '../entities/admin_stats.dart';
import '../entities/user_profile.dart';

abstract interface class AdminRepository {
  Future<AdminStats> getStatistics();

  Future<List<AdminUserSummary>> getAllUsers();

  Future<void> setUserActive(String uid, bool isActive);

  Future<void> setPremiumTier(String uid, PremiumTier tier);
}
