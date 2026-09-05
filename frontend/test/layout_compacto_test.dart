// layout_compacto_test.dart — abaixo de 800px a tela mostra a mesma zona de
// resultados do layout largo, em coluna única. O que muda é o que fica em
// volta: sem trilho, com os parâmetros num bottom sheet.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nnadsorption_app/providers/theme_provider.dart';
import 'package:nnadsorption_app/screens/platform_screen.dart';
import 'package:nnadsorption_app/theme/app_theme.dart';
import 'package:nnadsorption_app/widgets/parameters_panel.dart';
import 'package:nnadsorption_app/widgets/rail_lateral.dart';
import 'package:nnadsorption_app/widgets/zona_resultados.dart';

/// Viewport de celular: abaixo de `Breakpoint.tablet`.
Future<void> _pumpCompacto(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: MaterialApp(theme: temaEscuro(), home: const PlatformScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('mostra a zona de resultados, sem trilho', (tester) async {
    await _pumpCompacto(tester);

    // A mesma zona do layout largo: são os KPIs do preditor local, não o
    // painel do /predict antigo.
    expect(find.byType(ZonaResultados), findsOneWidget);
    expect(find.text('t_break'), findsOneWidget);
    expect(find.text('severidade'), findsOneWidget);
    // O trilho pede uma faixa fixa que esta largura não tem
    expect(find.byType(RailLateral), findsNothing);
  });

  testWidgets('os KPIs vao a dois por linha', (tester) async {
    await _pumpCompacto(tester);

    final tBreak = tester.getRect(find.text('t_break'));
    final tSat = tester.getRect(find.text('t_sat'));
    final tF = tester.getRect(find.text('T_F'));

    // Os dois primeiros dividem a linha...
    expect(tSat.top, closeTo(tBreak.top, 0.5));
    // ...e o terceiro já desceu, em vez de espremer três numa linha só
    expect(tF.top, greaterThan(tBreak.bottom));
  });

  testWidgets('os parametros abrem em folha por cima', (tester) async {
    await _pumpCompacto(tester);

    expect(find.byType(ParametersPanel), findsNothing);
    // Num celular a ação é só o ícone; o rótulo vive no tooltip.
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.byType(ParametersPanel), findsOneWidget);
  });
}
