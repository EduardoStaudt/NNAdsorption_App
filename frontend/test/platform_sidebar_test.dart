// platform_sidebar_test.dart — trilho lateral do desktop: seleção de painel,
// fechar clicando no ícone ativo, o botão de alternar e a prévia do hover.
// O histórico vem do localStorage (mockado aqui), então a tela monta sem rede.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
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

/// Coloca o cursor sobre um ícone sem clicar.
Future<TestGesture> _passarMouse(WidgetTester tester, IconData icone) async {
  final cursor = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await cursor.addPointer(location: Offset.zero);
  addTearDown(cursor.removePointer);
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
      expect(find.text('Histórico'), findsOneWidget);

      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(find.byType(PeekPainel), findsNothing);
    });

    testWidgets('nao aparece no icone do painel que ja esta aberto', (
      tester,
    ) async {
      await _pumpDesktop(tester);
      await _tocar(tester, Icons.history); // agora o historico esta aberto

      // Nao se espia o que ja esta a vista
      await _passarMouse(tester, Icons.history);
      expect(find.byType(PeekPainel), findsNothing);
    });

    testWidgets('o icone de parametros nao mostra nada no hover', (
      tester,
    ) async {
      await _pumpDesktop(tester);
      await _tocar(tester, Icons.tune); // fecha: se houvesse previa, seria aqui

      await _passarMouse(tester, Icons.tune);
      expect(find.byType(PeekPainel), findsNothing);
      // Nem o tooltip do Material — o hover so acende o icone
      expect(
        find.ancestor(
          of: _iconeDoTrilho(Icons.tune),
          matching: find.byType(Tooltip),
        ),
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
    await tester.tap(find.byKey(const ValueKey('accordion-Adsorbato')));
    await tester.pumpAndSettle();

    await _tocar(tester, Icons.tune); // fecha o painel
    expect(find.byType(ParametersPanel), findsOneWidget); // nao desmontou

    await _tocar(tester, Icons.tune); // abre de novo

    final seta = tester.widget<AnimatedRotation>(
      find.descendant(
        of: find.byKey(const ValueKey('accordion-Adsorbato')),
        matching: find.byType(AnimatedRotation),
      ),
    );
    expect(seta.turns, 0); // continua fechado, como o usuario deixou
  });

  testWidgets('o cabecalho dos resultados nao tem mais botoes soltos', (
    tester,
  ) async {
    await _pumpDesktop(tester);

    expect(find.text('Histórico'), findsNothing);
    // Exportar existe, mas no rodape do painel de parametros — nao no trilho
    expect(_iconeDoTrilho(Icons.download), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ParametersPanel),
        matching: find.text('Exportar'),
      ),
      findsOneWidget,
    );
  });
}
