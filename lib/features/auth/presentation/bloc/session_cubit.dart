import 'dart:async';

import 'package:equatable/equatable.dart';
import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/services/metadata_service.dart';
import '../../../../core/services/session_guard.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/auth_repository.dart';
import '../../data/models/android_role.dart';
import '../../data/models/auth_session.dart';

enum SessionStatus { loading, onboarding, unauthenticated, authenticated }

class SessionState extends Equatable {
  final SessionStatus status;
  final AuthSession? session;

  /// Which shell is showing right now. Null only while [session] holds a
  /// single-role user -- there is nothing to choose, so routing falls back
  /// to whichever flag is true.
  final AndroidRole? activeRole;

  const SessionState({required this.status, this.session, this.activeRole});

  const SessionState.loading() : this(status: SessionStatus.loading);

  const SessionState.onboarding() : this(status: SessionStatus.onboarding);

  const SessionState.unauthenticated()
    : this(status: SessionStatus.unauthenticated);

  const SessionState.authenticated(AuthSession session, {AndroidRole? activeRole})
    : this(
        status: SessionStatus.authenticated,
        session: session,
        activeRole: activeRole,
      );

  /// The roles this session actually holds, in a stable display/priority
  /// order. Empty only for a signed-out state.
  List<AndroidRole> get availableRoles {
    final AuthSession? s = session;
    if (s == null) return const [];
    return [
      if (s.isSalesPerson) AndroidRole.salesPerson,
      if (s.isGodownManager) AndroidRole.godownManager,
      if (s.isLabTester) AndroidRole.labTester,
    ];
  }

  /// True once the session holds two or more roles -- the only time a
  /// choice needs making.
  bool get hasRoleChoice => availableRoles.length >= 2;

  /// The role to route by: an explicit choice first, then whichever single
  /// role the account has, defaulting to the first available role (sales
  /// person preferred) if somehow none came back true (a state the server
  /// should never send).
  AndroidRole get effectiveRole {
    if (activeRole != null) return activeRole!;
    final List<AndroidRole> roles = availableRoles;
    if (roles.length == 1) return roles.first;
    if (roles.isNotEmpty) return roles.first;
    return AndroidRole.salesPerson;
  }

  @override
  List<Object?> get props => [status, session, activeRole];
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

    final String? storedRoleKey = await StorageService.getActiveAndroidRole();
    await _enterAuthenticated(
      verified,
      activeRole: AndroidRoleX.fromStorageKey(storedRoleKey),
    );
  }

  Future<void> completeOnboarding() async {
    await StorageService.markOnboardingSeen();
    emit(const SessionState.unauthenticated());
  }

  void onAuthenticated(AuthSession session) {
    unawaited(_enterAuthenticated(session));
  }

  Future<void> _enterAuthenticated(
    AuthSession session, {
    AndroidRole? activeRole,
  }) async {
    AppLogger.session('authenticated as userId=${session.userId}');

    final int roleCount = [
      session.isSalesPerson,
      session.isGodownManager,
      session.isLabTester,
    ].where((held) => held).length;
    final AndroidRole? resolved = roleCount >= 2
        ? (activeRole ?? await _defaultRoleFor(session))
        : null;

    emit(SessionState.authenticated(session, activeRole: resolved));
    unawaited(MetadataService.instance.ensureLoaded());
  }

  /// A fresh login with both roles opens to whichever one was last chosen
  /// on this device, so the picker is not shown every single time.
  Future<AndroidRole?> _defaultRoleFor(AuthSession session) async {
    final String? storedKey = await StorageService.getActiveAndroidRole();
    return AndroidRoleX.fromStorageKey(storedKey);
  }

  /// Switches the shell for a dual-role user without a fresh login.
  Future<void> switchRole(AndroidRole role) async {
    final AuthSession? session = state.session;
    if (session == null) return;

    await StorageService.saveActiveAndroidRole(role.storageKey);
    emit(SessionState.authenticated(session, activeRole: role));
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
