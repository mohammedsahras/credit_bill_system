import 'package:credit_bill_system/core/theme/theme_controller.dart';
import 'package:credit_bill_system/features/settings/presentation/pages/theme_settings_page.dart';
import 'package:credit_bill_system/features/settings/presentation/widgets/settings_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../settings_test_harness.dart';

void main() {
  late FakePreferencesStore prefs;
  late ThemeController controller;

  bool isSelected(WidgetTester tester, String key) =>
      tester
          .widget<SettingsOptionTile>(find.byKey(Key(key)))
          .selected;

  Future<void> pumpTheme(WidgetTester tester) async {
    await tester.pumpWidget(
      ThemeScope(
        controller: controller,
        child: const MaterialApp(home: ThemeSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    prefs = FakePreferencesStore();
    controller = ThemeController(store: prefs);
    await controller.load();
    addTearDown(controller.dispose);
  });

  testWidgets('system default is the fallback and is shown as selected', (
    tester,
  ) async {
    await pumpTheme(tester);

    expect(find.byType(SettingsOptionTile), findsNWidgets(3));
    expect(isSelected(tester, 'themeSystemOption'), isTrue);
    expect(isSelected(tester, 'themeLightOption'), isFalse);
    expect(isSelected(tester, 'themeDarkOption'), isFalse);

    // Re-selecting the current mode is a no-op: no notification, no write.
    await tester.tap(find.byKey(const Key('themeSystemOption')));
    await tester.pumpAndSettle();
    expect(prefs.savedMode, isNull);
    expect(isSelected(tester, 'themeSystemOption'), isTrue);
  });

  testWidgets('a stored dark mode opens as selected and switching persists', (
    tester,
  ) async {
    controller = ThemeController(store: prefs, initialMode: ThemeMode.dark);
    await pumpTheme(tester);

    expect(isSelected(tester, 'themeDarkOption'), isTrue);
    expect(isSelected(tester, 'themeSystemOption'), isFalse);

    await tester.tap(find.byKey(const Key('themeLightOption')));
    await tester.pumpAndSettle();

    expect(controller.mode, ThemeMode.light);
    expect(prefs.savedMode, ThemeMode.light);
    expect(isSelected(tester, 'themeLightOption'), isTrue);
    expect(isSelected(tester, 'themeDarkOption'), isFalse);
  });

  testWidgets('every option announces itself as a selectable control', (
    tester,
  ) async {
    await pumpTheme(tester);

    for (final key in [
      'themeSystemOption',
      'themeLightOption',
      'themeDarkOption',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
      expect(
        tester.widget<SettingsOptionTile>(find.byKey(Key(key))).onTap,
        isNotNull,
      );
    }
  });
}
