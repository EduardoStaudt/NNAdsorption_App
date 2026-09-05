// motor_onnx_web.dart — onnxruntime-web (WASM) chamado por JS interop.
//
// O runtime é servido do próprio domínio (`web/ort/`), não de CDN: o CSP do
// Firebase Hosting só libera script de `'self'`, e assim o app não depende de
// um terceiro no ar pra prever. O `.wasm` só é baixado quando alguém roda a
// primeira predição — a landing não paga por isso.
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

const bool onnxDisponivel = true;

/// Pasta do runtime dentro de `web/`. O `.wasm` vive ao lado do `.js`.
const String _pastaRuntime = 'ort/';

@JS('ort')
external JSObject? get _ort;

@JS('ort.Tensor')
external JSFunction get _construtorTensor;

Completer<void>? _carga;

/// Injeta o script do onnxruntime uma vez só e configura o WASM.
Future<void> _garantirRuntime() {
  final emAndamento = _carga;
  if (emAndamento != null) return emAndamento.future;

  final pronto = Completer<void>();
  _carga = pronto;

  if (_ort != null) {
    _configurarWasm();
    pronto.complete();
    return pronto.future;
  }

  final script = web.HTMLScriptElement()
    ..src = '${_pastaRuntime}ort.wasm.min.js'
    ..async = true;

  script.addEventListener(
    'load',
    ((web.Event _) {
      _configurarWasm();
      pronto.complete();
    }).toJS,
  );
  script.addEventListener(
    'error',
    ((web.Event _) {
      _carga = null; // deixa uma próxima tentativa acontecer
      pronto.completeError(
        StateError(
          'não consegui carregar $_pastaRuntime'
          'ort.wasm.min.js',
        ),
      );
    }).toJS,
  );

  web.document.head!.appendChild(script);
  return pronto.future;
}

void _configurarWasm() {
  final wasm = _ort!
      .getProperty<JSObject>('env'.toJS)
      .getProperty<JSObject>('wasm'.toJS);
  // Uma thread só: threads exigem cross-origin isolation (COOP **e** COEP), e
  // o Hosting hoje manda só o COOP. Pedir mais faria o ORT tentar um worker e
  // cair de volta sozinho, com um erro no console pra ninguém.
  wasm.setProperty('numThreads'.toJS, 1.toJS);
  wasm.setProperty('proxy'.toJS, false.toJS);
  // URL absoluta, não `'ort/'`: o ORT usa este valor num `import()` dinâmico,
  // e um caminho relativo sem `./` o navegador lê como *nome de módulo* —
  // "Failed to resolve module specifier 'ort/ort-wasm-simd-threaded.mjs'".
  wasm.setProperty('wasmPaths'.toJS, _urlDoRuntime().toJS);
}

/// `<base href>` + a pasta do runtime. Segue o app onde ele for servido.
String _urlDoRuntime() {
  final base = web.document.baseURI;
  final raiz = base.isEmpty ? Uri.base : Uri.parse(base);
  return raiz.resolve(_pastaRuntime).toString();
}

/// Cria uma sessão a partir dos bytes do `.onnx`.
Future<Object> abrirSessao(Uint8List modelo) async {
  await _garantirRuntime();

  final opcoes = JSObject()
    ..setProperty('executionProviders'.toJS, <JSAny>['wasm'.toJS].toJS)
    ..setProperty('graphOptimizationLevel'.toJS, 'all'.toJS);

  final criar = _ort!.getProperty<JSObject>('InferenceSession'.toJS);
  final promessa = criar.callMethod<JSPromise<JSObject>>(
    'create'.toJS,
    modelo.toJS,
    opcoes,
  );
  return await promessa.toDart;
}

/// Roda a sessão com uma matriz `[linhas, colunas]` achatada em row-major.
///
/// É aqui que o lote ganha: N linhas vão numa chamada só, porque a rede é
/// vetorizada e o custo de N quase não sobe em relação a 1.
Future<Float32List> rodarSessao(
  Object sessao,
  Float32List entrada,
  int linhas,
  int colunas,
) async {
  final s = sessao as JSObject;
  final nomeEntrada = s
      .getProperty<JSArray<JSString>>('inputNames'.toJS)
      .toDart;
  final nomeSaida = s.getProperty<JSArray<JSString>>('outputNames'.toJS).toDart;

  final tensor = _construtorTensor.callAsConstructor<JSObject>(
    'float32'.toJS,
    entrada.toJS,
    <JSAny>[linhas.toJS, colunas.toJS].toJS,
  );

  final feeds = JSObject()..setProperty(nomeEntrada.first, tensor);
  final saida = await s
      .callMethod<JSPromise<JSObject>>('run'.toJS, feeds)
      .toDart;

  return saida
      .getProperty<JSObject>(nomeSaida.first)
      .getProperty<JSFloat32Array>('data'.toJS)
      .toDart;
}
