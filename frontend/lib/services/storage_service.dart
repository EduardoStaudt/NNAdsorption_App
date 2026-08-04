// storage_service.dart — guarda no localStorage (web) o que precisa sobreviver
// a um reload: o token JWT e a preferência de tema.
import 'package:shared_preferences/shared_preferences.dart';

const String _kTokenKey = 'jwt_token';
const String _kTemaKey = 'tema_escuro';

Future<void> salvarToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kTokenKey, token);
}

Future<String?> lerToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kTokenKey);
}

Future<void> removerToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kTokenKey);
}

Future<void> salvarTemaEscuro(bool escuro) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kTemaKey, escuro);
}

/// `null` = o usuário nunca escolheu; quem chama decide o padrão.
Future<bool?> lerTemaEscuro() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kTemaKey);
}
