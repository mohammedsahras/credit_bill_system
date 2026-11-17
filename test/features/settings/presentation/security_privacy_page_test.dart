import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';
import 'package:credit_bill_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:credit_bill_system/features/settings/presentation/pages/security_privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../settings_test_harness.dart';

void main() {
  late AuthBloc bloc;
  late MockChangePasswordUseCase changePassword;

  Future<void> pumpSecurity(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: SecurityPrivacyPage(changePasswordUseCase: changePassword),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    required String current,
    required String next,
    required String confirm,
  }) async {
    await tester.enterText(
      find.byKey(const Key('changeCurrentPasswordField')),
      current,
    );
    await tester.enterText(
      find.byKey(const Key('changeNewPasswordField')),
      next,
    );
    await tester.enterText(
      find.byKey(const Key('changeConfirmPasswordField')),
      confirm,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('changePasswordButton')));
    await tester.pumpAndSettle();
  }

  /// SnackBars arm a 4-second dismiss timer; advance past it so the test
  /// never ends with a pending timer.
  Future<void> flushSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    final auth = await signedInAuthBloc(sampleUser());
    bloc = auth.bloc;
    addTearDown(bloc.close);
    changePassword = MockChangePasswordUseCase();
  });

  testWidgets('validates the form before calling the use case', (
    tester,
  ) async {
    await pumpSecurity(tester);

    await tester.tap(find.byKey(const Key('changePasswordButton')));
    await tester.pumpAndSettle();

    expect(find.text('Enter your current password.'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
    verifyZeroInteractions(changePassword);
  });

  testWidgets('mismatched confirmation is caught inline', (tester) async {
    await pumpSecurity(tester);
    await fillAndSubmit(
      tester,
      current: 'OldSecret1',
      next: 'NewSecret1',
      confirm: 'Different1',
    );

    expect(find.text('Passwords do not match.'), findsOneWidget);
    verifyZeroInteractions(changePassword);
  });

  testWidgets('a rejected change surfaces the error and keeps the inputs', (
    tester,
  ) async {
    when(
      () => changePassword.execute(
        email: 'ada@example.com',
        currentPassword: 'WrongOld1',
        newPassword: 'BrandNew1',
      ),
    ).thenAnswer(
      (_) async => Left<Failure, UserEntity>(
        const ValidationFailure('Current password is incorrect.'),
      ),
    );

    await pumpSecurity(tester);
    await fillAndSubmit(
      tester,
      current: 'WrongOld1',
      next: 'BrandNew1',
      confirm: 'BrandNew1',
    );

    // Shown both inline and as the red SnackBar — and nothing was cleared.
    expect(find.text('Current password is incorrect.'), findsWidgets);
    expect(find.text('WrongOld1'), findsOneWidget);
    verify(
      () => changePassword.execute(
        email: 'ada@example.com',
        currentPassword: 'WrongOld1',
        newPassword: 'BrandNew1',
      ),
    ).called(1);
    await flushSnackBar(tester);
  });

  testWidgets('a successful change clears the form and confirms', (
    tester,
  ) async {
    when(
      () => changePassword.execute(
        email: 'ada@example.com',
        currentPassword: 'OldSecret1',
        newPassword: 'NewSecret1',
      ),
    ).thenAnswer((_) async => Right<Failure, UserEntity>(sampleUser()));

    await pumpSecurity(tester);
    await fillAndSubmit(
      tester,
      current: 'OldSecret1',
      next: 'NewSecret1',
      confirm: 'NewSecret1',
    );

    expect(find.text('Password changed successfully.'), findsOneWidget);
    expect(find.text('OldSecret1'), findsNothing);
    expect(find.text('NewSecret1'), findsNothing);
    verify(
      () => changePassword.execute(
        email: 'ada@example.com',
        currentPassword: 'OldSecret1',
        newPassword: 'NewSecret1',
      ),
    ).called(1);
    await flushSnackBar(tester);
  });

  testWidgets('sign out confirms, clears the session and logs the bloc out', (
    tester,
  ) async {
    await pumpSecurity(tester);

    // The sign-out row sits below the fold in the lazy list.
    await tester.scrollUntilVisible(
      find.byKey(const Key('signOutTile')),
      200,
      scrollable: pageScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signOutTile')));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('signOutConfirmButton')));
    await tester.pumpAndSettle();

    // The logout handler awaits real session-file I/O on the real event
    // loop, which plain pumps never turn — wait for the actual state with
    // a bounded timeout instead of a fixed delay.
    await tester.runAsync(() async {
      if (bloc.state is! AuthUnauthenticatedState) {
        await bloc.stream
            .firstWhere((state) => state is AuthUnauthenticatedState)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw StateError(
                'AuthBloc never emitted AuthUnauthenticatedState',
              ),
            );
      }
    });
    await tester.pumpAndSettle();
    expect(bloc.state, isA<AuthUnauthenticatedState>());
  });

  testWidgets('cancelling the sign-out confirmation signs nothing out', (
    tester,
  ) async {
    await pumpSecurity(tester);

    // The sign-out row sits below the fold in the lazy list.
    await tester.scrollUntilVisible(
      find.byKey(const Key('signOutTile')),
      200,
      scrollable: pageScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signOutTile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signOutCancelButton')));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsNothing);
    expect(bloc.state, isA<AuthAuthenticatedState>());
  });
}
