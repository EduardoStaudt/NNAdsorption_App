// parameters_panel_test.dart — estrutura dos cards, seleção única e feedback
// de erro do painel de parâmetros.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nnadsorption_app/models/param_defs.dart';
import 'package:nnadsorption_app/theme/app_theme.dart';
import 'package:nnadsorption_app/widgets/parameters_panel.dart';

Map<String, TextEditingController> _controladores() => {
  for (final e in textosPadrao().entries)
    e.key: TextEditingController(text: e.value),
};

Future<void> _pump(
  WidgetTester tester,
  Map<String, TextEditingController> ctrls,
) async {
  // Viewport alto o bastante pra o ListView construir os 3 cards: ele é lazy
  // e, com o Adsorvente aberto, os de baixo ficariam fora da tela.
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

/// Lê "aberto" pela seta do cabeçalho — `AnimatedRotation.turns` guarda o
/// destino, então vale já no primeiro frame. A `key` está no cabeçalho, que é
/// irmão do corpo: a busca nunca alcança a seta de uma sub-seção.
/// (O widget também expõe `expanded` no Semantics, pro leitor de tela; ler isso
/// aqui exigiria um SemanticsHandle por teste, que é setup a mais sem ganho.)
bool _aberto(WidgetTester tester, String titulo) {
  final seta = tester.widget<AnimatedRotation>(
    find.descendant(
      of: find.byKey(ValueKey('accordion-$titulo')),
      matching: find.byType(AnimatedRotation),
    ),
  );
  return seta.turns != 0;
}

Future<void> _tocarCabecalho(WidgetTester tester, String titulo) async {
  await tester.tap(find.byKey(ValueKey('accordion-$titulo')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tres cards de topo, com os componentes dentro do Adsorvente', (
    tester,
  ) async {
    await _pump(tester, _controladores());

    expect(find.text('Adsorvente'), findsOneWidget);
    expect(find.text('Recheio'), findsOneWidget);
    expect(find.text('Operacao e Geometria'), findsOneWidget);
    // Carregador e Gás Forte existem, mas como sub-secoes — nao como card
    expect(find.text('Carregador'), findsOneWidget);
    expect(find.text('Gás Forte'), findsOneWidget);
  });

  testWidgets('o Adsorvente soma os campos das duas sub-secoes', (
    tester,
  ) async {
    await _pump(tester, _controladores());

    expect(
      find.text('16 campos'),
      findsOneWidget,
    ); // 8 + 8 no cabecalho do card
    expect(find.text('8 campos'), findsNWidgets(2)); // uma por sub-secao
    expect(find.text('3 campos'), findsOneWidget); // Recheio
    expect(find.text('9 campos'), findsOneWidget); // Operacao
  });

  group('selecao unica', () {
    testWidgets('abrir um card de topo fecha o que estava aberto', (
      tester,
    ) async {
      await _pump(tester, _controladores());

      expect(_aberto(tester, 'Adsorvente'), isTrue); // padrao
      expect(_aberto(tester, 'Recheio'), isFalse);

      await _tocarCabecalho(tester, 'Recheio');

      expect(_aberto(tester, 'Recheio'), isTrue);
      expect(_aberto(tester, 'Adsorvente'), isFalse);
      expect(_aberto(tester, 'Operacao e Geometria'), isFalse);
    });

    testWidgets('tocar no card ja aberto fecha ele', (tester) async {
      await _pump(tester, _controladores());

      await _tocarCabecalho(tester, 'Adsorvente');
      expect(_aberto(tester, 'Adsorvente'), isFalse);
    });

    testWidgets('dentro do Adsorvente so uma sub-secao fica aberta', (
      tester,
    ) async {
      await _pump(tester, _controladores());

      expect(_aberto(tester, 'Carregador'), isTrue); // padrao
      expect(_aberto(tester, 'Gás Forte'), isFalse);

      await _tocarCabecalho(tester, 'Gás Forte');

      expect(_aberto(tester, 'Gás Forte'), isTrue);
      expect(_aberto(tester, 'Carregador'), isFalse);
    });

    testWidgets(
      'a sub-secao aberta sobrevive a fechar e reabrir o Adsorvente',
      (tester) async {
        await _pump(tester, _controladores());

        await _tocarCabecalho(tester, 'Gás Forte');
        await _tocarCabecalho(tester, 'Adsorvente'); // fecha o card
        await _tocarCabecalho(tester, 'Adsorvente'); // reabre

        expect(_aberto(tester, 'Gás Forte'), isTrue);
        expect(_aberto(tester, 'Carregador'), isFalse);
      },
    );
  });

  group('erro', () {
    testWidgets('valores padrao entram sem nenhum erro', (tester) async {
      await _pump(tester, _controladores());

      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.textContaining('com erro'), findsNothing);
    });

    testWidgets('fora do intervalo mostra a faixa valida no campo', (
      tester,
    ) async {
      final ctrls = _controladores();
      await _pump(tester, ctrls);

      ctrls['qm_ref_1']!.text = '99'; // aceita 1..15
      await tester.pump();

      expect(find.text('Fora do intervalo (1 a 15)'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('campo vazio pede um valor', (tester) async {
      final ctrls = _controladores();
      await _pump(tester, ctrls);

      ctrls['qm_ref_1']!.text = '';
      await tester.pump();

      expect(find.text('Informe um valor'), findsOneWidget);
    });

    testWidgets('erro em card de topo fechado aparece na contagem', (
      tester,
    ) async {
      final ctrls = _controladores();
      await _pump(tester, ctrls);

      ctrls['eps']!.text = '5'; // 'eps' vive em Recheio, que comeca fechado
      await tester.pump();

      expect(find.text('1 com erro'), findsOneWidget);
      expect(find.text('3 campos'), findsNothing);
    });

    testWidgets('erro no Carregador sobe pro cabecalho do Adsorvente', (
      tester,
    ) async {
      final ctrls = _controladores();
      await _pump(tester, ctrls);

      // Abre o Gás Forte: o Carregador fecha e o erro dele ficaria escondido
      await _tocarCabecalho(tester, 'Gás Forte');
      ctrls['qm_ref_1']!.text = '99';
      await tester.pump();

      // Aparece nos dois niveis: na sub-secao fechada e no card que a contem
      expect(find.text('1 com erro'), findsNWidgets(2));
      expect(find.text('16 campos'), findsNothing);
      expect(find.text('8 campos'), findsOneWidget); // so o Gás Forte, sem erro
    });

    testWidgets('erros das duas sub-secoes somam no Adsorvente', (
      tester,
    ) async {
      final ctrls = _controladores();
      await _pump(tester, ctrls);

      ctrls['qm_ref_1']!.text = '99';
      ctrls['qm_ref_2']!.text = '99';
      await tester.pump();

      expect(find.text('2 com erro'), findsOneWidget); // o card do Adsorvente
      expect(find.text('1 com erro'), findsNWidgets(2)); // uma por sub-secao
    });
  });

  testWidgets('nao chama predicao: o botao Rodar esta desligado', (
    tester,
  ) async {
    await _pump(tester, _controladores());

    expect(find.text('Rodar predicao'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
  });
}
