import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/categories/data/repositories/category_repository_impl.dart';
import '../../features/categories/domain/repositories/category_repository.dart';
import '../../features/categories/presentation/bloc/category_bloc.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/more/data/repositories/admin_repository_impl.dart';
import '../../features/more/data/repositories/payee_mapping_repository_impl.dart';
import '../../features/more/data/repositories/purchase_repository_impl.dart';
import '../../features/more/data/repositories/rating_repository_impl.dart';
import '../../features/more/data/repositories/transaction_type_repository_impl.dart';
import '../../features/more/data/repositories/user_profile_repository_impl.dart';
import '../../features/more/domain/repositories/admin_repository.dart';
import '../../features/more/domain/repositories/payee_mapping_repository.dart';
import '../../features/more/domain/repositories/purchase_repository.dart';
import '../../features/more/domain/repositories/rating_repository.dart';
import '../../features/more/domain/repositories/transaction_type_repository.dart';
import '../../features/more/domain/repositories/user_profile_repository.dart';
import '../../features/more/domain/services/edit_restriction_checker.dart';
import '../../features/more/presentation/bloc/admin_bloc.dart';
import '../../features/more/presentation/bloc/payee_mapping_bloc.dart';
import '../../features/more/presentation/bloc/rating_bloc.dart';
import '../../features/more/presentation/bloc/transaction_type_bloc.dart';
import '../../features/more/presentation/bloc/user_profile_bloc.dart';
import '../../features/reminders/data/repositories/reminder_repository_impl.dart';
import '../../features/reminders/domain/repositories/reminder_repository.dart';
import '../../features/reminders/presentation/bloc/reminder_bloc.dart';
import '../../features/transactions/data/repositories/pending_sms_repository_impl.dart';
import '../../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../../features/transactions/domain/repositories/pending_sms_repository.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';
import '../../features/transactions/presentation/bloc/transaction_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> setupDependencies() async {
  // ─── Firebase ────────────────────────────────────────────────
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseFunctions>(() => FirebaseFunctions.instance);

  // ─── Local storage ───────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<EditRestrictionChecker>(() => EditRestrictionChecker(sl<SharedPreferences>()));

  // ─── Repositories ────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      auth: sl<FirebaseAuth>(),
      functions: sl<FirebaseFunctions>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );

  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton<ReminderRepository>(
    () => ReminderRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton<RatingRepository>(
    () => RatingRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton<PayeeMappingRepository>(
    () => PayeeMappingRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton<TransactionTypeRepository>(
    () => TransactionTypeRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(firestore: sl<FirebaseFirestore>()),
  );

  sl.registerLazySingleton<PurchaseRepository>(
    () => PurchaseRepositoryImpl(
      iap: InAppPurchase.instance,
      functions: sl<FirebaseFunctions>(),
    ),
  );

  sl.registerLazySingleton<PendingSmsRepository>(
    () => PendingSmsRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
      userProfileRepository: sl<UserProfileRepository>(),
      payeeMappingRepository: sl<PayeeMappingRepository>(),
      categoryRepository: sl<CategoryRepository>(),
      transactionRepository: sl<TransactionRepository>(),
    ),
  );

  // ─── BLoCs ───────────────────────────────────────────────────
  // Registered as factory so each widget tree gets a fresh instance.
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<AuthRepository>()));
  sl.registerFactory<DashboardBloc>(() => DashboardBloc(sl<DashboardRepository>()));
  sl.registerFactory<CategoryBloc>(() => CategoryBloc(sl<CategoryRepository>()));
  sl.registerFactory<TransactionBloc>(() => TransactionBloc(sl<TransactionRepository>()));
  sl.registerFactory<ReminderBloc>(() => ReminderBloc(sl<ReminderRepository>()));
  sl.registerFactory<UserProfileBloc>(() => UserProfileBloc(sl<UserProfileRepository>()));
  sl.registerFactory<RatingBloc>(() => RatingBloc(sl<RatingRepository>(), sl<FirebaseAuth>()));
  sl.registerFactory<PayeeMappingBloc>(() => PayeeMappingBloc(sl<PayeeMappingRepository>()));
  sl.registerFactory<TransactionTypeBloc>(() => TransactionTypeBloc(sl<TransactionTypeRepository>()));
  sl.registerFactory<AdminBloc>(() => AdminBloc(sl<AdminRepository>(), sl<RatingRepository>()));
}
