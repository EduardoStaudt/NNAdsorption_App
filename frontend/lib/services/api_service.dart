// api_service.dart — todas as chamadas HTTP ao backend FastAPI
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/prediction.dart';
import '../models/user.dart';

// Resposta genérica de login/register (token + user)
class AuthResponse {
  final String token;
  final User user;
  AuthResponse({required this.token, required this.user});
}

class ApiService {
  // Monta o cabeçalho com o token JWT
  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // --- Auth ---

  Future<AuthResponse> register(String email, String password) async {
    final resp = await http.post(
      Uri.parse('$kBackendUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    _checarErro(resp);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return AuthResponse(
      token: data['token'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<AuthResponse> login(String email, String password) async {
    final resp = await http.post(
      Uri.parse('$kBackendUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    _checarErro(resp);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return AuthResponse(
      token: data['token'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<User> getMe(String token) async {
    final resp = await http.get(
      Uri.parse('$kBackendUrl/auth/me'),
      headers: _headers(token),
    );
    _checarErro(resp);
    return User.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  // --- Meta ---

  Future<Map<String, dynamic>> getMeta() async {
    final resp = await http.get(Uri.parse('$kBackendUrl/meta'));
    _checarErro(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // --- Predict ---

  Future<({int predictionId, PredictionResult result})> predict(
    String token,
    Map<String, double> inputs,
  ) async {
    final resp = await http.post(
      Uri.parse('$kBackendUrl/predict'),
      headers: _headers(token),
      body: jsonEncode({'inputs': inputs}),
    );
    _checarErro(resp);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return (
      predictionId: data['prediction_id'] as int,
      result: PredictionResult.fromJson(data['result'] as Map<String, dynamic>),
    );
  }

  // --- History ---

  Future<List<PredictionSummary>> getHistory(String token) async {
    final resp = await http.get(
      Uri.parse('$kBackendUrl/history'),
      headers: _headers(token),
    );
    _checarErro(resp);
    final lista = jsonDecode(resp.body) as List;
    return lista
        .map((e) => PredictionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getPrediction(String token, int id) async {
    final resp = await http.get(
      Uri.parse('$kBackendUrl/history/$id'),
      headers: _headers(token),
    );
    _checarErro(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<void> deletePrediction(String token, int id) async {
    final resp = await http.delete(
      Uri.parse('$kBackendUrl/history/$id'),
      headers: _headers(token),
    );
    _checarErro(resp);
  }

  String exportUrl(int predictionId, String format) =>
      '$kBackendUrl/predict/$predictionId/export?format=$format';

  // Lança exceção com a mensagem de erro do backend
  void _checarErro(http.Response resp) {
    if (resp.statusCode >= 400) {
      String mensagem = 'Erro ${resp.statusCode}';
      try {
        final body = jsonDecode(resp.body);
        if (body is Map && body['detail'] != null) {
          mensagem = body['detail'].toString();
        }
      } catch (_) {}
      throw Exception(mensagem);
    }
  }
}
