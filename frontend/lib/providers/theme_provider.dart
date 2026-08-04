// theme_provider.dart — controla o tema claro/escuro via Provider
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  // Escuro por padrão: o sistema nasceu de um mockup dark e o splash do
  // index.html é escuro — abrir no claro daria um flash na primeira pintura.
  ThemeMode _modo = ThemeMode.dark;

  ThemeMode get modo => _modo;

  bool get modoEscuro => _modo == ThemeMode.dark;

  /// Restaura a escolha salva. Sem escolha registrada, fica no escuro.
  Future<void> inicializar() async {
    final escuro = await lerTemaEscuro();
    if (escuro == null) return;
    _modo = escuro ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Gravações em fila. Sem isso, dois toques rápidos disparam dois `setBool`
  /// concorrentes e nada garante a ordem de chegada — dá pra ficar salvo o
  /// penúltimo tema.
  Future<void> _fila = Future.value();

  /// Troca na hora e grava depois. O Future devolvido completa quando a escolha
  /// está salva: a UI ignora, os testes esperam.
  Future<void> alternar() {
    _modo = modoEscuro ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    final escuro = modoEscuro;
    _fila = _fila.then((_) => salvarTemaEscuro(escuro));
    return _fila;
  }
}
