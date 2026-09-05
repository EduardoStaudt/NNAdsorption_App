// param_defs_ponte.dart — traduz o estado da tela pro vetor do contrato.
//
// A tela e a rede falam nomes e unidades diferentes, e isso é proposital: o
// pesquisador digita −ΔH em kJ/mol e pressão em MPa porque é assim que se
// escreve num artigo; a rede foi treinada em SI puro. A conversão vive aqui,
// num lugar só, e é a única coisa entre `models/param_defs.dart` e
// `inferencia/contrato.dart`.
//
// Se um parâmetro novo entrar na tela, ele entra nesta lista **na posição do
// contrato** — a ordem desta lista É a ordem das 31 colunas.
import '../models/param_defs.dart' show chaveComponente;

/// De onde sai o valor de uma coluna do contrato e por quanto multiplicá-lo.
class PonteDeParametro {
  /// Chave no mapa que a tela monta (ex.: `b_ref_1`, `T_in`).
  final String chaveDaTela;

  /// Fator de conversão pra unidade do contrato. 1.0 = mesma unidade.
  final double fator;

  const PonteDeParametro(this.chaveDaTela, [this.fator = 1.0]);
}

// Fatores das três unidades que diferem entre a tela e o contrato.
const double _kJParaJ = 1000.0; // −ΔH: kJ/mol → J/mol
const double _mPaParaPa = 1e6; // P: MPa → Pa
const double _mmParaM = 1e-3; // d_p: mm → m

/// Chaves base da tela, na ordem dos 9 parâmetros por componente do contrato
/// (qm_ref, k2, B_ref, k4, n_ref, k6, kL, dH, Cpg).
const List<(String base, double fator)> _porComponente = [
  ('qm_ref', 1.0),
  ('k2', 1.0),
  ('b_ref', 1.0), // contrato: B_ref
  ('k4', 1.0),
  ('n_ref', 1.0),
  ('k6', 1.0),
  ('kL', 1.0),
  ('dH', _kJParaJ),
  ('cp_g', 1.0), // contrato: Cpg
];

/// As 31 pontes, na ordem exata do contrato v22. Componente 1 da tela é o
/// carreador (c0); o 2 é o gás forte (c1).
final List<PonteDeParametro> kPontesDoContrato = [
  for (var comp = 1; comp <= 2; comp++)
    for (final (base, fator) in _porComponente)
      PonteDeParametro(chaveComponente(base, comp), fator),
  // leito e adsorvente
  const PonteDeParametro('eps'), // contrato: eb
  const PonteDeParametro('rho_b'),
  const PonteDeParametro('cp_s'), // contrato: Cps
  // globais — Dt é o último, depois de Dm
  const PonteDeParametro('vs'),
  const PonteDeParametro('T_in'), // contrato: Tin
  const PonteDeParametro('P', _mPaParaPa),
  const PonteDeParametro('L'),
  const PonteDeParametro('h_w'), // contrato: hw
  const PonteDeParametro('lam'),
  const PonteDeParametro('dp', _mmParaM),
  const PonteDeParametro('Dm'),
  const PonteDeParametro('Dt'),
  // alimentação
  const PonteDeParametro('y0'),
];
