// lote_local.dart — o lote inteiro no cliente: lê planilha, roda, exporta.
//
// Antes isto era o `/predict_batch_file` do backend. Agora o navegador faz
// tudo: parse do CSV/XLSX, uma passada da rede sobre as N linhas e a planilha
// de volta. Nada sai da máquina de quem usa.
//
// FORMATO DE I/O — o mesmo esquema de colunas vale na ida e na volta:
//
//   Entrada: nome + as 31 colunas do contrato, na ordem de `kColunasContrato`
//   Saída escalares: nome, tbreak, tsat, TF, tst, pi_max, severidade, avisos
//   Saída curvas (formato longo): nome, t, y_forte, y_carrier, T_out
//
// As unidades são as do contrato (SI): −ΔH em J/mol, P em Pa, dp em m. Não são
// as da tela — o lote é arquivo entra / arquivo sai e não passa pelos campos.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/resultado_binario.dart';
import 'contrato.dart';
import 'preditor_onnx.dart';

/// Escalares que a saída traz por experimento: chave interna + rótulo na tela.
const List<(String chave, String rotulo)> kEscalaresLote = [
  ('tbreak', 't_break'),
  ('tsat', 't_sat'),
  ('TF', 'TF'),
  ('tst', 't_st'),
  ('pi_max', 'πmax'),
  ('severidade', 'severidade'),
];

/// Cabeçalho da planilha de entrada: o nome do experimento e as 31 colunas.
List<String> get colunasDaPlanilha => ['nome', ...kColunasContrato];

/// Quantas linhas da amostra a prévia mostra.
const int kLinhasPrevia = 4;

/// Teto de linhas por lote. A rede é rápida, mas 100 mil curvas de 200 pontos
/// não cabem na memória de uma aba de navegador.
const int kMaxLinhasLote = 5000;

/// Quanto do arquivo é decodificado pra ler cabeçalho e amostra na prévia.
const int _bytesDeAmostra = 64 * 1024;

const String mediaCsv = 'text/csv';
const String mediaXlsx =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

// --- Prévia (antes de rodar) ---

/// O que o arquivo escolhido tem dentro, lido sem decodificá-lo inteiro.
class PreviaLote {
  final List<String> colunas;
  final List<List<String>> amostra;
  final int totalLinhas;
  final List<String> faltando;

  const PreviaLote({
    required this.colunas,
    required this.amostra,
    required this.totalLinhas,
    required this.faltando,
  });

  bool get valida => faltando.isEmpty && totalLinhas > 0;
}

/// Cabeçalho e primeiras linhas de um CSV, sem montar String do arquivo todo.
PreviaLote? lerPreviaCsv(Uint8List bytes, {int amostra = kLinhasPrevia}) {
  final inicio = utf8.decode(
    bytes.sublist(0, math.min(bytes.length, _bytesDeAmostra)),
    allowMalformed: true,
  );
  final linhas = _linhasNaoVazias(inicio);
  if (linhas.isEmpty) return null;
  return _montarPrevia(
    _celulas(linhas.first).map((c) => c.trim()).toList(),
    [for (final l in linhas.skip(1).take(amostra)) _celulas(l)],
    _contarLinhasDeDados(bytes),
  );
}

/// Mesma prévia, a partir de uma planilha XLSX já lida.
PreviaLote? _previaDeTabela(
  List<List<String>> tabela, {
  int amostra = kLinhasPrevia,
}) {
  if (tabela.isEmpty) return null;
  return _montarPrevia(
    tabela.first.map((c) => c.trim()).toList(),
    tabela.skip(1).take(amostra).toList(),
    tabela.length - 1,
  );
}

PreviaLote _montarPrevia(
  List<String> colunas,
  List<List<String>> amostra,
  int totalLinhas,
) {
  final presentes = colunas.toSet();
  return PreviaLote(
    colunas: colunas,
    amostra: amostra,
    totalLinhas: totalLinhas,
    faltando: [
      for (final obrigatoria in kColunasContrato)
        if (!presentes.contains(obrigatoria)) obrigatoria,
    ],
  );
}

