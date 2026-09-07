// motor_lote.dart — escolhe a implementação conforme a plataforma.
export 'motor_lote_stub.dart'
    if (dart.library.js_interop) 'motor_lote_web.dart';
