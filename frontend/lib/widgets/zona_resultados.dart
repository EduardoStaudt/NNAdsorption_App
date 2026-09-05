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

  /// Experimento do histórico sobreposto ao atual, ou `null` sem comparação.
  final ResultadoBinario? comparacao;
  final String? nomeComparacao;
  final VoidCallback? onRemoverComparacao;

  const ZonaResultados({
    super.key,
    required this.resultado,
    this.comparacao,
    this.nomeComparacao,
    this.onRemoverComparacao,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Espaco.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Cabecalho(),
          if (comparacao != null && nomeComparacao != null) ...[
            const SizedBox(height: Espaco.sm),
            _FaixaComparacao(
              nome: nomeComparacao!,
              onRemover: onRemoverComparacao,
            ),
          ],
          const SizedBox(height: Espaco.cartao),
          _GraficoRuptura(resultado: resultado, comparacao: comparacao),
          const SizedBox(height: Espaco.cartao),
          _GraficoTemperatura(resultado: resultado, comparacao: comparacao),
          const SizedBox(height: Espaco.cartao),
          _FaixaKpis(resultado: resultado, comparacao: comparacao),
        ],
      ),
    );
  }
}

/// Alpha das curvas do experimento comparado. Elas são referência, não a
/// leitura principal — ficam atrás sem sumir.
const _alphaComparacao = 0.4;

/// Tracejado mais espaçado que o da série do carreador, pra as duas linhas
/// tracejadas do gráfico não se confundirem.
const _tracoComparacao = [8, 5];

/// Barra fina que diz o que está sobreposto e como tirar. Sem ela a segunda
/// curva vira um dado sem procedência na tela.
class _FaixaComparacao extends StatelessWidget {
  final String nome;
  final VoidCallback? onRemover;
  const _FaixaComparacao({required this.nome, this.onRemover});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        Espaco.campo,
        Espaco.xxs,
        Espaco.xxs,
        Espaco.xxs,
      ),
      decoration: BoxDecoration(
        color: cores.panel,
        border: Border.all(color: cores.line, width: Borda.fina),
        borderRadius: BorderRadius.circular(Raio.chip),
      ),
      child: Row(
        children: [
          Icon(Icons.compare_arrows, size: Icone.pp, color: cores.text2),
          const SizedBox(width: Espaco.xs),
          Expanded(
            child: Text(
              'Comparando com: $nome',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: Tipo.corpo,
                color: cores.text2,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remover comparação',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: Icone.p),
            onPressed: onRemover,
          ),
        ],
      ),
    );
  }
}

/// Faixa de identificação da coluna. Fina de propósito: quem manda na tela são
/// as curvas, e isto só nomeia o bloco. (Já teve um selo de severidade aqui;
/// saiu por repetir o KPI de baixo.)
class _Cabecalho extends StatelessWidget {
  const _Cabecalho();

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Row(
      children: [
        Icon(Icons.analytics_outlined, size: Icone.p, color: cores.accentForte),
        const SizedBox(width: Espaco.xs),
        Text(
          'Resultados',
          style: TextStyle(
            // Um degrau acima dos títulos dos cards abaixo, senão a coluna
            // ficaria com o rótulo do todo menor que o das partes.
            fontFamily: 'IBMPlexSans',
            fontSize: Tipo.tituloGrande,
            fontWeight: FontWeight.w600,
            color: cores.text,
          ),
        ),
      ],
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
          // `Wrap` e não `Row`: a coluna central estreita quando o painel flat
          // está na lateral, e aí a legenda desce pra segunda linha em vez de
          // estourar o cabeçalho.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Espaco.cartao,
            runSpacing: Espaco.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: Icone.p, color: cores.text2),
                  const SizedBox(width: Espaco.xs),
                  // `Flexible` por causa da coluna única do celular: lá o
                  // título sozinho já ocupa a linha inteira.
                  Flexible(
                    child: Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        // Mesmo degrau do título de card do accordion
                        // ("Adsorbato"): os dois nomeiam um bloco de conteúdo.
                        fontFamily: 'IBMPlexSans',
                        fontSize: Tipo.titulo,
                        fontWeight: FontWeight.w600,
                        color: cores.text,
                      ),
                    ),
                  ),
                ],
              ),
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

