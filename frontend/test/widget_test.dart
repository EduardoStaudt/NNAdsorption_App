// widget_test.dart — smoke tests: verifica que cada tela renderiza sem crash
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nnadsorption_app/providers/auth_provider.dart';
import 'package:nnadsorption_app/providers/theme_provider.dart';
import 'package:nnadsorption_app/screens/landing_screen.dart';
import 'package:nnadsorption_app/screens/login_screen.dart';
import 'package:nnadsorption_app/screens/register_screen.dart';
import 'package:nnadsorption_app/theme/app_theme.dart';

// Envolve o widget com os providers necessários
Widget _comProviders(Widget filho) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ],
    child: MaterialApp(
      theme: temaClaro(),
      darkTheme: temaEscuro(),
      home: filho,
    ),
  );
}

void main() {
  testWidgets('LandingScreen renderiza sem crash', (tester) async {
    await tester.pumpWidget(_comProviders(const LandingScreen()));
    await tester.pump(); // processa o frame inicial
    // Verifica que o botão CTA está na tela
    expect(find.text('Começar agora'), findsOneWidget);
  });

  testWidgets('LoginScreen renderiza sem crash', (tester) async {
    await tester.pumpWidget(_comProviders(const LoginScreen()));
    await tester.pump();
    expect(find.text('Entrar'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2)); // email + senha
  });

  testWidgets('RegisterScreen renderiza sem crash', (tester) async {
    await tester.pumpWidget(_comProviders(const RegisterScreen()));
    await tester.pump();
    expect(find.text('Criar conta'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(3)); // email + senha + confirma
  });
}
