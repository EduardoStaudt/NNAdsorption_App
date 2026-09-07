// comparar_historico_test.dart — o modal só inicia a comparação; a troca de
// experimento comparado acontece na lista do trilho, que abre junto.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nnadsorption_app/models/param_defs.dart';
import 'package:nnadsorption_app/models/resultado_binario.dart';
import 'package:nnadsorption_app/providers/theme_provider.dart';
import 'package:nnadsorption_app/screens/platform_screen.dart';
import 'package:nnadsorption_app/theme/app_theme.dart';

/// Entrada do histórico como o navegador a guarda. `L` diferente em cada uma
/// pra as curvas não saírem idênticas.
String _entrada(int id, String nome, double comprimento) {
  final p = Map<String, double>.from(valoresPadrao());
  p['L'] = comprimento;
  return jsonEncode({
    'id': id,
    'nome': nome,
    'criado_em': DateTime.fromMillisecondsSinceEpoch(id).toIso8601String(),
    'inputs': p,
    'resultado': const <String, dynamic>{},
    'binario': ResultadoBinario.dosParametros(p).paraJson(),
  });
}

/// A dica que a lista mostra só quando ela virou seletor de comparação. Como o
/// painel fechado fica offstage, achá-la já diz que o histórico está aberto.
final _dica = find.text('Clique num experimento pra trocar a comparação.');

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'flutter.historico_predicoes': [
      _entrada(1, 'leito curto', 0.4),
      _entrada(2, 'leito longo', 1.2),
    ],
  });
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1400, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: MaterialApp(theme: temaEscuro(), home: const PlatformScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Abre o modal e escolhe um experimento — o caminho da primeira comparação.
Future<void> _compararCom(WidgetTester tester, String nome) async {
  await tester.tap(find.text('Comparar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(nome).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('escolher no modal abre o historico no trilho', (tester) async {
    await _pump(tester);
    expect(_dica, findsNothing);

    await _compararCom(tester, 'leito longo');

    expect(find.text('Comparando com: leito longo'), findsOneWidget);
    // O painel aberto é o do histórico, já em modo de troca
    expect(_dica, findsOneWidget);
  });

  testWidgets('com comparacao ativa, clicar na lista troca o comparado', (
    tester,
  ) async {
    await _pump(tester);
    await _compararCom(tester, 'leito longo');

    await tester.tap(find.text('leito curto'));
    await tester.pumpAndSettle();

    expect(find.text('Comparando com: leito curto'), findsOneWidget);
    expect(find.text('Comparando com: leito longo'), findsNothing);
  });

  testWidgets('sem comparacao, clicar na lista carrega a predicao', (
    tester,
  ) async {
    await _pump(tester);
    // Abre o histórico pelo trilho, sem passar por comparação nenhuma
    await tester.tap(find.byIcon(Icons.history).first);
    await tester.pumpAndSettle();
    expect(_dica, findsNothing);

    await tester.tap(find.text('leito longo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Comparando com'), findsNothing);
    // Carregar traz o nome do experimento pro campo do painel de parâmetros,
    // que está atrás do histórico no mesmo trilho.
    await tester.tap(find.byIcon(Icons.tune).first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'leito longo'), findsOneWidget);
  });
}
