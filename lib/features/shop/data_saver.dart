import 'data_saver_stub.dart'
    if (dart.library.js_interop) 'data_saver_web.dart' as impl;

/// True when the browser Save-Data flag is on. Other platforms use the
/// Account autoplay choice instead.
bool readSaveData() => impl.readSaveData();
