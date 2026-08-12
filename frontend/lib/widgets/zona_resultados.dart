// zona_resultados.dart — coluna central da tela binária: as duas curvas de
// saída e a faixa de KPIs embaixo.
//
// Os gráficos são montados aqui em vez de reusar `charts/line_profile_chart.dart`
// porque precisam do que aquele não faz: duas séries no mesmo eixo, uma delas
// tracejada, e legenda. Quando a tela binária substituir a de histórico, os dois
// viram um só — hoje mexer no compartilhado colocaria em risco a tela que
// funciona.
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/resultado_binario.dart';
import '../theme/app_sizes.dart';
import '../theme/colors.dart';

class ZonaResultados extends StatelessWidget {
  final ResultadoBinario resultado;

  const ZonaResultados({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Espaco.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GraficoRuptura(resultado: resultado),
          const SizedBox(height: Espaco.cartao),
          _GraficoTemperatura(resultado: resultado),
          const SizedBox(height: Espaco.cartao),
          _FaixaKpis(resultado: resultado),
        ],
      ),
    );
  }
}

/// Moldura comum dos dois gráficos: título com ícone e a caixa do card.
class _CartaoGrafico extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final Widget? legenda;
  final double altura;
  final Widget grafico;

  const _CartaoGrafico({
    required this.icone,
    required this.titulo,
    required this.altura,
    required this.grafico,
    this.legenda,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Container(
      padding: const EdgeInsets.all(Espaco.cartao),
      decoration: BoxDecoration(
        color: cores.panel,
        border: Border.all(color: cores.line, width: Borda.fina),
        borderRadius: BorderRadius.circular(Raio.campo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icone, size: Icone.p, color: cores.text2),
              const SizedBox(width: Espaco.xs),
              Text(
                titulo,
                style: TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: Tipo.dado,
                  fontWeight: FontWeight.w600,
                  color: cores.text,
                ),
              ),
              const Spacer(),
              ?legenda,
            ],
          ),
          const SizedBox(height: Espaco.cartao),
          SizedBox(height: altura, child: grafico),
        ],
      ),
    );
  }
}

/// Marca da legenda: o traço na cor da série, contínuo ou tracejado.
class _ChaveLegenda extends StatelessWidget {
  final Color cor;
  final bool tracejada;
  final String rotulo;

  const _ChaveLegenda({
    required this.cor,
    required this.rotulo,
    this.tracejada = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: Dim.tracoLegenda,
          height: Borda.foco,
          child: CustomPaint(
            painter: _TracoPainter(cor: cor, tracejada: tracejada),
          ),
        ),
        const SizedBox(width: Espaco.xs),
        Text(
          rotulo,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: Tipo.eixo,
            color: context.cores.text2,
          ),
        ),
      ],
    );
  }
}

class _TracoPainter extends CustomPainter {
  final Color cor;
  final bool tracejada;
  _TracoPainter({required this.cor, required this.tracejada});

  @override
  void paint(Canvas canvas, Size size) {
    final tinta = Paint()
      ..color = cor
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;

    if (!tracejada) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), tinta);
      return;
    }
    // Mesmo ritmo do `dashArray` da curva, pra a legenda não mentir
    const traco = 4.0;
    const vao = 3.0;
    for (var x = 0.0; x < size.width; x += traco + vao) {
      final fim = math.min(x + traco, size.width);
      canvas.drawLine(Offset(x, y), Offset(fim, y), tinta);
    }
  }

  @override
  bool shouldRepaint(_TracoPainter old) =>
      old.cor != cor || old.tracejada != tracejada;
}

