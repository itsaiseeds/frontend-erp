import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState.initial()) {
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthSignedOut>(_onSignedOut);
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    AppLogger.auth('login submitted');
    try {
      final session = await _authRepository.login(
        phoneNumber: event.phoneNumber,
        otp: event.otp,
      );
      AppLogger.auth('login succeeded for role=${session.role}');
      emit(AuthState.success(session));
    } on ApiException catch (e) {
      final message = e.message.trim();
      AppLogger.auth('login rejected (${e.statusCode}): $message');
      emit(
        AuthState.failure(message.isEmpty ? AppStrings.LOGIN_FAILED : message),
      );
    } catch (e) {
      AppLogger.auth('login failed unexpectedly: $e');
      emit(const AuthState.failure(AppStrings.LOGIN_FAILED));
    }
  }

  Future<void> _onSignedOut(
    AuthSignedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthState.initial());
  }
}
