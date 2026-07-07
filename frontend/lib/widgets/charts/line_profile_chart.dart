// line_profile_chart.dart — gráfico de linha genérico usado nas 4 curvas
// (concentração, adsorção, temperatura e breakthrough)
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';

class LineProfileChart extends StatelessWidget {
  final List<double> xs;
  final List<double> ys;
  final String eixoX; // ex.: "z (m)"
  final String eixoY; // ex.: "C (mol/m³)"
  final Color cor;
  final bool preenchido; // pinta a área abaixo da curva (breakthrough)
  final String Function(double x, double y) tooltip;

  const LineProfileChart({
    super.key,
    required this.xs,
    required this.ys,
    required this.eixoX,
    required this.eixoY,
    required this.cor,
    required this.tooltip,
    this.preenchido = false,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final estiloEixo = GoogleFonts.ibmPlexMono(fontSize: 10, color: cores.text3);
    final spots = List.generate(xs.length, (i) => FlSpot(xs[i], ys[i]));

    return LineChart(
      // Anima a transição quando os dados mudam (nova predição)
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      LineChartData(
        gridData: FlGridData(
          getDrawingHorizontalLine: (_) => FlLine(color: cores.line, strokeWidth: 0.5),
          getDrawingVerticalLine: (_) => FlLine(color: cores.line, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text(eixoY, style: estiloEixo),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              // Sem labels no min/max — evita números sobrepostos na borda
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (v, meta) =>
                  Text(meta.formattedValue, style: estiloEixo),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Text(eixoX, style: estiloEixo),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, meta) =>
                  Text(meta.formattedValue, style: estiloEixo),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: cores.line2)),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: cor,
            barWidth: preenchido ? 2.5 : 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: preenchido,
              color: cor.withValues(alpha: 0.12),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      tooltip(s.x, s.y),
                      GoogleFonts.ibmPlexMono(fontSize: 11, color: Colors.white),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