/// Eixos, grade e moldura — iguais nos dois gráficos. `intervaloY` só é preciso
/// onde o eixo é curto e a faixa de valores estreita: sem ele o fl_chart cabe um
/// tick só e o gráfico fica sem escala legível.
FlTitlesData _eixos(
  BuildContext context,
  String eixoX,
  String eixoY, {
  double? intervaloY,
}) {
  final estilo = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontSize: Tipo.eixo,
    color: context.cores.text3,
  );
  return FlTitlesData(
    leftTitles: AxisTitles(
      axisNameWidget: Text(eixoY, style: estilo),
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: Dim.calhaEixoY,
        interval: intervaloY,
        minIncluded: false,
        maxIncluded: false,
        getTitlesWidget: (v, meta) => Text(meta.formattedValue, style: estilo),
      ),
    ),
    bottomTitles: AxisTitles(
      axisNameWidget: Text(eixoX, style: estilo),
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: Dim.calhaEixoX,
        getTitlesWidget: (v, meta) => Text(meta.formattedValue, style: estilo),
      ),
    ),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );
}

FlGridData _grade(BuildContext context, {double? intervaloY}) {
  final cores = context.cores;
  return FlGridData(
    horizontalInterval: intervaloY,
    getDrawingHorizontalLine: (_) =>
        FlLine(color: cores.line, strokeWidth: 0.5),
    getDrawingVerticalLine: (_) => FlLine(color: cores.line, strokeWidth: 0.5),
  );
}

FlBorderData _moldura(BuildContext context) => FlBorderData(
  show: true,
  border: Border.all(color: context.cores.line2, width: Borda.fina),
);

List<FlSpot> _pontos(List<double> xs, List<double> ys) =>
    List.generate(xs.length, (i) => FlSpot(xs[i], ys[i]));

/// Curva de ruptura: as duas frações molares no mesmo eixo.
class _GraficoRuptura extends StatelessWidget {
  final ResultadoBinario resultado;
  const _GraficoRuptura({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return _CartaoGrafico(
      icone: Icons.show_chart,
      titulo: 'Curva de ruptura',
      altura: Dim.alturaGraficoRuptura,
      legenda: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChaveLegenda(cor: cores.data1, rotulo: 'y₁ forte'),
          const SizedBox(width: Espaco.cartao),
          _ChaveLegenda(
            cor: cores.data4,
            rotulo: 'y₀ carreador',
            tracejada: true,
          ),
        ],
      ),
      grafico: LineChart(
        duration: Duracao.lenta,
        curve: Curves.easeOutCubic,
        LineChartData(
          minY: 0,
          maxY: 1,
          gridData: _grade(context),
          titlesData: _eixos(context, 'tempo [s]', 'fração molar'),
          borderData: _moldura(context),
          lineBarsData: [
            LineChartBarData(
              spots: _pontos(resultado.tempos, resultado.yForte),
              isCurved: true,
              color: cores.data1,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: _pontos(resultado.tempos, resultado.yCarreador),
              isCurved: true,
              color: cores.data4,
              barWidth: 2,
              dashArray: const [4, 3],
              dotData: const FlDotData(show: false),
            ),
          ],
          lineTouchData: _toque(context, (s) {
            final qual = s.barIndex == 0 ? 'y₁' : 'y₀';
            return 't=${s.x.toStringAsFixed(0)}s\n'
                '$qual=${s.y.toStringAsFixed(3)}';
          }),
        ),
      ),
    );
  }
}

/// Temperatura de saída: uma série só, na cor de série 3.
class _GraficoTemperatura extends StatelessWidget {
  final ResultadoBinario resultado;
  const _GraficoTemperatura({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    // Quatro faixas na altura que este card tem. Sai dos dados e não de um
    // número fixo pra continuar valendo quando a rede devolver outra escala.
    final minT = resultado.tSaida.reduce(math.min);
    final maxT = resultado.tSaida.reduce(math.max);
    final intervalo = math.max((maxT - minT) / 4, 0.1);

    return _CartaoGrafico(
      icone: Icons.thermostat,
      titulo: 'Temperatura de saída',
      altura: Dim.alturaGraficoTemperatura,
      grafico: LineChart(
        duration: Duracao.lenta,
        curve: Curves.easeOutCubic,
        LineChartData(
          gridData: _grade(context, intervaloY: intervalo),
          titlesData: _eixos(
            context,
            'tempo [s]',
            'T [K]',
            intervaloY: intervalo,
          ),
          borderData: _moldura(context),
          lineBarsData: [
            LineChartBarData(
              spots: _pontos(resultado.tempos, resultado.tSaida),
              isCurved: true,
              color: cores.data3,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: cores.data3.withValues(alpha: 0.10),
              ),
            ),
          ],
          lineTouchData: _toque(
            context,
            (s) =>
                't=${s.x.toStringAsFixed(0)}s\n'
                'T=${s.y.toStringAsFixed(1)}K',
          ),
        ),
      ),
    );
  }
}

