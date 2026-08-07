// platform_sidebar_test.dart — trilho lateral do desktop: seleção de painel,
// fechar clicando no ícone ativo, o botão de alternar e a prévia do hover.
// Sem token na sessão o histórico nem é buscado, então a tela monta sem rede.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nnadsorption_app/providers/auth_provider.dart';
import 'package:nnadsorption_app/providers/theme_provider.dart';
import 'package:nnadsorption_app/screens/platform_screen.dart';
import 'package:nnadsorption_app/theme/app_sizes.dart';
import 'package:nnadsorption_app/theme/app_theme.dart';
import 'package:nnadsorption_app/theme/colors.dart';
import 'package:nnadsorption_app/widgets/parameters_panel.dart';
import 'package:nnadsorption_app/widgets/rail_lateral.dart';
import 'package:nnadsorption_app/widgets/ui_comum.dart';

double _larguraPainel(WidgetTester tester) =>
    tester.getSize(find.byKey(const ValueKey('painel-lateral'))).width;

Finder _iconeDoTrilho(IconData icone) =>
    find.descendant(of: find.byType(RailLateral), matching: find.byIcon(icone));

/// Botão de alternar o painel — mora no cabeçalho, não no trilho.
final _alternar = find.byKey(const ValueKey('alternar-painel'));

/// O ícone do alternar preenche a coluna esquerda quando o painel está aberto.
bool _alternarMostraAberto(WidgetTester tester) => tester
    .widget<IconePainelEsquerdo>(
      find.descendant(
        of: _alternar,
        matching: find.byType(IconePainelEsquerdo),
      ),
    )
    .aberto;

/// Cor do ícone — é assim que o trilho diz qual painel está selecionado.
Color _corDoIcone(WidgetTester tester, IconData icone) =>
    tester.widget<Icon>(_iconeDoTrilho(icone)).color!;

Future<void> _pumpDesktop(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(
    1400,
    900,
  ); // acima de Breakpoint.desktop
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(theme: temaEscuro(), home: const PlatformScreen()),
    ),
  );
  await tester.pump();
}

Future<void> _tocarAlternar(WidgetTester tester) async {
  await tester.tap(_alternar);
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, IconData icone) async {
  await tester.tap(_iconeDoTrilho(icone));
  await tester.pumpAndSettle();
}

/// Coloca o cursor sobre um ícone sem clicar. Passe o mouse devolvido pra
/// visitar outro ícone: registrar um ponteiro novo sem remover o anterior faz
/// o `MouseTracker` do framework abortar.
Future<TestGesture> _passarMouse(
  WidgetTester tester,
  IconData icone, [
  TestGesture? mouse,
]) async {
  final cursor =
      mouse ?? await tester.createGesture(kind: PointerDeviceKind.mouse);
  if (mouse == null) {
    await cursor.addPointer(location: Offset.zero);
    addTearDown(cursor.removePointer);
  }
  await cursor.moveTo(tester.getCenter(_iconeDoTrilho(icone)));
  await tester.pumpAndSettle();
  return cursor;
}

