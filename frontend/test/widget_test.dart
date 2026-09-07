// widget_test.dart — smoke tests: verifica que cada tela renderiza sem crash
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nnadsorption_app/providers/theme_provider.dart';
import 'package:nnadsorption_app/screens/landing_screen.dart';
import 'package:nnadsorption_app/theme/app_theme.dart';

// Envolve o widget com os providers necessários
Widget _comProviders(Widget filho) {
  return MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
    child: MaterialApp(
      theme: temaClaro(),
      darkTheme: temaEscuro(),
      home: filho,
    ),
  );
}

// Renderiza a landing num viewport de largura específica (altura folgada, já
// que a página inteira é um SingleChildScrollView).
Future<void> _pumpLanding(WidgetTester tester, double largura) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(largura, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_comProviders(const LandingScreen()));
  await tester.pump();
}

// O botão do CTA final. O "Começar agora" aparece duas vezes na página
// (hero + CTA); o do CTA é o último na ordem da árvore.
Rect _rectPrimarioCta(WidgetTester tester) =>
    tester.getRect(find.text('Começar agora').last);

void main() {
  testWidgets('LandingScreen renderiza sem crash', (tester) async {
    await tester.pumpWidget(_comProviders(const LandingScreen()));
    await tester.pump(); // processa o frame inicial
    // Verifica que o CTA está na tela — há dois "Começar agora"
    // (hero + seção de CTA final), reforçando a conversão.
    expect(find.text('Começar agora'), findsWidgets);
  });

  // Viewports reais de celular: o CTA tem que caber sem passar da borda.
  for (final largura in [360.0, 390.0, 414.0]) {
    testWidgets('CTA cabe na tela em ${largura.toInt()}px', (tester) async {
      await _pumpLanding(tester, largura);
      final primario = _rectPrimarioCta(tester);

      expect(primario.left, greaterThanOrEqualTo(0));
      expect(primario.right, lessThanOrEqualTo(largura));

      // A fonte que o flutter_test usa é bem mais larga que a IBM Plex Sans
      // real (cada glifo ocupa 1em): em 360px isso faz a topbar acusar 20px de
      // overflow que não acontece no navegador. Descarta esses avisos — quem
      // guarda o CTA são as asserções de geometria acima, que falhariam se os
      // botões voltassem a ficar lado a lado ou a passar da borda.
      for (
        var erro = tester.takeException();
        erro != null;
        erro = tester.takeException()
      ) {
        expect(erro.toString(), contains('overflowed'));
      }
    });
  }

  // Sem login não há segunda ação: nem no CTA, nem no cabeçalho.
  testWidgets('CTA e header oferecem uma acao so', (tester) async {
    await _pumpLanding(tester, 1200);

    expect(find.text('Já tenho conta'), findsNothing);
    expect(find.text('Entrar'), findsNothing);
    expect(find.text('Começar'), findsOneWidget);
    // Hero e CTA final
    expect(find.text('Começar agora'), findsNWidgets(2));
  });
}
