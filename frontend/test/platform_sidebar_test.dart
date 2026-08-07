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

double _larguraPainel(WidgetTester tester) =>
    tester.getSize(find.byKey(const ValueKey('painel-lateral'))).width;

Finder _iconeDoTrilho(IconData icone) =>
    find.descendant(of: find.byType(RailLateral), matching: find.byIcon(icone));

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

Future<void> _tocar(WidgetTester tester, IconData icone) async {
  await tester.tap(_iconeDoTrilho(icone));
  await tester.pumpAndSettle();
}

/// Coloca o cursor sobre um ícone sem clicar.
Future<TestGesture> _passarMouse(WidgetTester tester, IconData icone) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await mouse.moveTo(tester.getCenter(_iconeDoTrilho(icone)));
  await tester.pumpAndSettle();
  return mouse;
}

void main() {
  testWidgets('o trilho tem o alternar mais um icone por painel', (
    tester,
  ) async {
    await _pumpDesktop(tester);

    expect(find.byType(RailLateral), findsOneWidget);
    expect(_iconeDoTrilho(Icons.menu_open), findsOneWidget); // comeca aberto
    expect(_iconeDoTrilho(Icons.tune), findsOneWidget);
    expect(_iconeDoTrilho(Icons.history), findsOneWidget);
    expect(_iconeDoTrilho(Icons.download), findsOneWidget);
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

      await _tocar(tester, Icons.menu_open);
      expect(_larguraPainel(tester), 0);

      await _tocar(tester, Icons.menu); // virou o icone de abrir
      expect(_larguraPainel(tester), Dim.larguraPainelParametros);
      // Reabriu o mesmo painel, nao voltou pro padrao
      expect(_corDoIcone(tester, Icons.tune), AppColors.escuro.accent);
    });

    testWidgets('reabre o ultimo painel escolhido, nao os parametros', (
      tester,
    ) async {
      await _pumpDesktop(tester);

      await _tocar(tester, Icons.history);
      await _tocar(tester, Icons.menu_open); // fecha
      await _tocar(tester, Icons.menu); // reabre

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

  testWidgets('os botoes soltos nao voltaram pro cabecalho', (tester) async {
    await _pumpDesktop(tester);

    expect(find.text('Historico'), findsNothing);
    expect(find.text('Exportar'), findsNothing);
  });
}
