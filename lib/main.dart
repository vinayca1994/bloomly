import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/crash_log.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  CrashLog.install();
  runZonedGuarded(
    () => runApp(const ProviderScope(child: BloomlyApp())),
    CrashLog.record,
  );
}
