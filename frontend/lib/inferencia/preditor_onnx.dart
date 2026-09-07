// preditor_onnx.dart — a cascata completa, do parâmetro da tela à curva.
//
//   X31 (físico) → X47 (enriquecido, com log) → rede TEMPOS → tb, ts, πmax
//                                    │                            │
//                                    └──── + 3 tempos + πmax → rede FORMA
//                                                                 │
//                                              y0(τ), Tout(τ) → eixo em segundos
//
// Porte fiel de `reference/exemplo_inferencia.py`. Duas regras que não podem
// ser esquecidas:
//   1. **Nada de z-score.** Os `.onnx` normalizam por dentro; entra número
//      físico, sai número físico.
//   2. **Enriquece antes, loga depois** (ver `features.dart`).
//
// Os dois modelos são carregados uma vez e ficam em memória: são 39 MB, e
// recriar a sessão a cada predição jogaria fora o ganho todo.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/resultado_binario.dart';
import 'contrato.dart';
import 'features.dart';
import 'grade_tau.dart';
import 'isoterma.dart';
import 'motor_onnx.dart';

/// Tamanho do vetor que entra na rede de tempos (31 crus + 16 derivadas).
const int _dimEnriquecida = 47;

/// A rede de forma recebe o mesmo vetor mais log(tb/tst), log(ts/tst),
/// log(TF/tst) = log(2) e πmax.
const int _dimForma = _dimEnriquecida + 4;

/// Quem executa uma das redes sobre uma matriz `[linhas, colunas]`. O padrão
/// é a sessão desta thread; o lote passa a do Web Worker, que roda fora da UI.
typedef ExecutorRede =
    Future<Float32List> Function(
      String rede,
      Float32List entrada,
      int linhas,
      int colunas,
    );

const String _caminhoTempos = 'assets/onnx/modelo_tempos_v22.onnx';
const String _caminhoForma = 'assets/onnx/modelo_forma_v22.onnx';

/// Roda a rede v22 inteiramente no cliente. Singleton: `PreditorOnnx.instancia`.
class PreditorOnnx {
  PreditorOnnx._();

  static final PreditorOnnx instancia = PreditorOnnx._();

  Object? _tempos;
  Object? _forma;
  Future<void>? _cargaEmAndamento;

  bool get carregado => _tempos != null && _forma != null;

  /// Carrega os dois `.onnx`. Chamadas concorrentes compartilham a mesma carga.
  Future<void> carregar() {
    if (carregado) return Future.value();
    return _cargaEmAndamento ??= _carregar();
  }

  Future<void> _carregar() async {
    final relogio = Stopwatch()..start();
    try {
      final tempos = await rootBundle.load(_caminhoTempos);
      final forma = await rootBundle.load(_caminhoForma);
      _tempos = await abrirSessao(tempos.buffer.asUint8List());
      _forma = await abrirSessao(forma.buffer.asUint8List());
      debugPrint(
        '[onnx] Modelos ONNX carregados em ${relogio.elapsedMilliseconds} ms',
      );
    } catch (e) {
      _cargaEmAndamento = null; // permite tentar de novo
      debugPrint('[onnx] falha ao carregar os modelos: $e');
      rethrow;
    }
  }

  /// Prediz um experimento. É o lote de tamanho 1 — mesma cascata.
  Future<ResultadoBinario> predizer(Map<String, double> paramsDaTela) async {
    // A carga fica fora do cronômetro: na primeira predição ela domina tudo
    // (39 MB de modelo) e o número de dentro é o que interessa medir.
    await carregar();
    final relogio = Stopwatch()..start();
    final r = (await predizerLote([paramsDaTela], comLog: false)).first;
    debugPrint('[onnx] Predição levou ${relogio.elapsedMilliseconds} ms');
    return r;
  }

  /// Prediz N experimentos vindos da tela (chaves e unidades da interface).
  Future<List<ResultadoBinario>> predizerLote(
    List<Map<String, double>> lista, {
    bool comLog = true,
  }) => predizerLoteX31([
    for (final params in lista) montarX31(params),
  ], comLog: comLog);

