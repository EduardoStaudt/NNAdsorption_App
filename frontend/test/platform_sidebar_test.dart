// platform_sidebar_test.dart — barra fixa de ações e o painel de parâmetros
// recolhível no layout desktop. Sem token na sessão o histórico nem é buscado,
// então a tela monta sem rede.
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
import 'package:nnadsorption_app/widgets/barra_acoes.dart';
import 'package:nnadsorption_app/widgets/parameters_panel.dart';

double _larguraFaixa(WidgetTester tester) =>
    tester.getSize(find.byKey(const ValueKey('faixa-parametros'))).width;

/// Cor do ícone da barra — é assim que a barra diz o que está ativo.
Color _corDoIcone(WidgetTester tester, IconData icone) => tester
    .widget<Icon>(
      find.descendant(
        of: find.byType(BarraAcoes),
        matching: find.byIcon(icone),
      ),
    )
    .color!;

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

/// Clique direto no ícone: a barra não abre nem fecha nada antes.
Future<void> _tocarNaBarra(WidgetTester tester, IconData icone) async {
  await tester.tap(
    find.descendant(of: find.byType(BarraAcoes), matching: find.byIcon(icone)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a barra fica sempre na tela, com as tres acoes', (tester) async {
    await _pumpDesktop(tester);

    expect(find.byType(BarraAcoes), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BarraAcoes),
        matching: find.byIcon(Icons.tune),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(BarraAcoes),
        matching: find.byIcon(Icons.history),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(BarraAcoes),
        matching: find.byIcon(Icons.download),
      ),
      findsOneWidget,
    );
  });

  testWidgets('os tres botoes soltos sairam do cabecalho', (tester) async {
    await _pumpDesktop(tester);

    expect(find.text('Historico'), findsNothing);
    expect(find.text('Exportar'), findsNothing);
  });

  testWidgets('o painel de parametros comeca aberto no desktop', (
    tester,
  ) async {
    await _pumpDesktop(tester);

    expect(find.byType(ParametersPanel), findsOneWidget);
    expect(_larguraFaixa(tester), greaterThan(Dim.larguraPainelParametros));
  });

  testWidgets('o icone de parametros recolhe e volta a mostrar', (
    tester,
  ) async {
    await _pumpDesktop(tester);

    await _tocarNaBarra(tester, Icons.tune);
    expect(_larguraFaixa(tester), 0);

    await _tocarNaBarra(tester, Icons.tune);
    expect(_larguraFaixa(tester), greaterThan(Dim.larguraPainelParametros));
  });

  testWidgets(
    'o icone de parametros fica aceso enquanto o painel esta aberto',
    (tester) async {
      await _pumpDesktop(tester);

      expect(_corDoIcone(tester, Icons.tune), AppColors.escuro.accent);

      await _tocarNaBarra(tester, Icons.tune); // recolhe
      expect(_corDoIcone(tester, Icons.tune), AppColors.escuro.text2);
    },
  );

  testWidgets('exportar fica apagado sem predicao em tela', (tester) async {
    await _pumpDesktop(tester);

    expect(_corDoIcone(tester, Icons.download), AppColors.escuro.text3);
  });

  testWidgets('recolhido, o painel continua montado e guarda o estado dele', (
    tester,
  ) async {
    await _pumpDesktop(tester);

    // Fecha o card que vem aberto por padrao
    await tester.tap(find.byKey(const ValueKey('accordion-Adsorvente')));
    await tester.pumpAndSettle();

    await _tocarNaBarra(tester, Icons.tune); // recolhe
    // Nao foi desmontado: os controladores e os accordions sobrevivem
    expect(find.byType(ParametersPanel), findsOneWidget);

    await _tocarNaBarra(tester, Icons.tune); // mostra de novo

    final seta = tester.widget<AnimatedRotation>(
      find.descendant(
        of: find.byKey(const ValueKey('accordion-Adsorvente')),
        matching: find.byType(AnimatedRotation),
      ),
    );
    expect(seta.turns, 0); // continua fechado, como o usuario deixou
  });
}
