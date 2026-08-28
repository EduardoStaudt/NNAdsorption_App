// api_service.dart — todas as chamadas HTTP ao backend FastAPI.
//
// A API é aberta e sem estado: não há token pra mandar nem histórico pra
// buscar. Quem guarda o que foi rodado é `armazenamento_local.dart`.
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import '../config.dart';

/// UTF-8 → JSON numa passada só, sem a String intermediária.
final _jsonDosBytes = const Utf8Decoder().fuse(const JsonDecoder());

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

  // --- Lote ---

  /// Sobe a planilha e roda o lote inteiro numa passada só da rede.
  ///
  /// `saida` são os campos do form que dizem o que voltar:
  /// `escalares` (bool), `curvas` (bool) e `colunas` (escalares por vírgula).
  Future<Map<String, dynamic>> predictBatchFile(
    Uint8List bytes,
    String nomeArquivo,
    Map<String, dynamic> saida,
  ) async {
    final pedido = http.MultipartRequest(
      'POST',
      Uri.parse('$kBackendUrl/predict_batch_file'),
    );
    pedido.files.add(
      http.MultipartFile.fromBytes('arquivo', bytes, filename: nomeArquivo),
    );
    saida.forEach((chave, valor) {
      if (valor != null) pedido.fields[chave] = valor.toString();
    });

    final resp = await http.Response.fromStream(await pedido.send());
    _checarErro(resp);
    // Direto dos bytes: com curvas a resposta passa de 3 MB, e `resp.body`
    // ainda montaria a String inteira só pra o jsonDecode relê-la.
    return _jsonDosBytes.convert(resp.bodyBytes) as Map<String, dynamic>;
  }

  /// Planilha modelo com o cabeçalho das 31 colunas e linhas de exemplo.
  Future<Uint8List> baixarTemplate(String formato) async {
    final resp = await http.get(
      Uri.parse('$kBackendUrl/template_batch?formato=$formato'),
    );
    _checarErro(resp);
    return resp.bodyBytes;
  }

  /// Devolve o resultado do lote ao backend e recebe a planilha de volta.
  /// A API não guarda nada — quem tem o resultado é quem o pediu.
  Future<Uint8List> exportarBatch(
    Map<String, dynamic> resultado,
    String formato,
  ) async {
    final resp = await http.post(
      Uri.parse('$kBackendUrl/export_batch?formato=$formato'),
      headers: _cabecalhoJson,
      body: jsonEncode(resultado),
    );
    _checarErro(resp);
    return resp.bodyBytes;
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
