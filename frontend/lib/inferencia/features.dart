// features.dart — porte de `reference/features_22.py` da lib `nnadsorption`.
//
// A rede não recebe os 31 parâmetros crus: recebe 47, sendo as 16 últimas
// combinações adimensionais (tempo de residência, números de transferência,
// seletividades, efeito térmico). Entregá-las prontas é parte do contrato do
// modelo — não é otimização nossa, é o que o treino viu.
//
// ORDEM DAS OPERAÇÕES (importa): enriquece 31 → 47 primeiro, **depois** aplica
// log nas colunas cruas de `kLogXIdx`. Inverter isso muda B_ref e kL antes de
// eles entrarem nas features, e o resultado sai errado sem nenhum erro.
//
// NÃO há z-score em lugar nenhum: os `.onnx` normalizam por dentro.
import 'dart:math' as math;
import 'dart:typed_data';

import 'contrato.dart';

const double _r = 8.314;

/// Nomes das 16 features derivadas, na ordem em que são concatenadas.
const List<String> kNomesFeatures = [
  'tau_resid',
  'NTU_0',
  'NTU_1',
  'Pe',
  'cf_0',
  'cf_1',
  'K_cap_0',
  'K_cap_1',
  'selet_B',
  'selet_q',
  'adT_0',
  'adT_1',
  'ratio_kL',
  'Bi_dp',
  'severidade',
  'NTU_wall',
];

/// Quais features recebem log (as multiplicativas). `adT_*` são lineares e a
/// severidade já vive em [0,1] — essas três ficam como estão.
const List<bool> _logMask = [
  true, true, true, true, true, true, true, true, // tau..K_cap_1
  true, true, // selet_B, selet_q
  false, false, // adT_0, adT_1
  true, true, // ratio_kL, Bi_dp
  false, // severidade
  true, // NTU_wall
];

// Índices do contrato v22 (ver `contrato.dart`).
const int _iEb = 18, _iRhoB = 19, _iCps = 20;
const int _iVs = 21, _iTin = 22, _iP = 23, _iL = 24;
const int _iHw = 25, _iDp = 27, _iDm = 28, _iDt = 29;
const int _iY0 = 30;

const double _eps = 1e-12;

/// Coluna `p` do componente `c` (bloco de 9 por componente).
double _col(List<double> x, int c, String p) {
  const idx = {
    'qm_ref': 0,
    'k2': 1,
    'B_ref': 2,
    'k4': 3,
    'n_ref': 4,
    'k6': 5,
    'kL': 6,
    'dH': 7,
    'Cpg': 8,
  };
  return x[c * 9 + idx[p]!];
}

double _norm01(double v, double lo, double hi, {bool log = false}) {
  var x = v, a = lo, b = hi;
  if (log) {
    x = math.log(math.max(x, 1e-30));
    a = math.log(math.max(a, 1e-30));
    b = math.log(math.max(b, 1e-30));
  }
  return ((x - a) / (b - a + 1e-12)).clamp(0.0, 1.0);
}

/// Índice de severidade do regime (Eq. 8 do artigo). Determinístico e com
/// pesos fixos de propósito: ele faz parte do contrato de entrada do modelo,
/// não é um ajuste que a gente possa mexer.
double severidadeRegime(List<double> x31) {
  final bC1 = _col(x31, 1, 'B_ref');
  final kLc1 = _col(x31, 1, 'kL');
  final qmC0 = _col(x31, 0, 'qm_ref');
  final k6C0 = _col(x31, 0, 'k6');
  final p = x31[_iP];
  final vs = x31[_iVs];
  final l = x31[_iL];
  final ntuC1 = kLc1 * l / math.max(vs, 1e-12);

  return 0.30 * _norm01(bC1, 1e-4, 1.0, log: true) +
      0.15 * _norm01(kLc1, 0.01, 1.0, log: true) +
      0.15 * _norm01(p, 1e5, 3e6) +
      0.15 * _norm01(qmC0, 1.0, 15.0) +
      0.15 * _norm01(-k6C0, -2200.0, 2200.0) +
      0.10 * _norm01(ntuC1, 0.0, 5.0);
}

