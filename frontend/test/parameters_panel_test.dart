// parameters_panel_test.dart — estrutura dos cards, seleção única e feedback
// de erro do painel de parâmetros.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nnadsorption_app/models/param_defs.dart';
import 'package:nnadsorption_app/theme/app_theme.dart';
import 'package:nnadsorption_app/theme/colors.dart';
import 'package:nnadsorption_app/widgets/parameters_panel.dart';

Map<String, TextEditingController> _controladores() => {
  for (final e in textosPadrao().entries)
    e.key: TextEditingController(text: e.value),
};

Future<void> _pump(
  WidgetTester tester,
  Map<String, TextEditingController> ctrls, {
  TextEditingController? nome,
  VoidCallback? onRodar,
  VoidCallback? onCarregarPreset,
  VoidCallback? onSalvarPreset,
}) async {
  // Viewport alto o bastante pra o ListView construir os 3 cards: ele é lazy
  // e, com o Adsorbato aberto, os de baixo ficariam fora da tela.
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(380, 1600);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: temaEscuro(),
      home: Scaffold(
        body: ParametersPanel(
          controladores: ctrls,
          onResetar: () {},
          podeExportar: false,
          onExportar: (_) {},
          nome: nome ?? TextEditingController(),
          onRodar: onRodar ?? () {},
          onCarregarPreset: onCarregarPreset ?? () {},
          onSalvarPreset: onSalvarPreset ?? () {},
        ),
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
  testWidgets('tres cards de topo, com os componentes dentro do Adsorbato', (
    tester,
  ) async {
    await _pump(tester, _controladores());

    expect(find.text('Adsorbato'), findsOneWidget);
    expect(find.text('Isoterma'), findsOneWidget);
    expect(find.text('Operação e Geometria'), findsOneWidget);
    // Carreador e Gás Forte existem, mas como sub-secoes — nao como card
    expect(find.text('Carreador'), findsOneWidget);
    expect(find.text('Gás Forte'), findsOneWidget);
  });

  testWidgets('o Adsorbato soma os campos das duas sub-secoes', (tester) async {
    await _pump(tester, _controladores());

    expect(
      find.text('18 campos'),
      findsOneWidget,
    ); // 9 + 9 no cabecalho do card
    expect(find.text('9 campos'), findsNWidgets(2)); // uma por sub-secao
    expect(find.text('3 campos'), findsOneWidget); // Isoterma
    expect(find.text('10 campos'), findsOneWidget); // Operacao
  });

  group('selecao unica', () {
    testWidgets('abrir um card de topo fecha o que estava aberto', (
      tester,
    ) async {
      await _pump(tester, _controladores());

      expect(_aberto(tester, 'Adsorbato'), isTrue); // padrao
      expect(_aberto(tester, 'Isoterma'), isFalse);

      await _tocarCabecalho(tester, 'Isoterma');

      expect(_aberto(tester, 'Isoterma'), isTrue);
      expect(_aberto(tester, 'Adsorbato'), isFalse);
      expect(_aberto(tester, 'Operação e Geometria'), isFalse);
    });

    testWidgets('tocar no card ja aberto fecha ele', (tester) async {
      await _pump(tester, _controladores());

      await _tocarCabecalho(tester, 'Adsorbato');
      expect(_aberto(tester, 'Adsorbato'), isFalse);
    });

    testWidgets('dentro do Adsorbato so uma sub-secao fica aberta', (
      tester,
    ) async {
      await _pump(tester, _controladores());

      expect(_aberto(tester, 'Carreador'), isTrue); // padrao
      expect(_aberto(tester, 'Gás Forte'), isFalse);

      await _tocarCabecalho(tester, 'Gás Forte');

      expect(_aberto(tester, 'Gás Forte'), isTrue);
      expect(_aberto(tester, 'Carreador'), isFalse);
    });

    testWidgets('a sub-secao aberta sobrevive a fechar e reabrir o Adsorbato', (
      tester,
    ) async {
      await _pump(tester, _controladores());

      await _tocarCabecalho(tester, 'Gás Forte');
      await _tocarCabecalho(tester, 'Adsorbato'); // fecha o card
      await _tocarCabecalho(tester, 'Adsorbato'); // reabre

      expect(_aberto(tester, 'Gás Forte'), isTrue);
      expect(_aberto(tester, 'Carreador'), isFalse);
    });
  });

  group('aberto acende em ambar', () {
    // A caixa mais proxima acima de um cabecalho. O AnimatedContainer do hover
    // fica abaixo da chave, entao nao entra aqui.
    AnimatedContainer caixaDe(WidgetTester tester, String titulo) =>
        tester.widget<AnimatedContainer>(
          find
              .ancestor(
                of: find.byKey(ValueKey('accordion-$titulo')),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );

    Color? bordaDe(WidgetTester tester, String titulo) =>
        (caixaDe(tester, titulo).decoration as BoxDecoration?)
            ?.border
            ?.top
            .color;

    // Sub-secao: o proprio nome, porque ela nao tem caixa nenhuma.
    Color? corDoNome(WidgetTester tester, String titulo) {
      final estilo = tester.widget<AnimatedDefaultTextStyle>(
        find.descendant(
          of: find.byKey(ValueKey('accordion-$titulo')),
          matching: find.byType(AnimatedDefaultTextStyle),
        ),
      );
      return estilo.style.color;
    }

    testWidgets('card de topo: pela borda em volta', (tester) async {
      await _pump(tester, _controladores());

      // Adsorbato comeca aberto; fechado fica no fio neutro, nunca em ambar
      expect(bordaDe(tester, 'Adsorbato'), AppColors.escuro.accent);
      expect(bordaDe(tester, 'Isoterma'), AppColors.escuro.line);

      await _tocarCabecalho(tester, 'Isoterma');

      expect(bordaDe(tester, 'Isoterma'), AppColors.escuro.accent);
      expect(bordaDe(tester, 'Adsorbato'), AppColors.escuro.line);
    });

    testWidgets('sub-secao: pelo nome, igual pros dois componentes', (
      tester,
    ) async {
      await _pump(tester, _controladores());

      // Carreador comeca aberto, Gas Forte fechado
      expect(corDoNome(tester, 'Carreador'), AppColors.escuro.accentForte);
      expect(corDoNome(tester, 'Gás Forte'), AppColors.escuro.text2);

      await _tocarCabecalho(tester, 'Gás Forte');

      expect(corDoNome(tester, 'Gás Forte'), AppColors.escuro.accentForte);
      expect(corDoNome(tester, 'Carreador'), AppColors.escuro.text2);
    });

    testWidgets('sub-secao nao ganha caixa: era ela que cortava o campo', (
      tester,
    ) async {
      await _pump(tester, _controladores());

      // Aberta e tudo, a caixa mais proxima acima do Carreador e *a mesma* do
      // card que o contem. Se a sub-secao tivesse caixa propria, seria outra.
      expect(caixaDe(tester, 'Carreador'), same(caixaDe(tester, 'Adsorbato')));
    });
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

      ctrls['eps']!.text = '5'; // 'eps' vive em Isoterma, que comeca fechado
      await tester.pump();

      expect(find.text('1 com erro'), findsOneWidget);
      expect(find.text('3 campos'), findsNothing);
    });

    testWidgets('erro no Carreador sobe pro cabecalho do Adsorbato', (
      tester,
    ) async {
      final ctrls = _controladores();
      await _pump(tester, ctrls);

      // Abre o Gás Forte: o Carreador fecha e o erro dele ficaria escondido
      await _tocarCabecalho(tester, 'Gás Forte');
      ctrls['qm_ref_1']!.text = '99';
      await tester.pump();

      // Aparece nos dois niveis: na sub-secao fechada e no card que a contem
      expect(find.text('1 com erro'), findsNWidgets(2));
      expect(find.text('18 campos'), findsNothing);
      expect(find.text('9 campos'), findsOneWidget); // so o Gás Forte, sem erro
    });

    testWidgets('erros das duas sub-secoes somam no Adsorbato', (tester) async {
      final ctrls = _controladores();
      await _pump(tester, ctrls);

      ctrls['qm_ref_1']!.text = '99';
      ctrls['qm_ref_2']!.text = '99';
      await tester.pump();

      expect(find.text('2 com erro'), findsOneWidget); // o card do Adsorbato
      expect(find.text('1 com erro'), findsNWidgets(2)); // uma por sub-secao
    });
  });

  testWidgets('o nome do experimento fica no pe, junto das acoes', (
    tester,
  ) async {
    final nome = TextEditingController();
    addTearDown(nome.dispose);
    await _pump(tester, _controladores(), nome: nome);

    // Desceu pro rodapé: é o nome que "Salvar preset" grava
    final campo = find.widgetWithText(TextField, 'Nome do experimento');
    expect(campo, findsOneWidget);
    expect(
      tester.getCenter(campo).dy,
      greaterThan(tester.getCenter(find.text('Adsorbato')).dy),
    );
    expect(
      tester.getCenter(campo).dy,
      lessThan(tester.getCenter(find.text('Rodar modelo')).dy),
    );

    await tester.enterText(campo, 'Coluna piloto A');
    expect(nome.text, 'Coluna piloto A');
  });

  testWidgets('o pe tem rodar, os dois presets e o resetar', (tester) async {
    var rodou = 0;
    var carregou = 0;
    var salvou = 0;
    await _pump(
      tester,
      _controladores(),
      onRodar: () => rodou++,
      onCarregarPreset: () => carregou++,
      onSalvarPreset: () => salvou++,
    );

    for (final rotulo in [
      'Rodar modelo',
      'Carregar preset',
      'Salvar preset',
      'Resetar valores',
    ]) {
      expect(find.text(rotulo), findsOneWidget, reason: rotulo);
    }

    await tester.tap(find.text('Rodar modelo'));
    await tester.tap(find.text('Carregar preset'));
    await tester.tap(find.text('Salvar preset'));
    await tester.pump();

    expect([rodou, carregou, salvou], [1, 1, 1]);
  });

  testWidgets('o pe diz que a rede roda no proprio navegador', (tester) async {
    await _pump(tester, _controladores());

    expect(find.textContaining('roda neste navegador'), findsOneWidget);
    expect(find.textContaining('nada é enviado'), findsOneWidget);
  });
}
