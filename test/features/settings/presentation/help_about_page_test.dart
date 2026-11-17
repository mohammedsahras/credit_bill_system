import 'dart:io';

import 'package:credit_bill_system/features/settings/presentation/pages/about_page.dart';
import 'package:credit_bill_system/features/settings/presentation/pages/help_support_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../settings_test_harness.dart';

void main() {
  testWidgets('FAQ answers are revealed by tapping their question', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HelpSupportPage()));
    await tester.pumpAndSettle();

    const answerNeedle = 'Everything stays on this device in the app';
    // Collapsed: the answer is not in the tree.
    expect(find.textContaining(answerNeedle), findsNothing);

    // The list is lazy — bring each question into view before tapping it.
    await tester.scrollUntilVisible(
      find.text('How do statement bills work?'),
      200,
      scrollable: pageScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('How do statement bills work?'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('countdown badge until the due date'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Where is my data stored?'),
      200,
      scrollable: pageScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Where is my data stored?'));
    await tester.pumpAndSettle();
    expect(find.textContaining(answerNeedle), findsOneWidget);
  });

  testWidgets('About shows the real bundled version and opens licenses', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));

    // The version comes from the bundled pubspec.yaml asset — a real
    // platform-channel/file read that only progresses on the real event
    // loop, while setState can only build on a pump. Alternate real-loop
    // turns with frame pumps: bounded, and it fails loudly if the
    // version never resolves.
    var resolved = false;
    for (var i = 0; i < 200; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 25));
      if (!tester.any(find.textContaining('Loading…'))) {
        resolved = true;
        break;
      }
    }
    if (!resolved) {
      throw StateError('About page never resolved the bundled version');
    }
    await tester.pumpAndSettle();

    // Expected value parsed from the same file the app bundles — the
    // screen must not drift from the actual build version.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:[ \t]*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1)!;
    final parts = version.split('+');
    final expected = parts.length > 1
        ? '${parts[0]} (build ${parts[1]})'
        : version;
    expect(find.text('Version $expected'), findsOneWidget);

    // Lazy list: the legal section sits below the fold.
    await tester.scrollUntilVisible(
      find.byKey(const Key('openLicensesButton')),
      200,
      scrollable: pageScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openLicensesButton')));
    await tester.pump(); // begin the route transition
    await tester.pump(const Duration(milliseconds: 400)); // complete it
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
