import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/app_config_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupDependencies();
  sl<AppConfigService>().listen();
  runApp(const ExLogApp());
}

class ExLogApp extends StatefulWidget {
  const ExLogApp({super.key});

  @override
  State<ExLogApp> createState() => _ExLogAppState();
}

class _ExLogAppState extends State<ExLogApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;
  late final GoRouterRefreshStream _refreshStream;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>();
    _refreshStream = GoRouterRefreshStream(_authBloc.stream);
    _router = createAppRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    _refreshStream.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: BlocListener<AuthBloc, AuthState>(
        bloc: _authBloc,
        listener: (context, state) => _router.refresh(),
        child: MaterialApp.router(
          routerConfig: _router,
          theme: AppTheme.light,
          title: 'ExLog',
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
