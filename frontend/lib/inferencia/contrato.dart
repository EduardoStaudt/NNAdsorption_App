// contrato.dart — porte de `reference/contrato_io_22.py` da lib `nnadsorption`.
//
// Ordem das 31 colunas que a rede v22 espera. É a única coisa que não pode
// mudar: os `.onnx` foram treinados nesta ordem exata e trocar duas colunas
// não dá erro nenhum — só devolve número errado.
//
//   comp0 (carreador): qm_ref, k2, B_ref, k4, n_ref, k6, kL, dH, Cpg   0..8
//   comp1 (gás forte): idem                                            9..17
//   leito:             eb, rho_b, Cps                                  18..20
//   globais:           vs, Tin, P, L, hw, lam, dp, Dm, Dt              21..29
//   alimentação:       y0  (y1 = 1 − y0)                               30
//
// ATENÇÃO ao `Dt`: ele é o **último** global, depois de Dm — não vem junto do
// L como a tela sugere. A v21 não tinha Dt; ele foi acrescentado no fim.
import 'param_defs_ponte.dart';

/// Quantas colunas o vetor de entrada tem.
const int kDimX = 31;

/// Nomes das 31 colunas, na ordem do contrato.
const List<String> kColunasContrato = [
  // comp0
  'c0_qm_ref', 'c0_k2', 'c0_B_ref', 'c0_k4', 'c0_n_ref',
  'c0_k6', 'c0_kL', 'c0_dH', 'c0_Cpg',
  // comp1
  'c1_qm_ref', 'c1_k2', 'c1_B_ref', 'c1_k4', 'c1_n_ref',
  'c1_k6', 'c1_kL', 'c1_dH', 'c1_Cpg',
  // leito
  'eb', 'rho_b', 'Cps',
  // globais
  'vs', 'Tin', 'P', 'L', 'hw', 'lam', 'dp', 'Dm', 'Dt',
  // alimentação
  'y0',
];

/// Colunas amostradas em escala log: B_ref e kL de cada componente.
/// A ordem é a do `log_x_idx()` do Python (os dois B_ref, depois os dois kL).
const List<int> kLogXIdx = [2, 11, 6, 15];

/// Faixas de treino, por parâmetro físico (`X_RANGES` do contrato).
/// Fora delas a rede extrapola: a predição sai, com aviso.
const Map<String, (double, double)> kFaixas = {
  'qm_ref': (1.0, 15.0),
  'k2': (-0.1, 0.0),
  'B_ref': (1e-4, 1.0),
  'k4': (0.0, 3200.0),
  'n_ref': (0.5, 1.5),
  'k6': (-2200.0, 2200.0),
  'kL': (0.01, 1.0),
  'dH': (5e3, 50e3),
  'Cpg': (25.0, 45.0),
  'eb': (0.30, 0.50),
  'rho_b': (400.0, 900.0),
  'Cps': (800.0, 1200.0),
  'vs': (0.001, 0.05),
  'Tin': (288.0, 323.0),
  'P': (1e5, 3e6),
  'L': (0.3, 1.5),
  'hw': (20.0, 100.0),
  'lam': (0.1, 0.8),
  'dp': (0.5e-3, 5e-3),
  'Dm': (5e-6, 3e-5),
  'Dt': (0.01, 0.06),
  'y0': (0.20, 0.75),
};

/// Monta o vetor X(31) a partir do estado da tela.
///
/// Faz duas traduções de uma vez: o nome da chave (a tela usa `b_ref_1`, o
/// contrato usa `c0_B_ref`) e a unidade (a tela mostra kJ/mol, MPa e mm; a
/// rede quer J/mol, Pa e m). Ver `param_defs_ponte.dart`.
List<double> montarX31(Map<String, double> paramsDaTela) {
  final x = List<double>.filled(kDimX, 0.0);
  for (var i = 0; i < kDimX; i++) {
    final ponte = kPontesDoContrato[i];
    final valor = paramsDaTela[ponte.chaveDaTela];
    if (valor == null) {
      throw ArgumentError('falta o parâmetro "${ponte.chaveDaTela}"');
    }
    x[i] = valor * ponte.fator;
  }
  return x;
}

/// Confere cada coluna contra as faixas de treino. Lista vazia = tudo dentro.
List<String> validar(List<double> x31) {
  final avisos = <String>[];
  for (var i = 0; i < kDimX; i++) {
    final faixa = kFaixas[_chaveDaFaixa(kColunasContrato[i])];
    if (faixa == null) continue;
    final (lo, hi) = faixa;
    final v = x31[i];
    if (v < lo || v > hi) {
      avisos.add(
        '${kColunasContrato[i]} = ${_curto(v)} '
        'fora da faixa [${_curto(lo)}, ${_curto(hi)}]',
      );
    }
  }
  return avisos;
}

/// 'c0_B_ref' → 'B_ref'; 'vs' → 'vs'. As faixas são por parâmetro físico, não
/// por componente.
String _chaveDaFaixa(String coluna) =>
    coluna.startsWith('c0_') || coluna.startsWith('c1_')
    ? coluna.substring(3)
    : coluna;

/// Número curto pra mensagem de aviso (o `%.4g` do Python).
String _curto(double v) {
  final a = v.abs();
  if (a != 0 && (a < 1e-3 || a >= 1e5)) return v.toStringAsExponential(3);
  return double.parse(v.toStringAsPrecision(4)).toString();
}
