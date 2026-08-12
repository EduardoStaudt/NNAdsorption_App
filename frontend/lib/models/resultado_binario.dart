// resultado_binario.dart — saída da predição do modelo binário.
//
// Ainda não existe rede binária treinada (ver CLAUDE.md: `/predict` está
// desligado), então `ResultadoBinario.exemplo()` devolve curvas sintéticas
// plausíveis. Os widgets leem só desta classe: quando a API entrar, troca-se a
// origem dos dados num lugar só e a tela não muda.
import 'dart:math' as math;

class ResultadoBinario {
  /// KPIs do topo. Tempos em segundos; `piMax` e `severidade` adimensionais.
  final double tBreak;
  final double tSat;
  final double tF;
  final double tSt;
  final double piMax;

  /// 0 a 1 — o único KPI que vira barra em vez de número solto.
  final double severidade;

  /// Eixo do tempo, compartilhado pelas três curvas.
  final List<double> tempos;

  /// Fração molar do gás forte (y₁) e do carreador (y₀) na saída.
  final List<double> yForte;
  final List<double> yCarreador;

  /// Temperatura de saída, em K.
  final List<double> tSaida;

  const ResultadoBinario({
    required this.tBreak,
    required this.tSat,
    required this.tF,
    required this.tSt,
    required this.piMax,
    required this.severidade,
    required this.tempos,
    required this.yForte,
    required this.yCarreador,
    required this.tSaida,
  });

  /// Curvas sintéticas pra desenhar a tela enquanto a rede binária não existe.
  /// A ruptura é uma sigmoide centrada em t=200 s; o carreador decai à medida
  /// que o forte passa; a temperatura faz o pico da onda térmica.
  factory ResultadoBinario.exemplo() {
    const passo = 4.0;
    const tMax = 420.0;
    final tempos = <double>[];
    final yForte = <double>[];
    final yCarreador = <double>[];
    final tSaida = <double>[];

    for (var t = 0.0; t <= tMax; t += passo) {
      final s = 1 / (1 + math.exp(-0.08 * (t - 200)));
      tempos.add(t);
      yForte.add(0.75 * s);
      yCarreador.add(
        0.50 + 0.25 * math.exp(-0.003 * (t - 80)) * math.max(0, 1 - 1.2 * s),
      );
      tSaida.add(303 + 18 * math.exp(-0.0004 * math.pow(t - 180, 2)));
    }

    return ResultadoBinario(
      tBreak: 127.3,
      tSat: 289.1,
      tF: 412.6,
      tSt: 206.3,
      piMax: 0.987,
      severidade: 0.42,
      tempos: tempos,
      yForte: yForte,
      yCarreador: yCarreador,
      tSaida: tSaida,
    );
  }
}
