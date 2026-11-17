import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';
import 'package:credit_bill_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:credit_bill_system/features/settings/presentation/pages/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../settings_test_harness.dart';

/// 1x1 transparent PNG — small enough for the photo size guard and valid
/// enough to pass the picker's decode check.
const _tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

void main() {
  const nameField = Key('profileNameField');
  const emailField = Key('profileEmailField');
  const phoneField = Key('profilePhoneField');
  const saveButton = Key('saveProfileButton');

  late AuthBloc bloc;
  late MockUpdateProfileUseCase updateProfile;
  late MockGetProfileUseCase getProfile;

  String textOf(WidgetTester tester, Key key) {
    final field = tester.widget<TextFormField>(
      find.descendant(of: find.byKey(key), matching: find.byType(TextFormField)),
    );
    return field.controller!.text;
  }

  void stubUpdate(
    Future<Either<Failure, UserEntity>> Function() answer,
  ) {
    when(
      () => updateProfile.execute(
        currentEmail: any(named: 'currentEmail'),
        fullName: any(named: 'fullName'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
        photo: any(named: 'photo'),
        currentPassword: any(named: 'currentPassword'),
      ),
    ).thenAnswer((_) => answer());
  }

  Future<void> pumpEditor(
    WidgetTester tester,
    UserEntity storedUser,
  ) async {
    getProfile = MockGetProfileUseCase();
    when(() => getProfile.execute(email: any(named: 'email'))).thenAnswer(
      (_) async => Right<Failure, UserEntity?>(storedUser),
    );

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    key: const Key('openEditorAction'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EditProfilePage(
                          getProfileUseCase: getProfile,
                        ),
                      ),
                    ),
                    child: const Text('Open editor'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openEditorAction')));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfilePage), findsOneWidget);
  }

  /// The auth bloc is constructed in `setUp`, i.e. outside the fake-async
  /// zone, so its update handler's async work — mock reply, session file
  /// write, state emit, listener — only progresses on the real event loop,
  /// which plain `pump`s never turn. Turn that loop inside `runAsync` and
  /// wait for the actual update state (no fixed delay): if the bloc never
  /// emits, the bounded timeout fails the test loudly instead of masking it.
  Future<void> settleBlocDispatch(WidgetTester tester) async {
    await tester.runAsync(() async {
      if (bloc.state is! AuthProfileUpdatedState &&
          bloc.state is! AuthProfileUpdateFailedState) {
        await bloc.stream
            .firstWhere(
              (state) =>
                  state is AuthProfileUpdatedState ||
                  state is AuthProfileUpdateFailedState,
            )
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw StateError(
                'AuthBloc never emitted a profile update state',
              ),
            );
      }
    });
  }

  setUp(() async {
    final auth = await signedInAuthBloc(sampleUser());
    bloc = auth.bloc;
    addTearDown(bloc.close);
    updateProfile = auth.updateProfileUseCase;
    stubUpdate(() async => Right(sampleUser()));
  });

  testWidgets('seeds the form and account info from the stored profile', (
    tester,
  ) async {
    await pumpEditor(tester, sampleUser());

    expect(textOf(tester, nameField), 'Ada Lovelace');
    expect(textOf(tester, emailField), 'ada@example.com');
    expect(textOf(tester, phoneField), '+94 77 123 4567');
    expect(find.text('AL'), findsOneWidget); // no photo -> initials avatar
    expect(find.text('Change photo'), findsOneWidget);
    expect(find.text('Remove photo'), findsNothing);

    // The account-info card sits below the fold: scroll the page list so it
    // is built and revealed before asserting on its rows.
    await tester.scrollUntilVisible(
      find.text('user-0001'),
      200,
      scrollable: pageScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('User ID'), findsOneWidget);
    expect(find.text('user-0001'), findsOneWidget);
    expect(find.text('15 Jan 2026'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
  });

  testWidgets('validates name, email and phone before dispatching anything', (
    tester,
  ) async {
    await pumpEditor(tester, sampleUser());

    await tester.enterText(find.byKey(nameField), '');
    await tester.enterText(find.byKey(emailField), 'not-an-email');
    await tester.enterText(find.byKey(phoneField), 'call-me');

    await tester.scrollUntilVisible(find.byKey(saveButton), 200, scrollable: pageScrollable);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(saveButton));
    await tester.pump();

    expect(find.text('Name cannot be empty.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter a valid phone number.'), findsOneWidget);
    expect(find.byType(EditProfilePage), findsOneWidget);
    verifyNever(
      () => updateProfile.execute(
        currentEmail: any(named: 'currentEmail'),
        fullName: any(named: 'fullName'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
        photo: any(named: 'photo'),
        currentPassword: any(named: 'currentPassword'),
      ),
    );
  });

  testWidgets('an email change asks for the current password first', (
    tester,
  ) async {
    await pumpEditor(tester, sampleUser());

    await tester.enterText(find.byKey(emailField), 'ada@newdomain.com');
    await tester.scrollUntilVisible(find.byKey(saveButton), 200, scrollable: pageScrollable);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(saveButton));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Confirm your current password'), findsOneWidget);
    expect(find.text('Password is required.'), findsNothing);

    // Confirming an empty password keeps the dialog open with an explanation.
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(find.text('Password is required.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    // Cancelling abandons the change: nothing is dispatched.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(EditProfilePage), findsOneWidget);
    expect(textOf(tester, emailField), 'ada@newdomain.com'); // edit kept
    verifyNever(
      () => updateProfile.execute(
        currentEmail: any(named: 'currentEmail'),
        fullName: any(named: 'fullName'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
        photo: any(named: 'photo'),
        currentPassword: any(named: 'currentPassword'),
      ),
    );
  });

  testWidgets('a wrong password keeps the user signed in with a clear message', (
    tester,
  ) async {
    stubUpdate(
      () async => const Left<Failure, UserEntity>(
        ValidationFailure('Current password is incorrect.'),
      ),
    );
    await pumpEditor(tester, sampleUser());

    await tester.enterText(find.byKey(emailField), 'ada@newdomain.com');
    await tester.scrollUntilVisible(find.byKey(saveButton), 200, scrollable: pageScrollable);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(saveButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('currentPasswordField')),
      'wrong-password',
    );
    await tester.tap(find.text('Confirm'));
    await settleBlocDispatch(tester);
    await tester.pumpAndSettle();

    // The rejection is surfaced and the editor (and session) stay put.
    expect(find.text('Current password is incorrect.'), findsWidgets);
    expect(find.byType(EditProfilePage), findsOneWidget);
    expect(bloc.state, isA<AuthProfileUpdateFailedState>());
    expect(bloc.state, isA<AuthAuthenticatedState>());

    // Let the error SnackBar finish its timer so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('a successful save pops the editor with a confirmation', (
    tester,
  ) async {
    stubUpdate(() async => Right(sampleUser(fullName: 'Augusta Ada King')));
    await pumpEditor(tester, sampleUser());

    await tester.enterText(find.byKey(nameField), 'Augusta Ada King');
    await tester.scrollUntilVisible(find.byKey(saveButton), 200, scrollable: pageScrollable);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(saveButton));
    await settleBlocDispatch(tester);
    await tester.pumpAndSettle();

    expect(find.byType(EditProfilePage), findsNothing);
    expect(bloc.state, isA<AuthProfileUpdatedState>());
    expect(
      (bloc.state as AuthProfileUpdatedState).fullName,
      'Augusta Ada King',
    );
    expect(find.text('Your profile has been updated.'), findsWidgets);

    // Flush the success SnackBar timer before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('removing the photo sends a null photo on save', (tester) async {
    await pumpEditor(tester, sampleUser(photo: _tinyPngBase64));

    expect(find.text('Remove photo'), findsOneWidget);
    await tester.tap(find.text('Remove photo'));
    await tester.pump();
    expect(find.text('Remove photo'), findsNothing);
    expect(find.text('AL'), findsOneWidget); // back to initials

    await tester.scrollUntilVisible(find.byKey(saveButton), 200, scrollable: pageScrollable);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(saveButton));
    await settleBlocDispatch(tester);
    await tester.pumpAndSettle();

    verify(
      () => updateProfile.execute(
        currentEmail: 'ada@example.com',
        fullName: 'Ada Lovelace',
        email: 'ada@example.com',
        phone: '+94 77 123 4567',
        photo: null,
        currentPassword: null,
      ),
    ).called(1);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
