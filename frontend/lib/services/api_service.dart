// api_service.dart — todas as chamadas HTTP ao backend FastAPI.
//
// A API é aberta e sem estado: não há token pra mandar nem histórico pra
// buscar. Quem guarda o que foi rodado é `armazenamento_local.dart`.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  static const _cabecalhoJson = {'Content-Type': 'application/json'};

  // --- Meta ---

  Future<Map<String, dynamic>> getMeta() async {
    final resp = await http.get(Uri.parse('$kBackendUrl/meta'));
    _checarErro(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // --- Predict ---

  /// Devolve o resultado cru da rede. Cru de propósito: é assim que ele vai
  /// pro histórico local, e é assim que a exportação precisa dele de volta.
  Future<Map<String, dynamic>> predict(Map<String, double> inputs) async {
    final resp = await http.post(
      Uri.parse('$kBackendUrl/predict'),
      headers: _cabecalhoJson,
      body: jsonEncode({'inputs': inputs}),
    );
    _checarErro(resp);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['result'] as Map<String, dynamic>;
  }

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
