import 'dart:async';

import 'package:equatable/equatable.dart';
import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/services/metadata_service.dart';
import '../../../../core/services/session_guard.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_session.dart';

enum SessionStatus { loading, onboarding, unauthenticated, authenticated }

class SessionState extends Equatable {
  final SessionStatus status;
  final AuthSession? session;

  const SessionState({required this.status, this.session});

  const SessionState.loading() : this(status: SessionStatus.loading);

  const SessionState.onboarding() : this(status: SessionStatus.onboarding);

  const SessionState.unauthenticated()
    : this(status: SessionStatus.unauthenticated);

  const SessionState.authenticated(AuthSession session)
    : this(status: SessionStatus.authenticated, session: session);

  @override
  List<Object?> get props => [status, session];
}

class SessionCubit extends SafeCubit<SessionState> {
  final AuthRepository _authRepository;
  StreamSubscription<void>? _expirySubscription;

  SessionCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const SessionState.loading()) {
    _expirySubscription = SessionGuard.onSessionExpired.listen((_) {
      AppLogger.session('session ended by guard, returning to login');
      emit(const SessionState.unauthenticated());
    });
  }

  Future<void> bootstrap() async {
    emit(const SessionState.loading());

    if (!await StorageService.hasOnboardingBeenSeen()) {
      AppLogger.session('bootstrap: onboarding not seen');
      emit(const SessionState.onboarding());
      return;
    }

    final stored = await _authRepository.readStoredSession();
    if (stored == null) {
      AppLogger.session('bootstrap: no stored token');
      emit(const SessionState.unauthenticated());
      return;
    }

    final verified = await _authRepository.reauthenticate();
    if (verified == null) {
      AppLogger.session('bootstrap: stored token rejected, clearing');
      await _authRepository.clearSession();
      emit(const SessionState.unauthenticated());
      return;
    }

    _enterAuthenticated(verified);
  }

  Future<void> completeOnboarding() async {
    await StorageService.markOnboardingSeen();
    emit(const SessionState.unauthenticated());
  }

  void onAuthenticated(AuthSession session) {
    _enterAuthenticated(session);
  }

  void _enterAuthenticated(AuthSession session) {
    AppLogger.session('authenticated as userId=${session.userId}');
    emit(SessionState.authenticated(session));
    unawaited(MetadataService.instance.ensureLoaded());
  }

  Future<void> signOut() async {
    AppLogger.session('sign out requested');
    await _authRepository.logout();
    emit(const SessionState.unauthenticated());
  }

  @override
  Future<void> close() {
    _expirySubscription?.cancel();
    return super.close();
  }
}
