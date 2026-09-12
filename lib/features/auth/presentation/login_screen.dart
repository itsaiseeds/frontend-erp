import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_state.dart';
import 'bloc/session_cubit.dart';
import 'widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.SURFACE,
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == AuthStatus.failure) {
            ToastUtils.showError(
              context,
              state.errorMessage ?? AppStrings.LOGIN_FAILED,
            );
            return;
          }
          if (state.status == AuthStatus.success && state.session != null) {
            context.read<SessionCubit>().onAuthenticated(state.session!);
          }
        },
        child: DismissKeyboard(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.LG24,
                    vertical: AppSpacing.XL32,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (AppSpacing.XL32 * 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          AppAssets.LOGO,
                          height: AppSizes.LOGIN_LOGO,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: AppSpacing.LG24),
                        Text(
                          AppStrings.LOGIN_HEADING,
                          textAlign: TextAlign.center,
                          style: AppTypography.headingMedium,
                        ),
                        const SizedBox(height: AppSpacing.XL32),
                        const LoginForm(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
