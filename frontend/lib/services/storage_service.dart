// storage_service.dart — salva e lê o token JWT no localStorage (web)
import 'package:shared_preferences/shared_preferences.dart';

const String _kTokenKey = 'jwt_token';

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
