// platform_sidebar_test.dart — recolher/mostrar o painel de parâmetros no
// layout desktop, agora pelo menu lateral. Sem token na sessão o histórico nem
// é buscado, então a tela monta sem rede.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nnadsorption_app/providers/auth_provider.dart';
import 'package:nnadsorption_app/providers/theme_provider.dart';
import 'package:nnadsorption_app/screens/platform_screen.dart';
import 'package:nnadsorption_app/theme/app_sizes.dart';
import 'package:nnadsorption_app/theme/app_theme.dart';
import 'package:nnadsorption_app/widgets/menu_acoes_drawer.dart';
import 'package:nnadsorption_app/widgets/parameters_panel.dart';

double _larguraFaixa(WidgetTester tester) =>
    tester.getSize(find.byKey(const ValueKey('faixa-parametros'))).width;

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

/// Abre o menu lateral pelo hambúrguer.
Future<void> _abrirMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

/// Caminho completo do usuário: hambúrguer, item, menu fecha e a ação roda.
Future<void> _acionar(WidgetTester tester, String item) async {
  await _abrirMenu(tester);
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('o cabecalho dos resultados fica so com o hamburguer', (
    tester,
  ) async {
    await _pumpDesktop(tester);

    expect(find.byIcon(Icons.menu), findsOneWidget);
    // Os tres botoes soltos sairam da tela
    expect(find.text('Historico'), findsNothing);
    expect(find.text('Exportar'), findsNothing);
  });

  testWidgets('o menu lateral traz as tres acoes', (tester) async {
    await _pumpDesktop(tester);
    await _abrirMenu(tester);

    expect(find.byType(MenuAcoesDrawer), findsOneWidget);
    expect(find.text('Parametros'), findsOneWidget);
    expect(find.text('Historico'), findsOneWidget);
    expect(find.text('Exportar'), findsOneWidget);
  });

  testWidgets('o painel de parametros comeca aberto no desktop', (
    tester,
  ) async {
    await _pumpDesktop(tester);

    expect(find.byType(ParametersPanel), findsOneWidget);
    expect(_larguraFaixa(tester), greaterThan(Dim.larguraPainelParametros));
  });

  testWidgets('o item Parametros recolhe e volta a mostrar', (tester) async {
    await _pumpDesktop(tester);

    await _acionar(tester, 'Parametros');
    expect(_larguraFaixa(tester), 0);

    await _acionar(tester, 'Parametros');
    expect(_larguraFaixa(tester), greaterThan(Dim.larguraPainelParametros));
  });

  testWidgets('a dica do item acompanha o estado do painel', (tester) async {
    await _pumpDesktop(tester);

    await _abrirMenu(tester);
    expect(find.text('Recolher o painel'), findsOneWidget);
    await tester.tap(find.text('Parametros'));
    await tester.pumpAndSettle();

    await _abrirMenu(tester);
    expect(find.text('Mostrar o painel'), findsOneWidget);
  });

  testWidgets('Exportar fica inerte sem predicao em tela', (tester) async {
    await _pumpDesktop(tester);
    await _abrirMenu(tester);

    expect(
      find.text('Abra uma predicao no historico primeiro'),
      findsOneWidget,
    );
    // Inerte: tocar nao revela CSV/XLSX nem fecha o menu. O AnimatedCrossFade
    // mantem os dois filhos montados, entao quem diz a verdade e o estado dele,
    // nao um find.text('CSV') — que acharia o filho invisivel.
    await tester.tap(find.text('Exportar'));
    await tester.pumpAndSettle();

    final formatos = tester.widget<AnimatedCrossFade>(
      find.descendant(
        of: find.byType(MenuAcoesDrawer),
        matching: find.byType(AnimatedCrossFade),
      ),
    );
    expect(formatos.crossFadeState, CrossFadeState.showFirst);
    expect(find.byType(MenuAcoesDrawer), findsOneWidget);
  });

  testWidgets('recolhido, o painel continua montado e guarda o estado dele', (
    tester,
  ) async {
    await _pumpDesktop(tester);

    // Fecha o card que vem aberto por padrao
    await tester.tap(find.byKey(const ValueKey('accordion-Adsorvente')));
    await tester.pumpAndSettle();

    await _acionar(tester, 'Parametros'); // recolhe
    // Nao foi desmontado: os controladores e os accordions sobrevivem
    expect(find.byType(ParametersPanel), findsOneWidget);

    await _acionar(tester, 'Parametros'); // mostra de novo

    final seta = tester.widget<AnimatedRotation>(
      find.descendant(
        of: find.byKey(const ValueKey('accordion-Adsorvente')),
        matching: find.byType(AnimatedRotation),
      ),
    );
    expect(seta.turns, 0); // continua fechado, como o usuario deixou
  });
}
