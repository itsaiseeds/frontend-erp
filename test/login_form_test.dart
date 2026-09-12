import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/constants/app_strings.dart';
import 'package:frontend_erp/core/network/api_client.dart';
import 'package:frontend_erp/features/auth/data/auth_repository.dart';
import 'package:frontend_erp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend_erp/features/auth/presentation/widgets/login_form.dart';

const List<Size> _phoneSizes = [
  Size(320, 640),
  Size(360, 800),
  Size(390, 844),
  Size(430, 932),
];

Future<void> _pumpForm(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final authBloc = AuthBloc(
    authRepository: AuthRepository(apiClient: ApiClient(dio: Dio())),
  );
  addTearDown(authBloc.close);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: LoginForm(),
          ),
        ),
      ),
    ),
  );
}

bool _isTruncated(WidgetTester tester, String text) {
  final finder = find.text(text);
  final Size painted = tester.getSize(finder);
  final Text widget = tester.widget<Text>(finder);

  final painter = TextPainter(
    text: TextSpan(text: text, style: widget.style),
    textDirection: TextDirection.ltr,
    maxLines: widget.maxLines,
  )..layout(maxWidth: painted.width);

  return painter.didExceedMaxLines;
}

void main() {
  for (final size in _phoneSizes) {
    testWidgets(
      'the authenticator helper renders in full at ${size.width.toInt()}px wide',
      (tester) async {
        await _pumpForm(tester, size);

        expect(find.text(AppStrings.LOGIN_OTP_HELPER), findsOneWidget);
        expect(
          _isTruncated(tester, AppStrings.LOGIN_OTP_HELPER),
          isFalse,
          reason: 'the helper text must never be clipped',
        );
      },
    );

    testWidgets(
      'the authentication code label renders in full at ${size.width.toInt()}px wide',
      (tester) async {
        await _pumpForm(tester, size);

        expect(
          _isTruncated(tester, AppStrings.AUTHENTICATION_CODE),
          isFalse,
          reason: 'the field label must never be clipped',
        );
      },
    );
  }

  testWidgets('the label and its helper stack rather than share a row', (
    tester,
  ) async {
    await _pumpForm(tester, _phoneSizes.last);

    final Offset label = tester.getTopLeft(
      find.text(AppStrings.AUTHENTICATION_CODE),
    );
    final Offset helper = tester.getTopLeft(
      find.text(AppStrings.LOGIN_OTP_HELPER),
    );

    expect(helper.dy, greaterThan(label.dy));
    expect(helper.dx, label.dx);
  });

  testWidgets('the layout does not overflow on the narrowest phone', (
    tester,
  ) async {
    await _pumpForm(tester, _phoneSizes.first);

    expect(tester.takeException(), isNull);
  });
}
