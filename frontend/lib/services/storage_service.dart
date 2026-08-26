// storage_service.dart — preferência de tema no localStorage (web).
// Histórico e presets moram em `armazenamento_local.dart`.
import 'package:shared_preferences/shared_preferences.dart';

const String _kTemaKey = 'tema_escuro';

Future<void> salvarTemaEscuro(bool escuro) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kTemaKey, escuro);
}

/// `null` = o usuário nunca escolheu; quem chama decide o padrão.
Future<bool?> lerTemaEscuro() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kTemaKey);
}
