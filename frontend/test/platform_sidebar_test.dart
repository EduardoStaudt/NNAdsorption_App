// platform_sidebar_test.dart — recolher/mostrar o painel de parâmetros no
// layout desktop. Sem token na sessão o histórico nem é buscado, então a tela
// monta sem rede.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nnadsorption_app/providers/auth_provider.dart';
import 'package:nnadsorption_app/providers/theme_provider.dart';
import 'package:nnadsorption_app/screens/platform_screen.dart';
import 'package:nnadsorption_app/theme/app_sizes.dart';
import 'package:nnadsorption_app/theme/app_theme.dart';
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

void main() {
  testWidgets('o painel de parametros comeca aberto no desktop', (
    tester,
  ) async {
    await _pumpDesktop(tester);

    expect(find.byType(ParametersPanel), findsOneWidget);
    expect(_larguraFaixa(tester), greaterThan(Dim.larguraPainelParametros));
  });

  testWidgets('o botao Parametros recolhe e volta a mostrar', (tester) async {
    await _pumpDesktop(tester);

    await tester.tap(find.text('Parametros'));
    await tester.pumpAndSettle();
    expect(_larguraFaixa(tester), 0);

    await tester.tap(find.text('Parametros'));
    await tester.pumpAndSettle();
    expect(_larguraFaixa(tester), greaterThan(Dim.larguraPainelParametros));
  });

  testWidgets('recolhido, o painel continua montado e guarda o estado dele', (
    tester,
  ) async {
    await _pumpDesktop(tester);

    // Fecha o card que vem aberto por padrao
    await tester.tap(find.byKey(const ValueKey('accordion-Adsorvente')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Parametros')); // recolhe
    await tester.pumpAndSettle();
    // Nao foi desmontado: os controladores e os accordions sobrevivem
    expect(find.byType(ParametersPanel), findsOneWidget);

    await tester.tap(find.text('Parametros')); // mostra de novo
    await tester.pumpAndSettle();

    final seta = tester.widget<AnimatedRotation>(
      find.descendant(
        of: find.byKey(const ValueKey('accordion-Adsorvente')),
        matching: find.byType(AnimatedRotation),
      ),
    );
    expect(seta.turns, 0); // continua fechado, como o usuario deixou
  });

  testWidgets('a seta do botao indica a direcao da acao', (tester) async {
    await _pumpDesktop(tester);

    // Só o botao usa chevron_left; os accordions usam chevron_right e seguem
    // montados quando recolhido, entao a ausencia do esquerdo é o sinal limpo.
    expect(find.byIcon(Icons.chevron_left), findsOneWidget); // aberto: recolhe

    await tester.tap(find.text('Parametros'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left), findsNothing); // fechado: mostra
  });
}
