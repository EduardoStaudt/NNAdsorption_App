// motor_onnx_stub.dart — fora do navegador não há onnxruntime.
//
// Existe pra a compilação passar na VM (onde `flutter test` roda) e no
// desktop. As funções puras da inferência — contrato, features, isoterma,
// grade τ — não passam por aqui e continuam testáveis normalmente.
import 'dart:typed_data';

const bool onnxDisponivel = false;

Never _semRuntime() => throw UnsupportedError(
  'A inferência ONNX só roda no navegador (onnxruntime-web). '
  'Nesta plataforma não há runtime.',
);

Future<Object> abrirSessao(Uint8List modelo) async => _semRuntime();

Future<Float32List> rodarSessao(
  Object sessao,
  Float32List entrada,
  int linhas,
  int colunas,
) async => _semRuntime();
