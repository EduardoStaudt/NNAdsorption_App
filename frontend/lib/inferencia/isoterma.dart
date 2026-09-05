// isoterma.dart — porte de `tst_ancora` do `reference/exemplo_inferencia.py`.
//
// Esta é a única física que roda em código, não na rede. A rede prevê os
// tempos como razões sobre a âncora estequiométrica `tst`; sem ela não há como
// desnormalizar tbreak e tsat pra segundos.
//
// Isoterma LRC avaliada em **pressão parcial (atm)** — não em concentração.
// As features usam concentração, e isso não é um descuido: são duas contas
// diferentes, cada uma como o treino a viu.
import 'dart:math' as math;

const double _r = 8.314; // J/(mol·K)
const double _atm = 101325.0; // Pa
const double _tref = 298.0; // K
const double _tfCap = 3600.0; // s — mesmo teto do gravador

/// Tempo estequiométrico (âncora temporal), em segundos.
///
///     tst_i = (L/vs) · (eb + rho_b · q*_i,alim / c_i,alim)
///     TF    = min(2 · max_i tst_i, 3600);   tst = TF/2
double tstAncora(List<double> x31) {
  final eb = x31[18];
  final rhoB = x31[19];
  final vs = x31[21];
  final tin = x31[22];
  final p = x31[23];
  final l = x31[24];
  final y0 = x31[30];

  final y = [y0, 1.0 - y0];
  // Pressão parcial em atm e concentração de alimentação em mol/m³.
  final pAtm = [y[0] * p / _atm, y[1] * p / _atm];
  final cFeed = [y[0] * p / (_r * tin), y[1] * p / (_r * tin)];

  final qm = List<double>.filled(2, 0);
  final b = List<double>.filled(2, 0);
  final n = List<double>.filled(2, 0);

  for (var i = 0; i < 2; i++) {
    final base = 9 * i;
    final qmRef = x31[base + 0], k2 = x31[base + 1];
    final bRef = x31[base + 2], k4 = x31[base + 3];
    final nRef = x31[base + 4], k6 = x31[base + 5];

    // Coeficientes k1/k3/k5 reconstruídos a partir dos valores em TREF.
    final k1 = qmRef - k2 * _tref;
    final k3 = bRef * math.exp(-k4 / _tref);
    final k5 = nRef - k6 / _tref;

    qm[i] = k1 + k2 * tin;
    b[i] = k3 * math.exp(k4 / tin);
    n[i] = k5 + k6 / tin;
  }

  final termo = [
    b[0] * math.pow(pAtm[0], n[0]).toDouble(),
    b[1] * math.pow(pAtm[1], n[1]).toDouble(),
  ];
  final den = 1.0 + termo[0] + termo[1];

  var maiorTst = 0.0;
  for (var i = 0; i < 2; i++) {
    final qstar = qm[i] * termo[i] / den; // mol/kg
    final tstI = (l / vs) * (eb + rhoB * qstar / cFeed[i]);
    if (tstI > maiorTst) maiorTst = tstI;
  }
  return math.min(2.0 * maiorTst, _tfCap) / 2.0;
}
