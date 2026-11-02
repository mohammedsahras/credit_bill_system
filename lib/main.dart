import 'package:flutter/material.dart';

import 'app.dart';
import 'app/presentation/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CreditBillApp(home: AuthWrapper()));
}
