import 'dart:js_interop';

bool readSaveData() {
  try {
    final connection = _connection;
    if (connection == null) return false;
    return _Conn(connection).saveData ?? false;
  } catch (_) {
    return false;
  }
}

@JS('navigator.connection')
external JSObject? get _connection;

extension type _Conn(JSObject _) implements JSObject {
  external bool? get saveData;
}
