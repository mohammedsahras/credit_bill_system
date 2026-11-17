import 'package:credit_bill_system/core/database/database_helper.dart';
import 'package:credit_bill_system/features/settings/presentation/pages/storage_data_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../settings_test_harness.dart';

void main() {
  late DatabaseHelper databaseHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    databaseHelper = DatabaseHelper();
  });

  setUp(() async {
    await databaseHelper.close();
    final databasePath = p.join(
      await getDatabasesPath(),
      'credit_bill_system.db',
    );
    await deleteDatabase(databasePath);
  });

  tearDownAll(() async {
    await databaseHelper.close();
  });

  /// Pumps the page and waits for its real device I/O to finish. The load
  /// mixes database/file futures, which only progress on the real event
  /// loop, with frame builds, which only happen on a pump — so alternate
  /// real-loop turns and pumps. Bounded, and it fails loudly if the
  /// spinner never clears.
  Future<void> pumpStorage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: StorageDataPage(databaseHelper: databaseHelper)),
    );
    var loaded = false;
    for (var i = 0; i < 200; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 25));
      if (!tester.any(find.byType(CircularProgressIndicator))) {
        loaded = true;
        break;
      }
    }
    if (!loaded) {
      throw StateError('StorageDataPage never finished loading its figures');
    }
    await tester.pumpAndSettle();
  }

  testWidgets('shows real record counts and usage figures from the device', (
    tester,
  ) async {
    await pumpStorage(tester);

    // Record counts come from COUNT queries over the existing tables —
    // a freshly created database really has zero rows everywhere.
    expect(find.text('Record counts'), findsOneWidget);
    for (final label in [
      'Customers',
      'Credit transactions',
      'Payments',
      'Cards',
      'Statement bills',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('0'), findsNWidgets(5));

    // Usage figures are read from the file system / image cache.
    expect(find.text('Usage'), findsOneWidget);
    expect(find.text('Database file'), findsOneWidget);
    expect(find.text('Image cache'), findsOneWidget);

    // Lazy list: bring the clear action into view before asserting on it.
    await tester.scrollUntilVisible(
      find.byKey(const Key('clearCacheButton')),
      200,
      scrollable: pageScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clearCacheButton')), findsOneWidget);
  });

  testWidgets('clearing the image cache is a real, confirmed action', (
    tester,
  ) async {
    await pumpStorage(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('clearCacheButton')),
      200,
      scrollable: pageScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clearCacheButton')));
    await tester.pumpAndSettle();

    expect(find.text('Image cache cleared.'), findsOneWidget);
    // SnackBar dismiss timer: advance past it so no timer leaks.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
