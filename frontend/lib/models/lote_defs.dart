// lote_defs.dart — colunas e prévia local da predição em lote.
//
// Espelha `nnadsorption/contract.py`: a ordem e os nomes das 31 colunas são os
// que a rede espera. Quem manda é o contrato da lib — se ele mudar, muda aqui
// junto, e o backend devolve 422 dizendo qual coluna sumiu.
//
// ATENÇÃO às unidades: aqui é o SI do contrato, não o da tela de predição
// única. `dH` em J/mol (a tela usa kJ/mol), `P` em Pa (a tela usa MPa) e `dp`
// em m (a tela usa mm). O lote é arquivo entra / arquivo sai e não passa pelos
// campos da tela, então nada converte no caminho.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'param_defs.dart' show kNumComponentes;

/// Os 9 parâmetros de isoterma e cinética que existem por componente.
/// Mesmos campos de `kPerComponentFields`, com a grafia do contrato.
const List<String> kParamsPorComponente = [
  'qm_ref',
  'k2',
  'B_ref',
  'k4',
  'n_ref',
  'k6',
  'kL',
  'dH',
  'Cpg',
];

/// Leito e adsorvente (3) + operação e geometria (9) + alimentação (1).
const List<String> kParamsFixos = [
  'eb', 'rho_b', 'Cps', // leito e adsorvente
  'vs', 'Tin', 'P', 'L', 'Dt', 'hw', 'lam', 'dp', 'Dm', // operação e geometria
  'y0', // alimentação (y1 = 1 − y0)
];

/// As 31 colunas obrigatórias, na ordem exata do vetor X. O número de
/// componentes é o mesmo da tela (`kNumComponentes`): subir um sem o outro
/// deixaria a prévia exigindo colunas que o resto do app não gera mais.
final List<String> kColunasLote = [
  for (var c = 0; c < kNumComponentes; c++)
    for (final p in kParamsPorComponente) 'c${c}_$p',
  ...kParamsFixos,
];

/// Escalares que a rede devolve por experimento: chave do backend + rótulo.
/// A ordem é a de `lote.COLUNAS_ESCALARES` no backend.
const List<(String chave, String rotulo)> kEscalaresLote = [
  ('tbreak', 't_break'),
  ('tsat', 't_sat'),
  ('TF', 'TF'),
  ('tst', 't_st'),
  ('pi_max', 'πmax'),
  ('severidade', 'severidade'),
];

/// O que o arquivo escolhido tem dentro, lido no navegador antes de subir.
class PreviaLote {
  final List<String> colunas;

  /// Primeiras linhas de dados, pra mostrar numa tabelinha.
  final List<List<String>> amostra;

  /// Total de linhas de dados (sem o cabeçalho).
  final int totalLinhas;

  /// Colunas do contrato que não apareceram no cabeçalho.
  final List<String> faltando;

  const PreviaLote({
    required this.colunas,
    required this.amostra,
    required this.totalLinhas,
    required this.faltando,
  });

  bool get valida => faltando.isEmpty && totalLinhas > 0;
}

/// Quantas linhas da amostra mostrar na prévia.
const int kLinhasPrevia = 4;

/// Quanto do arquivo é decodificado pra ler cabeçalho e amostra. O resto só é
/// contado byte a byte: um CSV de 5000 linhas vira uma String de ~3 MB, e
/// jogá-la fora inteira depois de olhar 5 linhas trava a interface à toa.
const int _bytesDeAmostra = 64 * 1024;

/// Lê o cabeçalho e as primeiras linhas de um CSV.
///
/// Só CSV: `.xlsx` é um zip e abrir isso no navegador exigiria uma dependência
/// só pra prévia. O arquivo sobe do mesmo jeito e o backend valida as colunas
/// ao rodar — a prévia é conveniência, não é o portão.
PreviaLote? lerPreviaCsv(Uint8List bytes, {int amostra = kLinhasPrevia}) {
  final inicio = utf8.decode(
    bytes.sublist(0, math.min(bytes.length, _bytesDeAmostra)),
    allowMalformed: true,
  );
  final linhas = _linhasNaoVazias(inicio);
  if (linhas.isEmpty) return null;

  final colunas = _celulas(linhas.first).map((c) => c.trim()).toList();
  final presentes = colunas.toSet();

  return PreviaLote(
    colunas: colunas,
    amostra: [
      for (final linha in linhas.skip(1).take(amostra)) _celulas(linha),
    ],
    totalLinhas: _contarLinhasDeDados(bytes),
    faltando: [
      for (final obrigatoria in kColunasLote)
        if (!presentes.contains(obrigatoria)) obrigatoria,
    ],
  );
}

/// Conta as linhas com conteúdo sem montar String nenhuma, e desconta o
/// cabeçalho. Linha só de espaço ou de quebra não conta — mesmo critério do
/// `_linhasNaoVazias`, que o `\n` sobrando no fim do arquivo já pedia.
int _contarLinhasDeDados(Uint8List bytes) {
  const quebra = 0x0A; // '\n'
  var total = 0;
  var temConteudo = false;

  for (final b in bytes) {
    if (b == quebra) {
      if (temConteudo) total++;
      temConteudo = false;
    } else if (b > 0x20) {
      // acima do espaço = caractere de verdade (pula \r, \t e o espaço)
      temConteudo = true;
    }
  }
  if (temConteudo) total++;

  return math.max(0, total - 1); // tira o cabeçalho
}

List<String> _linhasNaoVazias(String texto) => texto
    .split(RegExp(r'\r\n|\r|\n'))
    .where((linha) => linha.trim().isNotEmpty)
    .toList();

/// Divide uma linha de CSV em células, respeitando aspas duplas.
/// Simples de propósito: as planilhas do lote são números e nomes curtos.
List<String> _celulas(String linha) {
  final celulas = <String>[];
  final atual = StringBuffer();
  var entreAspas = false;

  for (var i = 0; i < linha.length; i++) {
    final c = linha[i];
    if (c == '"') {
      // Aspas duplas seguidas dentro do campo são uma aspa literal.
      if (entreAspas && i + 1 < linha.length && linha[i + 1] == '"') {
        atual.write('"');
        i++;
      } else {
        entreAspas = !entreAspas;
      }
    } else if (c == ',' && !entreAspas) {
      celulas.add(atual.toString());
      atual.clear();
    } else {
      atual.write(c);
    }
  }
  celulas.add(atual.toString());
  return celulas;
}