  /// Prediz N experimentos já no formato do contrato, com **uma chamada de
  /// cada rede**.
  ///
  /// É onde o surrogate ganha do solver: a rede é vetorizada, então mil curvas
  /// custam quase o mesmo que uma. Rodar num laço jogaria isso fora.
  ///
  /// Recebe X(31) pronto porque a planilha do lote já vem nos nomes e nas
  /// unidades do contrato — passar por `montarX31` obrigaria a traduzir de
  /// volta pras chaves da tela só pra traduzir de novo.
  ///
  /// `executor` troca quem roda as redes: com o Worker do lote, esta thread
  /// nem chega a carregar os 39 MB de modelo.
  Future<List<ResultadoBinario>> predizerLoteX31(
    List<List<double>> vetores, {
    bool comLog = true,
    ExecutorRede? executor,
  }) async {
    if (vetores.isEmpty) return const [];
    if (executor == null) await carregar();
    final rodar =
        executor ??
        (String rede, Float32List entrada, int linhas, int colunas) =>
            rodarSessao(
              rede == 'tempos' ? _tempos! : _forma!,
              entrada,
              linhas,
              colunas,
            );

    final relogio = Stopwatch()..start();
    final n = vetores.length;

    // 1) matriz [n, 47] achatada, já com log nas colunas certas
    final xl = Float32List(n * _dimEnriquecida);
    final tst = List<double>.filled(n, 0);
    final severidade = List<double>.filled(n, 0);
    final avisos = <List<String>>[];

    for (var i = 0; i < n; i++) {
      final x31 = vetores[i];
      avisos.add(validar(x31));
      tst[i] = tstAncora(x31);
      severidade[i] = severidadeRegime(x31);
      final x47 = xEnriquecido(x31);
      for (var j = 0; j < _dimEnriquecida; j++) {
        xl[i * _dimEnriquecida + j] = x47[j];
      }
    }

    // 2) rede TEMPOS → [log(tb/tst), log(ts/tst), πmax]
    final yt = await rodar('tempos', xl, n, _dimEnriquecida);

    // 3) entrada da rede FORMA = enriquecido + 3 tempos + πmax
    final ln2 = 0.6931471805599453; // log(2): TF = 2·tst, sempre
    final xf = Float32List(n * _dimForma);
    for (var i = 0; i < n; i++) {
      final destino = i * _dimForma;
      xf.setRange(destino, destino + _dimEnriquecida, xl, i * _dimEnriquecida);
      xf[destino + _dimEnriquecida + 0] = yt[i * 3 + 0];
      xf[destino + _dimEnriquecida + 1] = yt[i * 3 + 1];
      xf[destino + _dimEnriquecida + 2] = ln2;
      xf[destino + _dimEnriquecida + 3] = yt[i * 3 + 2];
    }

    // 4) rede FORMA → 100 pontos de y0 + 100 de Tout
    final yf = await rodar('forma', xf, n, _dimForma);
    final largura = yf.length ~/ n; // 200

    // 5) monta as curvas em segundos
    final resultados = <ResultadoBinario>[];
    for (var i = 0; i < n; i++) {
      final tb = math.exp(yt[i * 3 + 0]) * tst[i];
      final ts = math.exp(yt[i * 3 + 1]) * tst[i];
      final piMax = yt[i * 3 + 2].toDouble();
      final tf = 2.0 * tst[i];

      final base = i * largura;
      final m = largura ~/ 2;
      final yCarreador = <double>[];
      final yForte = <double>[];
      final tSaida = <double>[];
      for (var j = 0; j < m; j++) {
        final y0 = yf[base + j].toDouble().clamp(0.0, 1.0);
        yCarreador.add(y0);
        yForte.add(1.0 - y0);
        tSaida.add(yf[base + m + j].toDouble());
      }

      resultados.add(
        ResultadoBinario(
          tBreak: tb,
          tSat: ts,
          tF: tf,
          tSt: tst[i],
          piMax: piMax,
          severidade: severidade[i],
          tempos: montarEixoTempo(tb, ts, tf),
          yForte: yForte,
          yCarreador: yCarreador,
          tSaida: tSaida,
          avisos: avisos[i],
        ),
      );
    }

    if (comLog) {
      debugPrint(
        '[onnx] Lote de $n predições em ${relogio.elapsedMilliseconds} ms',
      );
    }
    return resultados;
  }
}
