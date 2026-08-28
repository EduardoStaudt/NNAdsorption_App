// arquivo_local.dart — escolher e baixar arquivo, sem depender da plataforma.
//
// Só o navegador tem `<input type=file>` e download por âncora, então a
// implementação de verdade vive em `arquivo_local_web.dart` e entra por import
// condicional. No desktop o stub responde "não dá" em vez de quebrar a
// compilação — o app é web, mas `flutter test` roda na VM.
import 'dart:typed_data';

export 'arquivo_local_stub.dart'
    if (dart.library.js_interop) 'arquivo_local_web.dart';

/// Um arquivo que a pessoa escolheu: o nome importa porque o backend decide o
/// parser pela extensão.
class ArquivoEscolhido {
  final String nome;
  final Uint8List bytes;

  const ArquivoEscolhido(this.nome, this.bytes);

  /// Tamanho legível pra mostrar ao lado do nome.
  String get tamanhoLegivel {
    if (bytes.length < 1024) return '${bytes.length} B';
    if (bytes.length < 1024 * 1024) {
      return '${(bytes.length / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
