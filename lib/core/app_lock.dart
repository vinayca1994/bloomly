import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AppLockController extends ChangeNotifier {
  AppLockController({FlutterSecureStorage? storage, LocalAuthentication? auth})
    : _storage = storage ?? const FlutterSecureStorage(),
      _auth = auth ?? LocalAuthentication();

  static const _key = 'bloomly.biometric';

  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  bool supported = false;
  bool enabled = false;
  bool locked = false;
  bool ready = false;
  bool prompting = false;
  String label = 'biometrics';
  bool _disposed = false;
  bool suppressResume = false;
  bool sawResumeDuringPrompt = false;

  Future<void> load() async {
    if (kIsWeb) {
      supported = false;
      ready = true;
      _notify();
      return;
    }
    try {
      supported = await _auth.isDeviceSupported();
      final stored = await _storage.read(key: _key);
      enabled = stored == '1';
      label = await _label();
    } catch (_) {
      supported = false;
      enabled = false;
    }
    ready = true;
    _notify();
  }

  Future<String> _label() async {
    final types = await _auth.getAvailableBiometrics();
    if (types.contains(BiometricType.face)) {
      return defaultTargetPlatform == TargetPlatform.iOS ? 'Face ID' : 'face unlock';
    }
    if (types.contains(BiometricType.fingerprint)) return 'fingerprint';
    return 'biometrics';
  }

  void engage() {
    if (!enabled || !supported || locked) return;
    locked = true;
    _notify();
  }

  void disengage() {
    if (!locked) return;
    locked = false;
    _notify();
  }

  Future<bool> unlock() async {
    prompting = true;
    sawResumeDuringPrompt = false;
    _notify();
    final ok = await _authenticate();
    prompting = false;
    if (!sawResumeDuringPrompt) suppressResume = true;
    if (ok) locked = false;
    _notify();
    return ok;
  }

  Future<String?> setEnabled(bool value) async {
    if (!supported) return 'This phone has no fingerprint or Face ID.';
    if (value) {
      prompting = true;
      sawResumeDuringPrompt = false;
      final ok = await _authenticate();
      prompting = false;
      if (!sawResumeDuringPrompt) suppressResume = true;
      if (!ok) {
        _notify();
        return 'Could not confirm it is you.';
      }
    }
    enabled = value;
    if (!value) locked = false;
    try {
      await _storage.write(key: _key, value: value ? '1' : '0');
    } catch (_) {
      enabled = false;
      _notify();
      return 'Could not save the unlock setting.';
    }
    _notify();
    return null;
  }

  Future<bool> _authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Bloom',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
