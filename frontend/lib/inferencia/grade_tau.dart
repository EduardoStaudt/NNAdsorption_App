// grade_tau.dart — porte de `grid_tau` do `reference/exemplo_inferencia.py`.
//
// A rede de forma devolve 100 pontos numa grade normalizada τ ∈ [0,1]. Ela não
// é uniforme: 10% dos pontos cobrem o platô antes da ruptura, 70% a zona de
// transferência de massa (que é onde a curva tem forma) e 20% o platô depois
// da saturação. Multiplicar τ por TF devolve o eixo em segundos.
import 'dart:math' as math;

/// Quantos pontos a rede de forma devolve por série.
const int kPontosCurva = 100;

/// `np.linspace(a, b, n)`. Com `incluirFim: false` o passo é `(b-a)/n` e o
/// último ponto fica de fora — é o `endpoint=False` do numpy.
List<double> _linspace(double a, double b, int n, {bool incluirFim = true}) {
  if (n <= 0) return const [];
  if (n == 1) return [a];
  final passo = incluirFim ? (b - a) / (n - 1) : (b - a) / n;
  return [for (var i = 0; i < n; i++) a + passo * i];
}

/// Grade τ ∈ [0,1] com `m` pontos, densa entre a ruptura e a saturação.
///
/// `tbFrac` e `tsFrac` são tb/TF e ts/TF.
List<double> gradeTau(
  double tbFrac,
  double tsFrac, {
  int m = kPontosCurva,
  double fracDensa = 0.70,
  double margem = 0.05,
}) {
  final t0 = math.max(0.0, tbFrac - margem);
  final tsUtil = tsFrac.isFinite ? tsFrac : 1.0;
  final t1 = math.min(math.max(tsUtil, t0 + 1e-3), 1.0);

  var nDensa = (fracDensa * m).round();
  final nPre = math.max(2, (0.10 * m).toInt());
  var nPos = m - nDensa - nPre;
  if (nPos < 0) {
    nDensa += nPos;
    nPos = 0;
  }

  final pre = _linspace(0.0, t0, nPre, incluirFim: false);
  final densa = _linspace(t0, t1, nDensa, incluirFim: nPos == 0);
  final pos = nPos > 0 ? _linspace(t1, 1.0, nPos + 1).sublist(1) : <double>[];

  final tau = [...pre, ...densa, ...pos]
    ..sort()
    ..toList();
  for (var i = 0; i < tau.length; i++) {
    tau[i] = tau[i].clamp(0.0, 1.0);
  }
  // Se a montagem não fechou em `m` pontos, cai numa grade uniforme — mesmo
  // escape do Python, pra o comprimento da curva nunca destoar do da rede.
  return tau.length == m ? tau : _linspace(0.0, 1.0, m);
}

/// Eixo do tempo em segundos, a partir dos tempos previstos.
List<double> montarEixoTempo(double tb, double ts, double tf) {
  final tau = gradeTau(tb / tf, ts / tf);
  return [for (final v in tau) v * tf];
}
