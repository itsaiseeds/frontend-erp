import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import 'core/config/app_config_keys.dart';
import 'core/constants/app_strings.dart';
import 'core/network/api_client.dart';
import 'core/routing/app_router.dart';
import 'core/services/metadata_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/session_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: AppConfigKeys.envFile);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const SaiseedsSalesApp());
}

class SaiseedsSalesApp extends StatefulWidget {
  const SaiseedsSalesApp({super.key});

  @override
  State<SaiseedsSalesApp> createState() => _SaiseedsSalesAppState();
}

class _SaiseedsSalesAppState extends State<SaiseedsSalesApp> {
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final SessionCubit _sessionCubit;
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    MetadataService.instance.apiClient = _apiClient;
    _authRepository = AuthRepository(apiClient: _apiClient);
    _sessionCubit = SessionCubit(authRepository: _authRepository);
    _authBloc = AuthBloc(authRepository: _authRepository);
    _router = AppRouter.create(sessionCubit: _sessionCubit);
    _sessionCubit.bootstrap();
  }

  @override
  void dispose() {
    _authBloc.close();
    _sessionCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _apiClient),
        BlocProvider<SessionCubit>.value(value: _sessionCubit),
        BlocProvider<AuthBloc>.value(value: _authBloc),
      ],
      child: ToastificationWrapper(
        child: MaterialApp.router(
          title: AppStrings.APP_NAME,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
        ),
      ),
    );
  }
}
