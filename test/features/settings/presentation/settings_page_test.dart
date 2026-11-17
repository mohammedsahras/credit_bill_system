import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/core/theme/theme_controller.dart';
import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';
import 'package:credit_bill_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:credit_bill_system/features/settings/presentation/pages/settings_page.dart';
import 'package:credit_bill_system/features/settings/presentation/pages/theme_settings_page.dart';
import 'package:credit_bill_system/features/settings/presentation/widgets/profile_header.dart';
import 'package:credit_bill_system/features/settings/presentation/widgets/settings_option_tile.dart';
import 'package:credit_bill_system/features/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../settings_test_harness.dart';

void main() {
  late AuthBloc bloc;
  late MockGetProfileUseCase getProfile;
  late ThemeController themeController;
  late FakePreferencesStore prefs;

  /// Builds a [GetProfileUseCase] stub that answers from [answers] in order,
  /// repeating the last entry when it runs out.
  MockGetProfileUseCase profileStub(List<Either<Failure, UserEntity?>> answers) {
    var calls = 0;
    final stub = MockGetProfileUseCase();
    when(() => stub.execute(email: any(named: 'email'))).thenAnswer((_) async {
      final index = calls < answers.length ? calls : answers.length - 1;
      calls += 1;
      return answers[index];
    });
    return stub;
  }

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ThemeScope(
        controller: themeController,
        child: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: MaterialApp(
            home: SettingsPage(getProfileUseCase: getProfile),
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/edit-profile':
                  return MaterialPageRoute<void>(
                    builder: (context) => Scaffold(
                      body: Center(
                        child: TextButton(
                          key: const Key('finishEditAction'),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Finish editing'),
                        ),
                      ),
                    ),
                  );
                case '/settings/theme':
                  return MaterialPageRoute<void>(
                    builder: (context) => const ThemeSettingsPage(),
                  );
                default:
                  return null;
              }
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    final auth = await signedInAuthBloc(sampleUser());
    bloc = auth.bloc;
    addTearDown(bloc.close);
    getProfile = profileStub([Right(sampleUser())]);
    prefs = FakePreferencesStore();
    themeController = ThemeController(store: prefs);
    addTearDown(themeController.dispose);
  });

  testWidgets('renders the stored profile header and the full category list', (
    tester,
  ) async {
    await pumpSettings(tester);

    // Profile comes from the database, not from hard-coded text.
    expect(find.byType(ProfileHeader), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('+94 77 123 4567'), findsOneWidget);
    expect(find.text('AL'), findsOneWidget); // initials avatar fallback

    expect(
      find.ancestor(
        of: find.text('Edit profile'),
        matching: find.byType(SettingsTile),
      ),
      findsOneWidget,
    );

    // Nothing on the screen pretends to be on the way: there is no
    // "Coming soon" label anywhere, and the categories whose features
    // do not exist yet (language, notifications) are omitted entirely —
    // not shown as stubs.
    expect(find.text('Coming soon'), findsNothing);

    // The whole list ships, all the way to the last entry. The list is
    // lazy: bring each entry into view (in list order) before asserting
    // on it, or the ones scrolled past are unmounted.
    for (final label in [
      'Theme & Appearance',
      'Security & Privacy',
      'Storage & Data',
      'Help & Support',
      'About',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: pageScrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      expect(
        find.ancestor(of: find.text(label), matching: find.byType(SettingsTile)),
        findsOneWidget,
      );
    }
    expect(find.text('Coming soon'), findsNothing);
  });

  testWidgets('a category opens its real screen, applies and returns', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.scrollUntilVisible(
      find.text('Theme & Appearance'),
      200,
      scrollable: pageScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theme & Appearance'));
    await tester.pumpAndSettle();

    // A fully functional theme picker — not a placeholder.
    expect(find.byType(ThemeSettingsPage), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);

    // Choosing Dark applies to the controller and is persisted.
    await tester.tap(find.byKey(const Key('themeDarkOption')));
    await tester.pumpAndSettle();
    expect(prefs.savedMode, ThemeMode.dark);
    expect(
      tester.widget<SettingsOptionTile>(
        find.byKey(const Key('themeDarkOption')),
      ).selected,
      isTrue,
    );

    // Back returns to the settings list untouched.
    Navigator.of(tester.element(find.byType(AppBar))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    // The lazy list restores at its previous offset, leaving the first
    // entry unmounted; snap back to the top before asserting on it.
    tester.state<ScrollableState>(pageScrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Edit profile'), findsOneWidget);
  });

  testWidgets('live search filters the category list', (tester) async {
    await pumpSettings(tester);

    await tester.enterText(
      find.byKey(const Key('settingsSearchField')),
      'storage',
    );
    await tester.pump();

    expect(find.text('Storage & Data'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Edit profile'), findsNothing);
    expect(find.text('Account'), findsNothing);
    expect(find.byType(ProfileHeader), findsNothing); // search-only mode

    await tester.enterText(
      find.byKey(const Key('settingsSearchField')),
      'zzzz',
    );
    await tester.pump();
    expect(find.text('No settings match "zzzz".'), findsOneWidget);
    expect(find.byType(SettingsTile), findsNothing);

    // Categories whose features are not built (yet) are absent from the
    // searchable list instead of advertising themselves.
    await tester.enterText(
      find.byKey(const Key('settingsSearchField')),
      'language',
    );
    await tester.pump();
    expect(find.text('No settings match "language".'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('settingsSearchField')),
      'notifications',
    );
    await tester.pump();
    expect(find.text('No settings match "notifications".'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('settingsSearchField')), '');
    await tester.pump();
    expect(find.byType(ProfileHeader), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('No settings match "zzzz".'), findsNothing);
  });

  testWidgets('opening Edit profile reloads the profile on return', (
    tester,
  ) async {
    var calls = 0;
    getProfile = MockGetProfileUseCase();
    when(() => getProfile.execute(email: any(named: 'email'))).thenAnswer((
      _,
    ) async {
      calls += 1;
      return Right<Failure, UserEntity?>(
        calls == 1
            ? sampleUser()
            : sampleUser(fullName: 'Grace Hopper', phone: null),
      );
    });

    await pumpSettings(tester);
    expect(calls, 1);
    expect(find.text('Ada Lovelace'), findsOneWidget);

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('finishEditAction')), findsOneWidget);

    await tester.tap(find.byKey(const Key('finishEditAction')));
    await tester.pumpAndSettle();

    // Returning with `true` refreshes the header from the database.
    expect(calls, 2);
    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsNothing);
    expect(find.text('Add phone'), findsOneWidget); // no number stored yet
  });

  testWidgets('profile load failures show a message and a working Retry', (
    tester,
  ) async {
    getProfile = profileStub([
      const Left<Failure, UserEntity?>(
        NotFoundFailure('No account found with this email.'),
      ),
      Right(sampleUser()),
    ]);

    await pumpSettings(tester);

    expect(find.text('No account found with this email.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(ProfileHeader), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileHeader), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('No account found with this email.'), findsNothing);
  });
}
