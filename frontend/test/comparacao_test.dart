// comparacao_test.dart — sobreposição de um experimento do histórico nos
// gráficos e nos KPIs.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nnadsorption_app/models/param_defs.dart';
import 'package:nnadsorption_app/models/resultado_binario.dart';
import 'package:nnadsorption_app/theme/app_theme.dart';
import 'package:nnadsorption_app/widgets/zona_resultados.dart';

/// Quantas séries cada gráfico desenhou, na ordem em que aparecem na tela
/// (ruptura primeiro, temperatura depois).
List<int> _series(WidgetTester tester) => tester
    .widgetList<LineChart>(find.byType(LineChart))
    .map((g) => g.data.lineBarsData.length)
    .toList();

Future<void> _pump(
  WidgetTester tester, {
  ResultadoBinario? comparacao,
  String? nome,
  VoidCallback? onRemover,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1000, 1600);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: temaEscuro(),
      home: Scaffold(
        body: ZonaResultados(
          resultado: ResultadoBinario.exemplo(),
          comparacao: comparacao,
          nomeComparacao: nome,
          onRemoverComparacao: onRemover,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Outro experimento: leito mais longo, então a frente sai bem depois.
ResultadoBinario _outro() {
  final p = Map<String, double>.from(valoresPadrao());
  p['L'] = 1.2;
  return ResultadoBinario.dosParametros(p);
}

void main() {
  group('sem comparação', () {
    testWidgets('cada grafico desenha so as series do experimento atual', (
      tester,
    ) async {
      await _pump(tester);
      expect(_series(tester), [2, 1]);
    });

    testWidgets('nao ha faixa de comparacao', (tester) async {
      await _pump(tester);
      expect(find.textContaining('Comparando com'), findsNothing);
    });
  });

  group('com comparação', () {
    testWidgets('ruptura ganha 2 series e temperatura ganha 1', (tester) async {
      await _pump(tester, comparacao: _outro(), nome: 'Coluna B');
      expect(_series(tester), [4, 2]);
    });

    testWidgets('a faixa nomeia o experimento sobreposto', (tester) async {
      await _pump(tester, comparacao: _outro(), nome: 'Coluna B');
      expect(find.text('Comparando com: Coluna B'), findsOneWidget);
    });

    testWidgets('o X da faixa devolve o controle pra tela', (tester) async {
      var removeu = 0;
      await _pump(
        tester,
        comparacao: _outro(),
        nome: 'Coluna B',
        onRemover: () => removeu++,
      );

      await tester.tap(find.byTooltip('Remover comparação'));
      await tester.pump();

      expect(removeu, 1);
    });

    testWidgets('o KPI mostra o valor comparado numa segunda linha', (
      tester,
    ) async {
      final outro = _outro();
      await _pump(tester, comparacao: outro, nome: 'Coluna B');

      final esperado = '${outro.tBreak.toStringAsFixed(1)} s  comp.';
      expect(find.text(esperado), findsOneWidget);
    });

    testWidgets('o eixo do tempo cobre o mais longo dos dois', (tester) async {
      final outro = _outro();
      await _pump(tester, comparacao: outro, nome: 'Coluna B');

      final ruptura = tester
          .widgetList<LineChart>(find.byType(LineChart))
          .first;
      expect(ruptura.data.maxX, outro.tF);
      // O leito de 1.2 m demora mais que o padrão de 0.5 m — é ele que manda
      expect(outro.tF, greaterThan(ResultadoBinario.exemplo().tF));
    });
  });

  test('as curvas respondem aos parâmetros', () {
    final curto = ResultadoBinario.exemplo();
    final longo = _outro();
    // Leito mais longo = frente sai mais tarde
    expect(longo.tBreak, greaterThan(curto.tBreak));
  });

  test('ida e volta pelo JSON preserva as curvas', () {
    final original = _outro();
    final volta = ResultadoBinario.deJson(original.paraJson());

    expect(volta.tBreak, original.tBreak);
    expect(volta.severidade, original.severidade);
    expect(volta.tempos, original.tempos);
    expect(volta.yForte, original.yForte);
    expect(volta.tSaida, original.tSaida);
  });
}
