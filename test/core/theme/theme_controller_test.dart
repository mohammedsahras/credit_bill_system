import 'package:credit_bill_system/core/services/preferences_store.dart';
import 'package:credit_bill_system/core/theme/theme_controller.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPreferencesStore extends Mock implements PreferencesStore {}

void main() {
  late MockPreferencesStore store;

  setUp(() {
    store = MockPreferencesStore();
  });

  test('defaults to system before anything is stored', () async {
    when(
      () => store.loadThemeMode(),
    ).thenAnswer((_) async => ThemeMode.system);
    final controller = ThemeController(store: store);
    addTearDown(controller.dispose);

    expect(controller.mode, ThemeMode.system);
    await controller.load();
    expect(controller.mode, ThemeMode.system);
  });

  test('load() applies the persisted mode and notifies listeners', () async {
    when(() => store.loadThemeMode()).thenAnswer((_) async => ThemeMode.dark);
    final controller = ThemeController(store: store);
    addTearDown(controller.dispose);
    var notified = false;
    controller.addListener(() => notified = true);

    await controller.load();

    expect(controller.mode, ThemeMode.dark);
    expect(notified, isTrue);
  });

  test('setMode notifies listeners, then persists the choice', () async {
    when(
      () => store.saveThemeMode(ThemeMode.light),
    ).thenAnswer((_) async {});
    final controller = ThemeController(store: store);
    addTearDown(controller.dispose);
    var notified = false;
    controller.addListener(() => notified = true);

    await controller.setMode(ThemeMode.light);

    expect(controller.mode, ThemeMode.light);
    expect(notified, isTrue);
    verify(() => store.saveThemeMode(ThemeMode.light)).called(1);
  });

  test('setMode is a no-op when the mode is unchanged', () async {
    final controller = ThemeController(store: store);
    addTearDown(controller.dispose);
    var notified = false;
    controller.addListener(() => notified = true);

    await controller.setMode(ThemeMode.system);

    expect(notified, isFalse);
    verifyZeroInteractions(store);
  });
}