/// Curva do experimento comparado: mesma cor da série correspondente, mais
/// apagada e com o tracejado longo. A cor diz *o que é*, o tratamento diz
/// *de qual experimento é*.
LineChartBarData _serieComparada(List<FlSpot> pontos, Color cor) =>
    LineChartBarData(
      spots: pontos,
      isCurved: true,
      color: cor.withValues(alpha: _alphaComparacao),
      barWidth: 2,
      dashArray: _tracoComparacao,
      dotData: const FlDotData(show: false),
    );

/// Marca vertical de um tempo característico. Neutra e tracejada: é régua, não
/// série — se ganhasse cor de dado competiria com as curvas.
VerticalLine _marcaTempo(BuildContext context, double t, String rotulo) {
  final cores = context.cores;
  return VerticalLine(
    x: t,
    color: cores.text3,
    strokeWidth: Borda.fina,
    dashArray: const [2, 3],
    label: VerticalLineLabel(
      show: true,
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(bottom: Espaco.xxs),
      labelResolver: (_) => rotulo,
      style: TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: Tipo.eixo,
        color: cores.text3,
      ),
    ),
  );
}

/// Curva de ruptura: as duas frações molares no mesmo eixo.
class _GraficoRuptura extends StatelessWidget {
  final ResultadoBinario resultado;
  final ResultadoBinario? comparacao;
  const _GraficoRuptura({required this.resultado, this.comparacao});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final comp = comparacao;