LineTouchData _toque(
  BuildContext context,
  String Function(LineBarSpot s) texto,
) => LineTouchData(
  touchTooltipData: LineTouchTooltipData(
    getTooltipItems: (spots) => spots
        .map(
          (s) => LineTooltipItem(
            texto(s),
            const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: Tipo.label,
              color: Colors.white,
            ),
          ),
        )
        .toList(),
  ),
);

/// Os seis KPIs. Três por linha: com seis numa fileira só, os rótulos
/// quebrariam na largura que sobra pra coluna central.
class _FaixaKpis extends StatelessWidget {
  final ResultadoBinario resultado;
  const _FaixaKpis({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    final kpis = <Widget>[
      _CartaoKpi(rotulo: 't_break', valor: r.tBreak, unidade: 's'),
      _CartaoKpi(rotulo: 't_sat', valor: r.tSat, unidade: 's'),
      _CartaoKpi(rotulo: 'T_F', valor: r.tF, unidade: 's'),
      _CartaoKpi(rotulo: 't_st', valor: r.tSt, unidade: 's'),
      _CartaoKpi(rotulo: 'π_max', valor: r.piMax, casas: 3),
      _CartaoKpi(
        rotulo: 'severidade',
        valor: r.severidade,
        casas: 2,
        barra: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, restricoes) {
        // Três por linha, com o vão entre eles descontado da largura
        const porLinha = 3;
        final largura =
            (restricoes.maxWidth - Espaco.sm * (porLinha - 1)) / porLinha;
        return Wrap(
          spacing: Espaco.sm,
          runSpacing: Espaco.sm,
          children: [for (final k in kpis) SizedBox(width: largura, child: k)],
        );
      },
    );
  }
}

class _CartaoKpi extends StatelessWidget {
  final String rotulo;
  final double valor;
  final String? unidade;
  final int casas;

  /// `true` troca o número solto por barra de 0 a 1 com o valor ao lado.
  final bool barra;

  const _CartaoKpi({
    required this.rotulo,
    required this.valor,
    this.unidade,
    this.casas = 1,
    this.barra = false,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final texto = valor.toStringAsFixed(casas);

    return Container(
      padding: const EdgeInsets.all(Espaco.campo),
      decoration: BoxDecoration(
        color: cores.panel,
        border: Border.all(color: cores.line, width: Borda.fina),
        borderRadius: BorderRadius.circular(Raio.chip),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: Tipo.eixo,
              color: cores.text2,
            ),
          ),
          const SizedBox(height: Espaco.xxs),
          if (barra)
            _BarraSeveridade(valor: valor, texto: texto)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  texto,
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: Tipo.corpoGrande,
                    fontWeight: FontWeight.w500,
                    color: cores.text,
                  ),
                ),
                if (unidade != null) ...[
                  const SizedBox(width: Espaco.xxs),
                  Text(
                    unidade!,
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: Tipo.eixo,
                      color: cores.text3,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// Severidade é o único KPI comparável a um teto conhecido (0 a 1), então vale
/// a barra: dá a leitura antes de o olho processar o número.
class _BarraSeveridade extends StatelessWidget {
  final double valor;
  final String texto;

  const _BarraSeveridade({required this.valor, required this.texto});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Borda.foco),
            child: LinearProgressIndicator(
              value: valor.clamp(0.0, 1.0),
              minHeight: Borda.foco * 2,
              backgroundColor: cores.line,
              valueColor: AlwaysStoppedAnimation(cores.accent),
            ),
          ),
        ),
        const SizedBox(width: Espaco.xs),
        Text(
          texto,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: Tipo.corpoGrande,
            fontWeight: FontWeight.w500,
            color: cores.text,
          ),
        ),
      ],
    );
  }
}
