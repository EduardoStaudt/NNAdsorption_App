// parameters_panel_test.dart — o painel dos 28 campos e o feedback de erro.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nnadsorption_app/models/param_defs.dart';
import 'package:nnadsorption_app/theme/app_theme.dart';
import 'package:nnadsorption_app/widgets/parameters_panel.dart';

Map<String, TextEditingController> _controladores() => {
      for (final e in valoresPadrao().entries)
        e.key: TextEditingController(text: e.value.toString()),
    };

Future<void> _pump(
  WidgetTester tester,
  Map<String, TextEditingController> ctrls,
) async {
  // Viewport alto o bastante pra o ListView construir os 4 grupos: ele é lazy
  // e, com o grupo 1 aberto, os de baixo ficariam fora da tela.
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(380, 1600);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: temaEscuro(),
      home: Scaffold(
        body: ParametersPanel(controladores: ctrls, onResetar: () {}),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('mostra um grupo por componente mais recheio e operacao',
      (tester) async {
    await _pump(tester, _controladores());

    expect(find.text('Comp 1 · Carregador'), findsOneWidget);
    expect(find.text('Comp 2 · Forte'), findsOneWidget);
    expect(find.text('Recheio'), findsOneWidget);
    expect(find.text('Operacao e Geometria'), findsOneWidget);
  });

  testWidgets('nao chama predicao: o botao Rodar esta desligado',
      (tester) async {
    await _pump(tester, _controladores());

    expect(find.text('Rodar predicao'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    // O play do botao ativo nao existe mais nesta tela
    expect(find.byIcon(Icons.play_arrow), findsNothing);
  });

  testWidgets('valores padrao entram sem nenhum erro', (tester) async {
    await _pump(tester, _controladores());

    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.textContaining('com erro'), findsNothing);
  });

  testWidgets('valor fora do intervalo mostra a faixa valida no campo',
      (tester) async {
    final ctrls = _controladores();
    await _pump(tester, ctrls);

    // qm_ref_1 aceita 1..15 e esta no grupo aberto por padrao
    ctrls['qm_ref_1']!.text = '99';
    await tester.pump();

    expect(find.text('Fora do intervalo (1 a 15)'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('erro em grupo fechado aparece na contagem do cabecalho',
      (tester) async {
    final ctrls = _controladores();
    await _pump(tester, ctrls);

    // 'eps' vive em Recheio, que comeca fechado
    expect(find.text('3 campos'), findsOneWidget);

    ctrls['eps']!.text = '5';
    await tester.pump();

    // Com o grupo fechado a mensagem inline fica invisivel (o AnimatedCrossFade
    // mantem o filho na arvore com opacidade 0), entao a contagem no cabecalho
    // eh o unico aviso que o usuario ve.
    expect(find.text('1 com erro'), findsOneWidget);
    expect(find.text('3 campos'), findsNothing);
  });

  testWidgets('campo vazio pede um valor', (tester) async {
    final ctrls = _controladores();
    await _pump(tester, ctrls);

    ctrls['qm_ref_1']!.text = '';
    await tester.pump();

    expect(find.text('Informe um valor'), findsOneWidget);
  });
}