    return _CartaoGrafico(
      icone: Icons.show_chart,
      titulo: 'Curva de ruptura',
      altura: Dim.alturaGraficoRuptura,
      legenda: Wrap(
        spacing: Espaco.cartao,
        runSpacing: Espaco.xxs,
        children: [
          _ChaveLegenda(cor: cores.data1, rotulo: 'y₁ forte'),
          _ChaveLegenda(
            cor: cores.data4,
            rotulo: 'y₀ carreador',
            tracejada: true,
          ),
          if (comp != null) ...[
            _ChaveLegenda(
              cor: cores.data1.withValues(alpha: _alphaComparacao),
              rotulo: 'y₁ (comp.)',
              tracejada: true,
            ),
            _ChaveLegenda(
              cor: cores.data4.withValues(alpha: _alphaComparacao),
              rotulo: 'y₀ (comp.)',
              tracejada: true,
            ),
          ],
        ],
      ),
      grafico: LineChart(
        duration: Duracao.lenta,
        curve: Curves.easeOutCubic,
        LineChartData(
          minY: 0,
          maxY: 1,
          // Com dois experimentos o eixo tem que caber o mais longo dos dois,
          // senão a curva comparada sai cortada.
          maxX: comp == null ? null : math.max(resultado.tF, comp.tF),
          gridData: _grade(context),
          titlesData: _eixos(context, 'tempo [s]', 'fração molar'),
          borderData: _moldura(context),
          // Ruptura e saturação marcadas no eixo: são dois dos KPIs de baixo,
          // e vê-los sobre a curva explica de onde saiu cada número.
          extraLinesData: ExtraLinesData(
            verticalLines: [
              _marcaTempo(context, resultado.tBreak, 'tb'),
              _marcaTempo(context, resultado.tSat, 'ts'),
            ],
          ),
          lineBarsData: [
            // As comparadas primeiro: ficam por baixo das do experimento atual.
            if (comp != null) ...[
              _serieComparada(_pontos(comp.tempos, comp.yForte), cores.data1),
              _serieComparada(
                _pontos(comp.tempos, comp.yCarreador),
                cores.data4,
              ),
            ],
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
  final ResultadoBinario? comparacao;
  const _GraficoTemperatura({required this.resultado, this.comparacao});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final comp = comparacao;
    // Quatro faixas na altura que este card tem. Sai dos dados e não de um
    // número fixo pra continuar valendo quando a rede devolver outra escala.
    // Com comparação, a faixa cobre as duas curvas — senão uma sai do quadro.
    final todas = [...resultado.tSaida, if (comp != null) ...comp.tSaida];
    final minT = todas.reduce(math.min);
    final maxT = todas.reduce(math.max);
    final intervalo = math.max((maxT - minT) / 4, 0.1);

    return _CartaoGrafico(
      icone: Icons.thermostat,
      titulo: 'Temperatura de saída',
      altura: Dim.alturaGraficoTemperatura,
      legenda: comp == null
          ? null
          : Wrap(
              spacing: Espaco.cartao,
              runSpacing: Espaco.xxs,
              children: [
                _ChaveLegenda(cor: cores.data3, rotulo: 'T saída'),
                _ChaveLegenda(
                  cor: cores.data3.withValues(alpha: _alphaComparacao),
                  rotulo: 'T saída (comp.)',
                  tracejada: true,
                ),
              ],
            ),
      grafico: LineChart(
        duration: Duracao.lenta,
        curve: Curves.easeOutCubic,
        LineChartData(
          maxX: comp == null ? null : math.max(resultado.tF, comp.tF),
          gridData: _grade(context, intervaloY: intervalo),
          titlesData: _eixos(
            context,
            'tempo [s]',
            'T [K]',
            intervaloY: intervalo,
          ),
          borderData: _moldura(context),
          lineBarsData: [
            if (comp != null)
              _serieComparada(_pontos(comp.tempos, comp.tSaida), cores.data3),
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
  final ResultadoBinario? comparacao;
  const _FaixaKpis({required this.resultado, this.comparacao});

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    final c = comparacao;
    final kpis = <Widget>[
      _CartaoKpi(
        rotulo: 't_break',
        valor: r.tBreak,
        comparado: c?.tBreak,
        unidade: 's',
      ),
      _CartaoKpi(
        rotulo: 't_sat',
        valor: r.tSat,
        comparado: c?.tSat,
        unidade: 's',
      ),
      _CartaoKpi(rotulo: 'T_F', valor: r.tF, comparado: c?.tF, unidade: 's'),
      _CartaoKpi(rotulo: 't_st', valor: r.tSt, comparado: c?.tSt, unidade: 's'),
      _CartaoKpi(
        rotulo: 'π_max',
        valor: r.piMax,
        comparado: c?.piMax,
        casas: 3,
      ),
      _CartaoKpi(
        rotulo: 'severidade',
        valor: r.severidade,
        comparado: c?.severidade,
        casas: 2,
        barra: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, restricoes) {
        // Três por linha, com o vão entre eles descontado da largura. Na
        // coluna única do celular não cabem três rótulos lado a lado sem
        // quebrar, e aí passam a ser dois.
        final porLinha = restricoes.maxWidth < Breakpoint.centroMinimo ? 2 : 3;
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

  /// Mesmo KPI no experimento comparado, ou `null` sem comparação. Entra numa
  /// segunda linha, apagado: o valor de cima continua sendo a leitura.
  final double? comparado;
  final String? unidade;
  final int casas;

  /// `true` troca o número solto por barra de 0 a 1 com o valor ao lado.
  final bool barra;

  const _CartaoKpi({
    required this.rotulo,
    required this.valor,
    this.comparado,
    this.unidade,
    this.casas = 1,
    this.barra = false,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final texto = valor.toStringAsFixed(casas);
    final comp = comparado;

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
          // Segunda linha, um degrau menor e apagada: dá pra comparar de
          // relance sem o valor comparado disputar com o atual.
          if (comp != null)
            Text(
              '${comp.toStringAsFixed(casas)}'
              '${unidade == null ? '' : ' $unidade'}  comp.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: Tipo.eixo,
                color: cores.text3,
              ),
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
