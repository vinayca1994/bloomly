import 'package:flutter/foundation.dart';

/// Records uncaught Flutter and platform errors.
///
/// The log line is `bloom.crash` plus the exception. It does not upload
/// anywhere until a reporting URL is added beside this hook.
class CrashLog {
  /// Call this in the same zone as `runApp`, after the binding is initialized.
  static void install() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      record(details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack);
      return true;
    };
  }

  static void record(Object error, StackTrace? stack) {
    debugPrint('bloom.crash $error');
    if (stack != null) debugPrint('$stack');
  }
}
