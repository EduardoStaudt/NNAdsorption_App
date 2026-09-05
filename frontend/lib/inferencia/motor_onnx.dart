// motor_onnx.dart — a única parte da inferência que depende da plataforma.
//
// No navegador quem roda os `.onnx` é o onnxruntime-web (WASM), chamado por
// JS interop. Fora dele não há runtime, e o stub existe só pra o código
// compilar — `flutter test` roda na VM, onde `dart:js_interop` nem existe.
//
// A sessão é um objeto opaco de propósito: quem orquestra (`preditor_onnx`)
// não precisa saber o que tem dentro, e assim toda a lógica portada da lib
// Python fica testável fora do navegador.
export 'motor_onnx_stub.dart'
    if (dart.library.js_interop) 'motor_onnx_web.dart';
