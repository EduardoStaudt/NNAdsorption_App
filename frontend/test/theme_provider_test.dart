// theme_provider_test.dart — padrão escuro e persistência da escolha de tema.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nnadsorption_app/providers/theme_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nasce no escuro', () {
    expect(ThemeProvider().modo, ThemeMode.dark);
    expect(ThemeProvider().modoEscuro, isTrue);
  });

  test('sem escolha salva, inicializar mantem o escuro', () async {
    final tema = ThemeProvider();
    await tema.inicializar();
    expect(tema.modo, ThemeMode.dark);
  });

  test('a escolha do usuario sobrevive a um reload', () async {
    final antes = ThemeProvider();
    await antes.alternar(); // vai pro claro
    expect(antes.modo, ThemeMode.light);

    final depois = ThemeProvider(); // simula o app abrindo de novo
    await depois.inicializar();
    expect(depois.modo, ThemeMode.light);
  });

  test('alternar duas vezes volta pro escuro e persiste assim', () async {
    final antes = ThemeProvider();
    // Sem await entre os dois: e o caso que corria risco de gravar fora de ordem
    antes.alternar();
    await antes.alternar();

    final depois = ThemeProvider();
    await depois.inicializar();
    expect(depois.modo, ThemeMode.dark);
  });

  test('notifica quem escuta ao alternar', () async {
    final tema = ThemeProvider();
    var avisos = 0;
    tema.addListener(() => avisos++);
    await tema.alternar();
    expect(avisos, 1);
  });
}