// --- Leitura completa ---

/// Uma linha da planilha já traduzida pro vetor que a rede espera.
class LinhaLote {
  final String nome;
  final List<double> x31;
  const LinhaLote(this.nome, this.x31);
}

/// Erro de formato da planilha, com a mensagem que vai direto pra tela.
class ErroDePlanilha implements Exception {
  final String mensagem;
  const ErroDePlanilha(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Lê a planilha inteira e devolve as linhas prontas pra rede.
List<LinhaLote> lerPlanilha(Uint8List bytes, String nomeArquivo) =>
    _tabelaParaLinhas(_lerTabela(bytes, nomeArquivo));

/// Prévia de qualquer um dos dois formatos.
PreviaLote? lerPrevia(Uint8List bytes, String nomeArquivo) =>
    _ehCsv(nomeArquivo)
    ? lerPreviaCsv(bytes)
    : _previaDeTabela(_lerTabela(bytes, nomeArquivo));

bool _ehCsv(String nome) => nome.toLowerCase().endsWith('.csv');

/// CSV ou XLSX → tabela de texto (a primeira linha é o cabeçalho).
List<List<String>> _lerTabela(Uint8List bytes, String nomeArquivo) {
  if (_ehCsv(nomeArquivo)) {
    final linhas = _linhasNaoVazias(utf8.decode(bytes, allowMalformed: true));
    return [for (final l in linhas) _celulas(l)];
  }

  final Excel planilha;
  try {
    planilha = Excel.decodeBytes(bytes);
  } catch (e) {
    throw ErroDePlanilha('não consegui abrir a planilha: $e');
  }
  final aba = planilha.tables[planilha.tables.keys.first];
  if (aba == null || aba.rows.isEmpty) {
    throw const ErroDePlanilha('a planilha não tem nenhuma aba com dados');
  }
  return [
    for (final linha in aba.rows)
      [for (final celula in linha) celula?.value?.toString().trim() ?? ''],
  ];
}

List<LinhaLote> _tabelaParaLinhas(List<List<String>> tabela) {
  if (tabela.isEmpty) throw const ErroDePlanilha('arquivo vazio');

  final cabecalho = tabela.first.map((c) => c.trim()).toList();
  final onde = <String, int>{
    for (var i = 0; i < cabecalho.length; i++) cabecalho[i]: i,
  };

  final faltando = [
    for (final c in kColunasContrato)
      if (!onde.containsKey(c)) c,
  ];
  if (faltando.isNotEmpty) {
    throw ErroDePlanilha(
      faltando.length == 1
          ? 'Falta a coluna ${faltando.first}.'
          : 'Faltam ${faltando.length} colunas: ${faltando.join(', ')}.',
    );
  }

  final dados = tabela.skip(1).where((l) => l.any((c) => c.trim().isNotEmpty));
  final iNome = onde['nome'];
  final linhas = <LinhaLote>[];

  for (final (i, linha) in dados.indexed) {
    final x31 = List<double>.filled(kDimX, 0);
    for (var j = 0; j < kDimX; j++) {
      final coluna = onde[kColunasContrato[j]]!;
      final bruto = coluna < linha.length ? linha[coluna].trim() : '';
      // Vírgula decimal: teclado pt-BR e Excel em português produzem isso.
      final valor = double.tryParse(bruto.replaceAll(',', '.'));
      if (valor == null || !valor.isFinite) {
        // +2: a linha 1 é o cabeçalho e a contagem do usuário começa em 1.
        throw ErroDePlanilha(
          'Linha ${i + 2}, coluna ${kColunasContrato[j]}: '
          '${bruto.isEmpty ? 'célula vazia' : '"$bruto" não é número'}.',
        );
      }
      x31[j] = valor;
    }
    final nome =
        iNome != null && iNome < linha.length && linha[iNome].isNotEmpty
        ? linha[iNome]
        : 'exp_${i + 1}';
    linhas.add(LinhaLote(nome, x31));
  }

  if (linhas.isEmpty) {
    throw const ErroDePlanilha('arquivo sem nenhuma linha de dados');
  }
  if (linhas.length > kMaxLinhasLote) {
    throw ErroDePlanilha(
      'Lote de ${linhas.length} linhas passa do teto de $kMaxLinhasLote.',
    );
  }
  return linhas;
}

// --- Rodar ---

/// O que voltou de um lote: os resultados, quantos saíram com aviso e quanto
/// tempo a rede levou (é o número que mostra o ganho sobre o solver).
class ResultadoLote {
  final List<String> nomes;
  final List<ResultadoBinario> resultados;
  final int tempoMs;

  const ResultadoLote(this.nomes, this.resultados, this.tempoMs);

  int get total => resultados.length;
  int get comAviso => resultados.where((r) => r.avisos.isNotEmpty).length;
}

/// Roda as N linhas numa passada só da rede.
Future<ResultadoLote> rodarLote(List<LinhaLote> linhas) async {
  // A carga dos modelos fica fora do cronômetro: na primeira vez ela é quase
  // todo o tempo, e o número que a tela mostra deve ser o da rede.
  await PreditorOnnx.instancia.carregar();
  final relogio = Stopwatch()..start();
  final resultados = await PreditorOnnx.instancia.predizerLoteX31([
    for (final l in linhas) l.x31,
  ]);
  return ResultadoLote(
    [for (final l in linhas) l.nome],
    resultados,
    relogio.elapsedMilliseconds,
  );
}

// --- Exportação ---

/// Uma linha por experimento: nome + escalares + avisos concatenados.
List<List<String>> _resumo(ResultadoLote lote, Set<String> escalares) {
  final colunas = [
    for (final (chave, _) in kEscalaresLote)
      if (escalares.contains(chave)) chave,
  ];
  return [
    ['nome', ...colunas, 'avisos'],
    for (var i = 0; i < lote.total; i++)
      [
        lote.nomes[i],
        for (final c in colunas) _escalar(lote.resultados[i], c).toString(),
        lote.resultados[i].avisos.join('; '),
      ],
  ];
}

double _escalar(ResultadoBinario r, String chave) => switch (chave) {
  'tbreak' => r.tBreak,
  'tsat' => r.tSat,
  'TF' => r.tF,
  'tst' => r.tSt,
  'pi_max' => r.piMax,
  _ => r.severidade,
};

/// Formato longo: uma linha por ponto. Longo em vez de largo porque 100 pontos
/// × 4 séries viram 400 colunas — planilha que ninguém lê e gráfico nenhum come.
List<List<String>> _curvas(ResultadoLote lote) => [
  ['nome', 't', 'y_forte', 'y_carrier', 'T_out'],
  for (var i = 0; i < lote.total; i++)
    for (var j = 0; j < lote.resultados[i].tempos.length; j++)
      [
        lote.nomes[i],
        '${lote.resultados[i].tempos[j]}',
        '${lote.resultados[i].yForte[j]}',
        '${lote.resultados[i].yCarreador[j]}',
        '${lote.resultados[i].tSaida[j]}',
      ],
];

/// Uma predição vira um lote de uma linha: mesmas colunas, mesmas abas. Quem
/// abrir os dois arquivos não precisa aprender dois formatos.
ResultadoLote loteDeUm(String nome, ResultadoBinario resultado) =>
    ResultadoLote([nome], [resultado], 0);

/// Todas as chaves de escalar, na ordem do cabeçalho.
Set<String> get todosOsEscalares => {for (final (c, _) in kEscalaresLote) c};

/// CSV só com os escalares — achatar as curvas em colunas fica ilegível.
Uint8List loteParaCsv(ResultadoLote lote, Set<String> escalares) =>
    _tabelaParaCsv(_resumo(lote, escalares));

/// XLSX com aba 'Resumo' e, quando pedido, uma aba 'Curvas' no formato longo.
/// `comResumo` falso deixa só as curvas: a exportação de uma predição pode
/// pedir isso, e uma aba de resumo sem escalar nenhum não diria nada.
Uint8List loteParaXlsx(
  ResultadoLote lote,
  Set<String> escalares, {
  bool comCurvas = false,
  bool comResumo = true,
}) {
  final abas = <String, List<List<String>>>{
    if (comResumo) 'Resumo': _resumo(lote, escalares),
    if (comCurvas) 'Curvas': _curvas(lote),
  };
  return _tabelasParaXlsx(abas);
}

// --- Template ---

/// Linhas de exemplo do modelo, dentro das faixas de treino e nas unidades do
/// contrato. Servem de referência de grandeza pra quem preenche na mão.
const List<List<Object>> _exemplos = [
  [
    'exemplo_1',
    8.0, -0.02, 0.1, 1500.0, 1.0, 0.0, 0.1, 25000.0, 29.0, // c0
    8.0, -0.02, 0.1, 1500.0, 1.0, 0.0, 0.1, 25000.0, 37.0, // c1
    0.4, 650.0, 1000.0, // leito
    0.01, 298.0, 1.0e6, 0.5, 50.0, 0.4, 2.0e-3, 1.0e-5, 0.035, // globais
    0.5, // y0
  ],
  [
    'exemplo_2',
    5.0,
    -0.01,
    0.02,
    900.0,
    0.9,
    -500.0,
    0.05,
    15000.0,
    29.0,
    12.0,
    -0.03,
    0.5,
    2200.0,
    1.1,
    800.0,
    0.3,
    40000.0,
    40.0,
    0.38,
    750.0,
    950.0,
    0.02,
    310.0,
    2.0e6,
    1.0,
    70.0,
    0.5,
    1.0e-3,
    2.0e-5,
    0.05,
    0.6,
  ],
];

List<List<String>> _tabelaDoTemplate() => [
  colunasDaPlanilha,
  for (final linha in _exemplos) [for (final v in linha) '$v'],
];

Uint8List templateCsv() => _tabelaParaCsv(_tabelaDoTemplate());

Uint8List templateXlsx() => _tabelasParaXlsx({'Modelo': _tabelaDoTemplate()});

// --- Serialização ---

Uint8List _tabelaParaCsv(List<List<String>> tabela) {
  final buffer = StringBuffer();
  for (final linha in tabela) {
    buffer.writeln([for (final c in linha) _celulaCsv(c)].join(','));
  }
  return Uint8List.fromList(utf8.encode(buffer.toString()));
}

/// Aspas só onde precisa: vírgula, aspas ou quebra de linha dentro do campo.
String _celulaCsv(String valor) => valor.contains(RegExp(r'[",\r\n]'))
    ? '"${valor.replaceAll('"', '""')}"'
    : valor;

Uint8List _tabelasParaXlsx(Map<String, List<List<String>>> abas) {
  final planilha = Excel.createExcel();
  final padrao = planilha.getDefaultSheet();

  for (final entrada in abas.entries) {
    final aba = planilha[entrada.key];
    for (final linha in entrada.value) {
      aba.appendRow([for (final c in linha) TextCellValue(c)]);
    }
  }
  // A aba que o pacote cria sozinho ficaria vazia no meio das nossas.
  if (padrao != null && !abas.containsKey(padrao)) planilha.delete(padrao);

  final bytes = planilha.encode();
  if (bytes == null) {
    throw const ErroDePlanilha('não consegui gerar o XLSX');
  }
  return Uint8List.fromList(bytes);
}

// --- CSV cru ---

List<String> _linhasNaoVazias(String texto) => texto
    .split(RegExp(r'\r\n|\r|\n'))
    .where((linha) => linha.trim().isNotEmpty)
    .toList();

/// Conta as linhas com conteúdo sem montar String nenhuma, e desconta o
/// cabeçalho. Linha só de espaço não conta.
int _contarLinhasDeDados(Uint8List bytes) {
  const quebra = 0x0A;
  var total = 0;
  var temConteudo = false;
  for (final b in bytes) {
    if (b == quebra) {
      if (temConteudo) total++;
      temConteudo = false;
    } else if (b > 0x20) {
      temConteudo = true;
    }
  }
  if (temConteudo) total++;
  return math.max(0, total - 1);
}

/// Divide uma linha de CSV em células, respeitando aspas duplas.
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
