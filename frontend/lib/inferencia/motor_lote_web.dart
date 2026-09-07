// motor_lote_web.dart — a ponte com o Web Worker que roda as redes do lote.
//
// Só o `session.run` mora lá; o resto da cadeia continua em Dart (ver
// `web/lote_worker.js`). O ganho é a UI não congelar: 30 mil linhas na thread
// principal travam a página por minutos.
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Caminho do worker dentro de `web/`.
const String _arquivoWorker = 'lote_worker.js';

/// Roda as redes num Worker. Uma instância por lote: encerrar mata a thread.
class MotorLote {
  web.Worker? _worker;
  final _pendentes = <int, Completer<Float32List>>{};
  int _proximoId = 0;

  /// Quanto o worker levou pra abrir as duas sessões. Zero antes de carregar.
  int msDeCarga = 0;

  bool get ativo => _worker != null;

  /// Sobe o worker e carrega os dois modelos dentro dele. Devolve `false` se o
  /// navegador não deixar — aí quem chama roda na thread principal mesmo.
  Future<bool> iniciar() async {
    if (_worker != null) return true;
    try {
      final url = _resolver(_arquivoWorker);
      // Clássico, não módulo: o `ort.wasm.min.js` é UMD e só se pendura no
      // global via `importScripts`. Como módulo ele não exporta nada.
      final worker = web.Worker(url.toJS);
      worker.onmessage = ((web.MessageEvent evento) {
        _receber(evento.data as JSObject);
      }).toJS;
      // Erro de carga do próprio script (404, sintaxe): não vira mensagem.
      worker.onerror = ((web.Event _) {
        _falharTudo('o worker do lote não subiu');
      }).toJS;
      _worker = worker;

      await _enviar(
        JSObject()
          ..setProperty('tipo'.toJS, 'carregar'.toJS)
          ..setProperty('base'.toJS, _base().toJS),
      );
      return true;
    } catch (e) {
      encerrar();
      return false;
    }
  }

  /// Roda uma das redes ('tempos' ou 'forma') sobre `[linhas, colunas]`.
  Future<Float32List> rodar(
    String rede,
    Float32List entrada,
    int linhas,
    int colunas,
  ) async {
    final resposta = await _enviar(
      JSObject()
        ..setProperty('tipo'.toJS, 'rodar'.toJS)
        ..setProperty('rede'.toJS, rede.toJS)
        ..setProperty('dados'.toJS, entrada.toJS)
        ..setProperty('linhas'.toJS, linhas.toJS)
        ..setProperty('colunas'.toJS, colunas.toJS),
    );
    return resposta;
  }

  /// Mata a thread. O que estiver pendente falha — é o que cancelar faz.
  void encerrar() {
    _worker?.terminate();
    _worker = null;
    _falharTudo('lote encerrado');
  }

  Future<Float32List> _enviar(JSObject mensagem) {
    final worker = _worker;
    if (worker == null) {
      return Future.error(StateError('worker do lote não está de pé'));
    }
    final id = _proximoId++;
    mensagem.setProperty('id'.toJS, id.toJS);
    final espera = Completer<Float32List>();
    _pendentes[id] = espera;
    worker.postMessage(mensagem);
    return espera.future;
  }

  void _receber(JSObject dados) {
    final id = dados.getProperty<JSNumber>('id'.toJS).toDartInt;
    final espera = _pendentes.remove(id);
    if (espera == null) return;

    final tipo = dados.getProperty<JSString>('tipo'.toJS).toDart;
    switch (tipo) {
      case 'carregado':
        msDeCarga = dados.getProperty<JSNumber>('ms'.toJS).toDartInt;
        espera.complete(Float32List(0));
      case 'saida':
        espera.complete(dados.getProperty<JSFloat32Array>('dados'.toJS).toDart);
      default:
        espera.completeError(
          StateError(dados.getProperty<JSString>('mensagem'.toJS).toDart),
        );
    }
  }

  void _falharTudo(String motivo) {
    for (final espera in _pendentes.values) {
      if (!espera.isCompleted) espera.completeError(StateError(motivo));
    }
    _pendentes.clear();
  }

  /// `<base href>` do app: o worker precisa dela pra achar o runtime e os
  /// modelos, já que a URL dele não diz onde o app foi servido.
  String _base() {
    final base = web.document.baseURI;
    return base.isEmpty ? Uri.base.toString() : base;
  }

  String _resolver(String caminho) =>
      Uri.parse(_base()).resolve(caminho).toString();
}

/// Web sempre tem Worker; o stub da VM é que diz não.
bool get suportaWorker => true;
