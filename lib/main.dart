import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/crash_log.dart';

void main() {
  // ensureInitialized and runApp must share a zone. Initializing the binding
  // outside this zone makes Flutter assert "Zone mismatch" from runApp, and
  // CrashLog records that as bloom.crash.
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    CrashLog.install();
    runApp(const ProviderScope(child: BloomlyApp()));
  }, CrashLog.record);
}
