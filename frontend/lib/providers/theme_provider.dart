// theme_provider.dart — controla o tema claro/escuro via Provider
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Inicia em modo claro
  ThemeMode _modo = ThemeMode.light;

  ThemeMode get modo => _modo;

  bool get modoEscuro => _modo == ThemeMode.dark;

  void alternar() {
    _modo = modoEscuro ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