void main() {
  testWidgets('o trilho tem um icone por painel; o alternar fica na topbar', (
    tester,
  ) async {
    await _pumpDesktop(tester);

    expect(find.byType(RailLateral), findsOneWidget);
    expect(_iconeDoTrilho(Icons.tune), findsOneWidget);
    expect(_iconeDoTrilho(Icons.history), findsOneWidget);
    expect(_iconeDoTrilho(Icons.download), findsOneWidget);

    // O alternar saiu do trilho: vive no cabecalho, antes da marca
    expect(_alternar, findsOneWidget);
    expect(
      find.descendant(of: find.byType(RailLateral), matching: _alternar),
      findsNothing,
    );
    expect(
      find.descendant(of: find.byType(AppBar), matching: _alternar),
      findsOneWidget,
    );
    // Mesmo eixo X dos icones do trilho logo abaixo
    expect(
      tester.getCenter(_alternar).dx,
      closeTo(tester.getCenter(_iconeDoTrilho(Icons.tune)).dx, 0.5),
    );
  });

  testWidgets('abre nos parametros', (tester) async {
    await _pumpDesktop(tester);

    expect(_larguraPainel(tester), Dim.larguraPainelParametros);
    expect(_corDoIcone(tester, Icons.tune), AppColors.escuro.accent);
  });

  testWidgets('clicar no icone ja ativo fecha o painel', (tester) async {
    await _pumpDesktop(tester);

    await _tocar(tester, Icons.tune);
    expect(_larguraPainel(tester), 0);
    expect(_corDoIcone(tester, Icons.tune), AppColors.escuro.text2);

    await _tocar(tester, Icons.tune);
    expect(_larguraPainel(tester), Dim.larguraPainelParametros);
  });

  testWidgets('trocar de icone troca o painel sem fechar', (tester) async {
    await _pumpDesktop(tester);

    await _tocar(tester, Icons.history);
    expect(_larguraPainel(tester), Dim.larguraPainelParametros);
    expect(_corDoIcone(tester, Icons.history), AppColors.escuro.accent);
    expect(_corDoIcone(tester, Icons.tune), AppColors.escuro.text2);
  });

  group('botao de alternar', () {
    testWidgets('fecha o painel aberto e reabre o mesmo', (tester) async {
      await _pumpDesktop(tester);
      expect(_alternarMostraAberto(tester), isTrue);

      await _tocarAlternar(tester);
      expect(_larguraPainel(tester), 0);
      // O proprio icone conta o estado: a coluna esquerda esvazia
      expect(_alternarMostraAberto(tester), isFalse);

      await _tocarAlternar(tester);
      expect(_larguraPainel(tester), Dim.larguraPainelParametros);
      expect(_alternarMostraAberto(tester), isTrue);
      // Reabriu o mesmo painel, nao voltou pro padrao
      expect(_corDoIcone(tester, Icons.tune), AppColors.escuro.accent);
    });

    testWidgets('reabre o ultimo painel escolhido, nao os parametros', (
      tester,
    ) async {
      await _pumpDesktop(tester);

      await _tocar(tester, Icons.history);
      await _tocarAlternar(tester); // fecha
      await _tocarAlternar(tester); // reabre

      expect(_corDoIcone(tester, Icons.history), AppColors.escuro.accent);
      expect(_corDoIcone(tester, Icons.tune), AppColors.escuro.text2);
    });
  });

  group('previa do hover', () {
    testWidgets('aparece sobre um painel fechado e some ao sair', (
      tester,
    ) async {
      await _pumpDesktop(tester);

      final mouse = await _passarMouse(tester, Icons.history);
      expect(find.byType(PeekPainel), findsOneWidget);
      expect(find.text('Historico'), findsOneWidget);

      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(find.byType(PeekPainel), findsNothing);
    });

    testWidgets('nao aparece no icone do painel que ja esta aberto', (
      tester,
    ) async {
      await _pumpDesktop(tester);

      // Parametros esta aberto: nao ha o que espiar
      await _passarMouse(tester, Icons.tune);
      expect(find.byType(PeekPainel), findsNothing);
    });

    testWidgets('as tres previas tem exatamente o mesmo tamanho', (
      tester,
    ) async {
      await _pumpDesktop(tester);
      await _tocar(tester, Icons.tune); // fecha tudo pra poder espiar as 3

      final tamanhos = <IconData, Size>{};
      TestGesture? mouse;
      for (final icone in [Icons.tune, Icons.history, Icons.download]) {
        mouse = await _passarMouse(tester, icone, mouse);
        tamanhos[icone] = tester.getSize(find.byType(PeekPainel));
      }

      expect(tamanhos[Icons.tune], tamanhos[Icons.history]);
      expect(tamanhos[Icons.tune], tamanhos[Icons.download]);
    });

    testWidgets('a previa de parametros mostra o conteudo real, sem editar', (
      tester,
    ) async {
      await _pumpDesktop(tester);
      await _tocar(tester, Icons.tune); // fecha, senao nao ha o que espiar
      await _passarMouse(tester, Icons.tune);

      final previa = find.byType(PeekPainel);
      // Os cards de verdade, com a contagem de campos de verdade
      expect(
        find.descendant(of: previa, matching: find.text('Adsorvente')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: previa, matching: find.text('16')),
        findsOneWidget,
      );
      // E os primeiros campos, com simbolo e valor atual
      expect(
        find.descendant(of: previa, matching: find.text('qm,ref')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: previa, matching: find.text('8')),
        findsWidgets,
      );
      // Prévia, nao editor: nenhum campo de texto dentro dela
      expect(
        find.descendant(of: previa, matching: find.byType(TextFormField)),
        findsNothing,
      );
    });

    testWidgets('some quando o painel espiado passa a ser aberto', (
      tester,
    ) async {
      await _pumpDesktop(tester);

      await _passarMouse(tester, Icons.history);
      expect(find.byType(PeekPainel), findsOneWidget);

      await tester.tap(_iconeDoTrilho(Icons.history));
      await tester.pumpAndSettle();
      expect(find.byType(PeekPainel), findsNothing);
    });
  });

  testWidgets('fechado, o painel continua montado e guarda o estado dele', (
    tester,
  ) async {
    await _pumpDesktop(tester);

    // Fecha o card que vem aberto por padrao
    await tester.tap(find.byKey(const ValueKey('accordion-Adsorvente')));
    await tester.pumpAndSettle();

    await _tocar(tester, Icons.tune); // fecha o painel
    expect(find.byType(ParametersPanel), findsOneWidget); // nao desmontou

    await _tocar(tester, Icons.tune); // abre de novo

    final seta = tester.widget<AnimatedRotation>(
      find.descendant(
        of: find.byKey(const ValueKey('accordion-Adsorvente')),
        matching: find.byType(AnimatedRotation),
      ),
    );
    expect(seta.turns, 0); // continua fechado, como o usuario deixou
  });

  group('exportar no rodape', () {
    testWidgets('fica separado, abaixo dos dois de cima', (tester) async {
      await _pumpDesktop(tester);

      final tune = tester.getCenter(_iconeDoTrilho(Icons.tune)).dy;
      final historico = tester.getCenter(_iconeDoTrilho(Icons.history)).dy;
      final exportar = tester.getCenter(_iconeDoTrilho(Icons.download)).dy;

      // Os dois de cima ficam juntos; o exportar cai bem longe, no rodape
      expect(historico - tune, lessThan(Dim.itemRail * 2));
      expect(exportar - historico, greaterThan(Dim.itemRail * 3));
    });

    testWidgets('fica inerte sem predicao, mas a previa explica', (
      tester,
    ) async {
      await _pumpDesktop(tester);

      // Sem predicao em tela: clicar nao abre o painel
      await _tocar(tester, Icons.download);
      expect(_corDoIcone(tester, Icons.download), AppColors.escuro.text3);
      expect(_larguraPainel(tester), Dim.larguraPainelParametros);

      // O hover ainda mostra a previa, que diz o porque
      await _passarMouse(tester, Icons.download);
      expect(
        find.text('Abra uma predicao no historico primeiro'),
        findsOneWidget,
      );
    });
  });

  testWidgets('os botoes soltos nao voltaram pro cabecalho', (tester) async {
    await _pumpDesktop(tester);

    expect(find.text('Historico'), findsNothing);
    expect(find.text('Exportar'), findsNothing);
  });
}
