// auth_provider.dart — estado de autenticação do usuário
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _carregando = false;

  User? get user => _user;
  String? get token => _token;
  bool get logado => _token != null && _user != null;
  bool get carregando => _carregando;

  final ApiService _api = ApiService();

  // Tenta restaurar a sessão salva no localStorage
  Future<void> inicializar() async {
    final token = await lerToken();
    if (token == null) return;
    try {
      final user = await _api.getMe(token);
      _token = token;
      _user = user;
      notifyListeners();
    } catch (_) {
      // Token expirado ou inválido — limpa
      await removerToken();
    }
  }

  Future<void> registrar(String email, String password) async {
    _carregando = true;
    notifyListeners();
    try {
      final resp = await _api.register(email, password);
      await salvarToken(resp.token);
      _token = resp.token;
      _user = resp.user;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> entrar(String email, String password) async {
    _carregando = true;
    notifyListeners();
    try {
      final resp = await _api.login(email, password);
      await salvarToken(resp.token);
      _token = resp.token;
      _user = resp.user;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> sair() async {
    await removerToken();
    _token = null;
    _user = null;
    notifyListeners();
  }
}
