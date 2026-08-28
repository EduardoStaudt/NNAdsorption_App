// arquivo_local_web.dart — escolher e baixar arquivo dentro do navegador.
//
// Flutter Web desenha num canvas e não tem seletor de arquivo nem download
// próprios: os dois são DOM puro. Aqui isso é feito com `package:web` (e não
// `dart:html`, que está descontinuado e não compila pra Wasm).
import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'arquivo_local.dart';

/// Abre o seletor do navegador e devolve o arquivo escolhido (null se cancelar).
///
/// `<input type=file>` só abre dentro de um gesto do usuário — por isso esta
/// função tem que ser chamada direto do `onTap`, sem `await` antes.
Future<ArquivoEscolhido?> escolherArquivo(List<String> extensoes) {
  final entrada = web.HTMLInputElement()
    ..type = 'file'
    ..accept = extensoes.map((e) => '.$e').join(',');

  final resposta = Completer<ArquivoEscolhido?>();

  entrada.onchange = ((web.Event _) {
    final arquivo = entrada.files?.item(0);
    if (arquivo == null) {
      resposta.complete(null);
      return;
    }
    _lerArquivo(arquivo).then(resposta.complete);
  }).toJS;

  // `cancel` cobre fechar a janela sem escolher nada. Nem todo navegador
  // dispara, então o Completer também é protegido por `isCompleted` na leitura.
  entrada.oncancel = ((web.Event _) {
    if (!resposta.isCompleted) resposta.complete(null);
  }).toJS;

  entrada.click();
  return resposta.future;
}

/// Entrega bytes ao navegador como download.
///
/// O truque é o de sempre: um Blob vira URL temporária, uma âncora invisível
/// aponta pra ela e leva um clique programático. A URL é revogada em seguida
/// pra o blob não ficar preso na memória da aba.
void baixarBytes(Uint8List bytes, String nomeArquivo, String tipoMime) {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: tipoMime),
  );
  final url = web.URL.createObjectURL(blob);

  final ancora = web.HTMLAnchorElement()
    ..href = url
    ..download = nomeArquivo
    ..style.display = 'none';

  web.document.body?.appendChild(ancora);
  ancora.click();
  ancora.remove();
  web.URL.revokeObjectURL(url);
}

bool get suportaArrastar => true;

web.EventListener? _ouvinteArrastar;
web.EventListener? _ouvinteSoltar;

/// Aceita arquivo solto em qualquer lugar da página.
///
/// O ouvinte é do documento, não de um retângulo: o canvas do Flutter fica por
/// cima de tudo e não repassa evento de arraste pra widget nenhum. Na prática
/// isso é até melhor — soltar em qualquer canto do modal funciona.
void aoArrastarArquivo(void Function(ArquivoEscolhido) quandoSoltar) {
  pararDeOuvirArraste();

  // Sem `preventDefault` no dragover o navegador abre o arquivo numa aba nova.
  _ouvinteArrastar = ((web.Event evento) => evento.preventDefault()).toJS;
  _ouvinteSoltar = ((web.Event evento) {
    evento.preventDefault();
    final arquivo = (evento as web.DragEvent).dataTransfer?.files.item(0);
    if (arquivo == null) return;
    _lerArquivo(arquivo).then((escolhido) {
      if (escolhido != null) quandoSoltar(escolhido);
    });
  }).toJS;

  web.document.addEventListener('dragover', _ouvinteArrastar);
  web.document.addEventListener('drop', _ouvinteSoltar);
}

void pararDeOuvirArraste() {
  if (_ouvinteArrastar != null) {
    web.document.removeEventListener('dragover', _ouvinteArrastar);
    _ouvinteArrastar = null;
  }
  if (_ouvinteSoltar != null) {
    web.document.removeEventListener('drop', _ouvinteSoltar);
    _ouvinteSoltar = null;
  }
}

Future<ArquivoEscolhido?> _lerArquivo(web.File arquivo) {
  final resposta = Completer<ArquivoEscolhido?>();
  final leitor = web.FileReader();

  leitor.onload = ((web.Event _) {
    final buffer = leitor.result as JSArrayBuffer?;
    if (resposta.isCompleted) return;
    resposta.complete(
      buffer == null
          ? null
          : ArquivoEscolhido(arquivo.name, buffer.toDart.asUint8List()),
    );
  }).toJS;

  leitor.onerror = ((web.Event _) {
    if (!resposta.isCompleted) resposta.complete(null);
  }).toJS;

  leitor.readAsArrayBuffer(arquivo);
  return resposta.future;
}
