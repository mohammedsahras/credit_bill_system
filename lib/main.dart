import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart' as ffi;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as ffi_web;
import 'app.dart';
import 'app/presentation/auth_wrapper.dart';

// Set up the database factory based on the target platform.
// kIsWeb is a compile-time constant set by the Flutter build system:
//   - true when building for Web
//   - false for native platforms (Android, iOS, Windows, macOS, Linux)
// In JIT debug mode (flutter run), kIsWeb correctly evaluates based on
// the target platform, so we use it instead of bool.fromEnvironment.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up the database factory based on platform.
  // Never initialize native FFI on Web.
  if (kIsWeb) {
    // Web: Use IndexedDB-backed FFI-Web factory.
    // Do NOT call ffi.sqfliteFfiInit() on Web.
    databaseFactory = ffi_web.databaseFactoryFfiWeb;
  } else {
    // Android, iOS, Windows, macOS, Linux: Use native FFI factory.
    // Initialize FFI bindings only for native platforms.
    ffi.sqfliteFfiInit();
    databaseFactory = ffi.databaseFactoryFfi;
  }

  runApp(const CreditBillApp(home: AuthWrapper()));
}