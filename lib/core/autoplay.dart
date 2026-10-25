import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Always plays on every network unless the device Save-Data flag is on.
/// Wi-Fi only and Never are explicit Account choices.
enum AutoplayChoice { always, wifi, never }

class AutoplaySetting extends ChangeNotifier {
  AutoplaySetting() {
    _load();
  }

  static const storageKey = 'bloom.autoplay';

  AutoplayChoice choice = AutoplayChoice.always;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    final next = AutoplayChoice.values.where((item) => item.name == raw).firstOrNull;
    if (next != null && next != choice) {
      choice = next;
      notifyListeners();
    }
  }

  Future<void> setChoice(AutoplayChoice next) async {
    choice = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, next.name);
  }
}

final autoplayProvider = ChangeNotifierProvider<AutoplaySetting>((ref) {
  return AutoplaySetting();
});