/// As 16 features derivadas de um X(31), já com o log aplicado onde cabe.
List<double> featuresDerivadas(List<double> x) {
  final eb = x[_iEb];
  final rhoB = x[_iRhoB];
  final cps = x[_iCps];
  final vs = x[_iVs];
  final tin = x[_iTin];
  final p = x[_iP];
  final l = x[_iL];
  final hw = x[_iHw];
  final dp = x[_iDp];
  final dm = x[_iDm];
  final dt = x[_iDt];
  final y0 = x[_iY0];
  final y = [y0, 1.0 - y0];

  final qm = [_col(x, 0, 'qm_ref'), _col(x, 1, 'qm_ref')];
  final b = [_col(x, 0, 'B_ref'), _col(x, 1, 'B_ref')];
  final kL = [_col(x, 0, 'kL'), _col(x, 1, 'kL')];
  final dH = [_col(x, 0, 'dH'), _col(x, 1, 'dH')];
  final cpg = [_col(x, 0, 'Cpg'), _col(x, 1, 'Cpg')];

  // Concentração de alimentação (mol/m³). Aqui é concentração mesmo — o tst
  // usa pressão parcial em atm. São contas diferentes de propósito.
  final cf = [
    math.max(y[0] * p / (_r * tin), 1e-9),
    math.max(y[1] * p / (_r * tin), 1e-9),
  ];
  final denom = 1.0 + b[0] * cf[0] + b[1] * cf[1];
  final qstar = [qm[0] * b[0] * cf[0] / denom, qm[1] * b[1] * cf[1] / denom];
  final kCap = [rhoB * qstar[0] / (eb * cf[0]), rhoB * qstar[1] / (eb * cf[1])];

  final ct = math.max(p / (_r * tin), _eps); // mol/m³, gás ideal
  final cpgMist = y[0] * cpg[0] + y[1] * cpg[1]; // J/(mol·K)
  final ntuWall =
      (4.0 * hw * l / math.max(dt, _eps)) / math.max(vs * ct * cpgMist, _eps);

  final f = <double>[
    l * eb / math.max(vs, _eps), // tau_resid
    kL[0] * l / math.max(vs, _eps), // NTU_0
    kL[1] * l / math.max(vs, _eps), // NTU_1
    vs * l / math.max(dm, _eps), // Pe
    cf[0], cf[1],
    math.max(kCap[0], _eps), math.max(kCap[1], _eps),
    math.max(b[1] / math.max(b[0], _eps), _eps), // selet_B
    math.max((qm[1] * b[1]) / math.max(qm[0] * b[0], _eps), _eps), // selet_q
    dH[0] / math.max(rhoB * cps, _eps), // adT_0
    dH[1] / math.max(rhoB * cps, _eps), // adT_1
    math.max(kL[1] / math.max(kL[0], _eps), _eps), // ratio_kL
    vs * dp / math.max(dm, _eps), // Bi_dp
    severidadeRegime(x), // severidade [0,1]
    math.max(ntuWall, _eps), // NTU_wall
  ];

  for (var i = 0; i < f.length; i++) {
    if (_logMask[i]) f[i] = math.log(math.max(f[i], 1e-30));
  }
  // O `features_22.py` devolve float32; arredondar aqui também mantém o porte
  // idêntico ao Python bit a bit — sem isso a diferença fica em ~1e-8, que é
  // pouco, mas some da comparação o que ela deveria pegar.
  final f32 = Float32List.fromList(f);
  return [for (var i = 0; i < f.length; i++) f32[i]];
}

/// X(31) → X(47): concatena os crus com as 16 derivadas e **só então** aplica
/// log nas colunas de `kLogXIdx` (B_ref e kL de cada componente).
List<double> xEnriquecido(List<double> x31) {
  final x47 = <double>[...x31, ...featuresDerivadas(x31)];
  for (final j in kLogXIdx) {
    x47[j] = math.log(math.max(x47[j], 1e-30));
  }
  return x47;
}
