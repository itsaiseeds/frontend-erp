import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/session_cubit.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'route_constants.dart';

class AppRouter {
  AppRouter._();

  static GoRouter create({required SessionCubit sessionCubit}) {
    return GoRouter(
      initialLocation: Routes.SPLASH,
      refreshListenable: _CubitRefreshListenable(sessionCubit.stream),
      redirect: (context, state) {
        final SessionStatus status = sessionCubit.state.status;
        final String location = state.matchedLocation;

        switch (status) {
          case SessionStatus.loading:
            return location == Routes.SPLASH ? null : Routes.SPLASH;
          case SessionStatus.onboarding:
            return location == Routes.ONBOARDING ? null : Routes.ONBOARDING;
          case SessionStatus.unauthenticated:
            return location == Routes.LOGIN ? null : Routes.LOGIN;
          case SessionStatus.authenticated:
            return location == Routes.HOME ? null : Routes.HOME;
        }
      },
      routes: [
        GoRoute(
          path: Routes.SPLASH,
          name: RouteNames.SPLASH,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: Routes.ONBOARDING,
          name: RouteNames.ONBOARDING,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: Routes.LOGIN,
          name: RouteNames.LOGIN,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: Routes.HOME,
          name: RouteNames.HOME,
          builder: (context, state) => const HomeScreen(),
        ),
      ],
    );
  }
}

class _CubitRefreshListenable extends ChangeNotifier {
  late final StreamSubscription<SessionState> _subscription;

  _CubitRefreshListenable(Stream<SessionState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
