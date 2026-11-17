import 'package:flutter/material.dart';

import '../services/preferences_store.dart';

/// Holds the user's chosen [ThemeMode] and persists it through a
/// [PreferencesStore].
///
/// `main()` loads the stored value before the first frame so the app opens
/// in the chosen theme without a flash; [setMode] notifies listeners first
/// and persists afterwards so the UI reacts on the same frame.
class ThemeController extends ChangeNotifier {
  ThemeController({PreferencesStore? store, ThemeMode? initialMode})
    : _store = store ?? PreferencesStore.instance,
      _mode = initialMode ?? ThemeMode.system;

  final PreferencesStore _store;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// Reads the persisted mode (defaults to system when nothing is stored).
  Future<void> load() async {
    final stored = await _store.loadThemeMode();
    if (stored == _mode) return;
    _mode = stored;
    notifyListeners();
  }

  /// Applies [mode] immediately and persists it.
  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _store.saveThemeMode(mode);
  }
}

/// Exposes the app-level [ThemeController] to descendant widgets.
///
/// Lives directly above [MaterialApp]; pages below it (e.g. the theme
/// picker) read it through [ThemeScope.of] and rebuild whenever the mode
/// changes. `MaterialApp` switches themes through its built-in
/// [AnimatedTheme], so every surface eases to the new mode.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  /// The controller above [context]. Requires a [ThemeScope] ancestor
  /// (the app provides one around `MaterialApp`).
  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'No ThemeScope found above this widget.');
    return scope!.notifier!;
  }

  /// The controller above [context], or null when there is none.
  static ThemeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.notifier;
}
