// armazenamento_local.dart — histórico e presets no navegador.
//
// Não existe mais conta nem banco: o que a pessoa roda fica na máquina dela,
// no localStorage (via `shared_preferences`, que na web é exatamente isso).
// Some ao limpar os dados do site, e não acompanha quem trocar de navegador —
// é o preço de não ter login, e para uma ferramenta de pesquisa é barato.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Uma predição guardada: os parâmetros que entraram e o resultado que saiu.
/// `resultado` é o mapa cru que a API devolve — guardar como veio deixa o
/// `PredictionResult.fromJson` continuar valendo sem tradução no meio.
class EntradaHistorico {
  /// Milissegundos da criação. Serve de identidade porque duas predições não
  /// nascem no mesmo milissegundo, e já vem ordenável de graça.
  final int id;
  final String nome;
  final DateTime criadoEm;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> resultado;

  /// As curvas do jeito que a tela binária desenha (`ResultadoBinario`). É um
  /// campo à parte porque hoje ela ainda não sai de `resultado` — a API devolve
  /// o formato do modelo antigo. Quando os dois formatos convergirem, este
  /// campo some e a tela lê de `resultado`.
  final Map<String, dynamic> binario;

  const EntradaHistorico({
    required this.id,
    required this.nome,
    required this.criadoEm,
    required this.inputs,
    required this.resultado,
    required this.binario,
  });

  Map<String, dynamic> paraJson() => {
    'id': id,
    'nome': nome,
    'criado_em': criadoEm.toIso8601String(),
    'inputs': inputs,
    'resultado': resultado,
    'binario': binario,
  };

  factory EntradaHistorico.deJson(Map<String, dynamic> json) =>
      EntradaHistorico(
        id: json['id'] as int,
        nome: json['nome'] as String,
        criadoEm: DateTime.parse(json['criado_em'] as String),
        inputs: Map<String, dynamic>.from(json['inputs'] as Map),
        resultado: Map<String, dynamic>.from(json['resultado'] as Map),
        binario: Map<String, dynamic>.from(
          (json['binario'] ?? const {}) as Map,
        ),
      );
}

/// Histórico de predições do navegador.
class HistoricoLocal {
  static const _chave = 'historico_predicoes';

  /// Teto de entradas guardadas. O localStorage tem uns 5 MB por site e cada
  /// predição carrega as curvas inteiras; sem limite, um dia de uso encheria a
  /// cota e a gravação passaria a falhar em silêncio.
  static const maximo = 50;

  Future<List<EntradaHistorico>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getStringList(_chave) ?? [];
    return [
      for (final linha in bruto)
        EntradaHistorico.deJson(jsonDecode(linha) as Map<String, dynamic>),
    ];
  }

  /// Grava no topo da lista e devolve a entrada criada.
  Future<EntradaHistorico> salvar({
    required String nome,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> resultado,
    Map<String, dynamic> binario = const {},
  }) async {
    final agora = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getStringList(_chave) ?? [];

    // Dois salvamentos no mesmo milissegundo cairiam no mesmo id, e aí apagar
    // um apagaria os dois. O topo da lista é sempre o id mais alto, então
    // basta passar dele.
    var id = agora.millisecondsSinceEpoch;
    if (bruto.isNotEmpty) {
      final ultimo = (jsonDecode(bruto.first) as Map<String, dynamic>)['id'];
      if (ultimo is int && id <= ultimo) id = ultimo + 1;
    }

    final entrada = EntradaHistorico(
      id: id,
      nome: nome,
      criadoEm: agora,
      inputs: inputs,
      resultado: resultado,
      binario: binario,
    );

    bruto.insert(0, jsonEncode(entrada.paraJson()));
    if (bruto.length > maximo) bruto.removeRange(maximo, bruto.length);
    await prefs.setStringList(_chave, bruto);
    return entrada;
  }

  Future<void> apagar(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getStringList(_chave) ?? [];
    bruto.removeWhere(
      (linha) => (jsonDecode(linha) as Map<String, dynamic>)['id'] == id,
    );
    await prefs.setStringList(_chave, bruto);
  }

  Future<void> renomear(int id, String nome) async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getStringList(_chave) ?? [];
    for (var i = 0; i < bruto.length; i++) {
      final json = jsonDecode(bruto[i]) as Map<String, dynamic>;
      if (json['id'] != id) continue;
      json['nome'] = nome;
      bruto[i] = jsonEncode(json);
      break;
    }
    await prefs.setStringList(_chave, bruto);
  }

  Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }
}

/// Presets: um jogo de valores dos parâmetros, salvo por nome.
class PresetsLocal {
  static const _chave = 'presets_parametros';

  /// Nome → valores dos campos, no mesmo formato de texto que os controladores
  /// da tela usam. Guardar como texto evita que "1e-5" volte como "0.00001".
  Future<Map<String, Map<String, String>>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(_chave);
    if (bruto == null) return {};
    final json = jsonDecode(bruto) as Map<String, dynamic>;
    return {
      for (final e in json.entries)
        e.key: Map<String, String>.from(e.value as Map),
    };
  }

  Future<void> salvar(String nome, Map<String, String> valores) async {
    final prefs = await SharedPreferences.getInstance();
    final todos = await listar();
    todos[nome] = valores;
    await prefs.setString(_chave, jsonEncode(todos));
  }

  Future<void> apagar(String nome) async {
    final prefs = await SharedPreferences.getInstance();
    final todos = await listar();
    todos.remove(nome);
    await prefs.setString(_chave, jsonEncode(todos));
  }
}
