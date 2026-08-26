// resultado_binario.dart — saída da predição do modelo binário.
//
// Ainda não existe rede binária treinada (ver CLAUDE.md: `/predict` está
// desligado), então `ResultadoBinario.exemplo()` devolve curvas sintéticas
// plausíveis. Os widgets leem só desta classe: quando a API entrar, troca-se a
// origem dos dados num lugar só e a tela não muda.
import 'dart:math' as math;

import 'param_defs.dart' show valoresPadrao;

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

  /// Curvas sintéticas com os valores padrão dos parâmetros.
  factory ResultadoBinario.exemplo() =>
      ResultadoBinario.dosParametros(valoresPadrao());

  /// Curvas sintéticas que **respondem aos parâmetros de entrada**, pra a tela
  /// mostrar causa e efeito enquanto a rede binária não existe.
  ///
  /// Não é modelo: é uma sigmoide cujo centro anda com o tempo de residência
  /// (L/vs), cuja inclinação anda com o kL do gás forte, e cuja onda térmica
  /// cresce com o calor de adsorção. Serve pra dois experimentos diferentes
  /// desenharem curvas diferentes — sem isso a comparação não compara nada.
  /// Quando a API devolver o resultado de verdade, isto sai inteiro.
  factory ResultadoBinario.dosParametros(Map<String, double> p) {
    double valor(String chave, double reserva) => p[chave] ?? reserva;

    // Tempo de residência do leito: é ele que decide quando a frente sai.
    final residencia = valor('L', 0.5) / math.max(valor('vs', 0.01), 1e-4);
    final centro = (residencia * 4).clamp(60.0, 900.0);
    // kL alto = transferência rápida = frente mais vertical.
    final inclinacao = 0.02 + valor('kL_2', 0.1) * 0.6;
    final patamarForte = (1 - valor('y0', 0.5)).clamp(0.05, 0.95);
    final tEntrada = valor('T_in', 298.0);
    // O pico térmico sobe com o calor de adsorção dos dois componentes.
    final pico = (valor('dH_1', 25.0) + valor('dH_2', 25.0)) * 0.36;

    final tMax = centro * 2.1;
    final passo = tMax / 105;
    final tempos = <double>[];
    final yForte = <double>[];
    final yCarreador = <double>[];
    final tSaida = <double>[];

    for (var t = 0.0; t <= tMax; t += passo) {
      final s = 1 / (1 + math.exp(-inclinacao * (t - centro)));
      tempos.add(t);
      yForte.add(patamarForte * s);
      yCarreador.add(
        valor('y0', 0.5) +
            0.25 *
                math.exp(-0.003 * (t - centro * 0.4)) *
                math.max(0, 1 - 1.2 * s),
      );
      tSaida.add(
        tEntrada +
            5 +
            pico *
                math.exp(
                  -4 / (centro * centro) * math.pow(t - centro * 0.9, 2),
                ),
      );
    }

    // Os tempos característicos saem da mesma sigmoide: 5%, 95% e o fim da
    // janela simulada.
    double quando(double fracao) =>
        centro + math.log(fracao / (1 - fracao)) / inclinacao;

    return ResultadoBinario(
      tBreak: quando(0.05),
      tSat: quando(0.95),
      tF: tMax,
      tSt: centro,
      piMax: patamarForte,
      severidade: (pico / 40).clamp(0.0, 1.0),
      tempos: tempos,
      yForte: yForte,
      yCarreador: yCarreador,
      tSaida: tSaida,
    );
  }

  Map<String, dynamic> paraJson() => {
    't_break': tBreak,
    't_sat': tSat,
    't_f': tF,
    't_st': tSt,
    'pi_max': piMax,
    'severidade': severidade,
    'tempos': tempos,
    'y_forte': yForte,
    'y_carreador': yCarreador,
    't_saida': tSaida,
  };

  factory ResultadoBinario.deJson(Map<String, dynamic> json) {
    List<double> lista(String chave) => [
      for (final v in json[chave] as List) (v as num).toDouble(),
    ];
    double num_(String chave) => (json[chave] as num).toDouble();

    return ResultadoBinario(
      tBreak: num_('t_break'),
      tSat: num_('t_sat'),
      tF: num_('t_f'),
      tSt: num_('t_st'),
      piMax: num_('pi_max'),
      severidade: num_('severidade'),
      tempos: lista('tempos'),
      yForte: lista('y_forte'),
      yCarreador: lista('y_carreador'),
      tSaida: lista('t_saida'),
    );
  }
}
