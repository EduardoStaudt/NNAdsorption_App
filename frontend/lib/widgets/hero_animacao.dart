// hero_animacao.dart — janela de "sistema" com a animação do hero desenhada
// num CustomPainter. Três estágios em loop (partículas → rede → curva),
// todos fluindo da esquerda pra direita. Ver DESIGN.md (paleta âmbar, mono).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/colors.dart';

const _tau = math.pi * 2;

// ----------------------------------------------------------------------------
// Dados estáticos (calculados uma vez; nunca dentro de paint()).
// ----------------------------------------------------------------------------

class _Particula {
  final double y; // 0..1 dentro do cilindro
  final double vel; // multiplicador de velocidade
  final double fase; // deslocamento inicial em X (0..1)
  final double wobbleFreq;
  final double wobbleFase;
  final bool accent2;
  const _Particula(
    this.y,
    this.vel,
    this.fase,
    this.wobbleFreq,
    this.wobbleFase,
    this.accent2,
  );
}

class _No {
  final double x; // normalizado no conteúdo
  final double y;
  final bool meio; // camada do meio → accent2
  const _No(this.x, this.y, this.meio);
}

class _Aresta {
  final int de;
  final int para; // índices globais de nó
  final bool accent2;
  const _Aresta(this.de, this.para, this.accent2);
}

// ----------------------------------------------------------------------------
// Widget: a janela + o loop de animação.
// ----------------------------------------------------------------------------

class HeroAnimacao extends StatefulWidget {
  const HeroAnimacao({super.key});

  @override
  State<HeroAnimacao> createState() => _HeroAnimacaoState();
}

class _HeroAnimacaoState extends State<HeroAnimacao>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _ctrl;

  // Tudo abaixo é estático — calculado uma vez no initState.
  late final List<_Particula> _particulas;
  late final List<_No> _nos;
  late final List<_Aresta> _arestas;
  late final List<Offset> _curva; // amostras normalizadas da sigmoide

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();
    WidgetsBinding.instance.addObserver(this);

    // Partículas com seeds fixas (mesma "aleatoriedade" a cada carga).
    final rnd = math.Random(42);
    _particulas = List.generate(18, (i) {
      return _Particula(
        0.16 + rnd.nextDouble() * 0.68, // y no cilindro
        3.0 + rnd.nextDouble() * 3.0, // vel 3..6
        rnd.nextDouble(), // fase
        0.5 + rnd.nextDouble() * 1.5, // freq do wobble
        rnd.nextDouble() * _tau, // fase do wobble
        i % 3 == 0, // 1 a cada 3 usa accent2
      );
    });

    // Rede 3 → 4 → 4 (colunas em x fixo, nós centralizados em y).
    const colunas = [3, 4, 4];
    const xs = [0.16, 0.5, 0.84];
    final nos = <_No>[];
    for (var c = 0; c < colunas.length; c++) {
      final n = colunas[c];
      for (var i = 0; i < n; i++) {
        final y = n == 1 ? 0.5 : 0.24 + (i / (n - 1)) * 0.52;
        nos.add(_No(xs[c], y, c == 1));
      }
    }
    _nos = nos;

    // Arestas entre camadas adjacentes (índices globais: 0..2, 3..6, 7..10).
    final arestas = <_Aresta>[];
    var k = 0;
    void conecta(List<int> a, List<int> b) {
      for (final u in a) {
        for (final v in b) {
          arestas.add(_Aresta(u, v, k % 4 == 0));
          k++;
        }
      }
    }

    conecta([0, 1, 2], [3, 4, 5, 6]);
    conecta([3, 4, 5, 6], [7, 8, 9, 10]);
    _arestas = arestas;

    // Curva sigmoidal (mesma forma da C(z)) — 80 amostras normalizadas.
    const n = 80;
    _curva = List.generate(n, (i) {
      final x = i / (n - 1);
      final y = 1 / (1 + math.exp(-11 * (x - 0.5)));
      return Offset(x, y);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced-motion: congela num quadro representativo (curva desenhada).
    if (MediaQuery.of(context).disableAnimations) {
      if (_ctrl.isAnimating) _ctrl.stop();
      _ctrl.value = 0.86;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  // Pausa quando a aba/app sai de primeiro plano — economiza ciclos.
  // (Abas ocultas já são pausadas pelo scheduler do Flutter; isto reforça.)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final reduzir = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (state == AppLifecycleState.resumed && !reduzir) {
      if (!_ctrl.isAnimating) _ctrl.repeat();
    } else if (state != AppLifecycleState.resumed) {
      if (_ctrl.isAnimating) _ctrl.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = cores.accent;
    // accent2: creme no escuro; no claro, tom escuro do próprio tema (contraste)
    final accent2 = isDark ? const Color(0xFFF5F2E6) : cores.text;
    // Barra de título. No claro fica escura (valor original); no escuro é a cor
    // em teste — troque só este valor.
    final corTitulo = isDark
        ? const Color(0xFF0E1013) // 0xFFE8EAED
        : const Color(0xFF0E1013);
    // Label acompanha a barra: escuro sobre barra clara, claro sobre escura.
    // Assim dá pra trocar `corTitulo` sem se preocupar com a legibilidade.
    final corLabel = corTitulo.computeLuminance() > 0.5
        ? const Color(0xFF0E1013) //0xFFE8EAED
        : const Color(0xFFE8EAED);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.panel2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cores.line),
        boxShadow: [
          // Glow âmbar + sombra preta profunda (a janela "flutua")
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 60,
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 50,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Barra de título
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: corTitulo,
                border: Border(bottom: BorderSide(color: cores.line)),
              ),
              child: Row(
                children: [
                  _semaforo(const Color(0xFFFF5F57)),
                  const SizedBox(width: 8),
                  _semaforo(const Color(0xFFFEBC2E)),
                  const SizedBox(width: 8),
                  _semaforo(const Color(0xFF28C840)),
                  const SizedBox(width: 14),
                  Text(
                    'NNAdsorption',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.24, // 0.02em em 12px
                      color: corLabel,
                    ),
                  ),
                ],
              ),
            ),
            // Corpo: fundo estático + o painter animado isolado num RepaintBoundary
            Expanded(
              child: ColoredBox(
                color: cores.panel,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, _) => CustomPaint(
                      size: Size.infinite,
                      painter: _HeroPainter(
                        progresso: _ctrl.value,
                        accent: accent,
                        accent2: accent2,
                        corEixo: cores.text,
                        particulas: _particulas,
                        nos: _nos,
                        arestas: _arestas,
                        curva: _curva,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _semaforo(Color c) => Container(
    width: 11,
    height: 11,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}

// ----------------------------------------------------------------------------
// Painter: só desenha o quadro do `progresso` atual. Sem alocação em loop.
// ----------------------------------------------------------------------------

class _HeroPainter extends CustomPainter {
  final double progresso;
  final Color accent;
  final Color accent2;
  final Color corEixo;
  final List<_Particula> particulas;
  final List<_No> nos;
  final List<_Aresta> arestas;
  final List<Offset> curva;

  _HeroPainter({
    required this.progresso,
    required this.accent,
    required this.accent2,
    required this.corEixo,
    required this.particulas,
    required this.nos,
    required this.arestas,
    required this.curva,
  });

  // rampa linear 0→1 entre a e b
  double _rampa(double x, double a, double b) =>
      ((x - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 26.0;
    final r = Rect.fromLTRB(pad, pad, size.width - pad, size.height - pad);
    if (r.width <= 0 || r.height <= 0) return;

    // Paints reutilizados (criados uma vez por quadro, nunca dentro dos loops).
    final traco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final preenche = Paint()..style = PaintingStyle.fill;
    final brilho = Paint()..style = PaintingStyle.fill;

    final p = progresso;
    final a1 = _rampa(p, 0.0, 0.03) * (1 - _rampa(p, 0.28, 0.32));
    final a2 = _rampa(p, 0.32, 0.34) * (1 - _rampa(p, 0.60, 0.66));
    final a3 = _rampa(p, 0.68, 0.71);

    if (a1 > 0.001) _estagio1(canvas, r, a1, traco, preenche, brilho);
    if (a2 > 0.001) _estagio2(canvas, r, a2, traco, preenche, brilho);
    if (a3 > 0.001) _estagio3(canvas, r, a3, traco, preenche, brilho);
  }

  // Estágio 1 — cilindro + partículas fluindo
  void _estagio1(
    Canvas canvas,
    Rect r,
    double alfa,
    Paint traco,
    Paint preenche,
    Paint brilho,
  ) {
    final cy = r.center.dy;
    final cilR = r.height * 0.30; // meia-altura do cilindro
    const capRx = 16.0;
    final left = r.left + capRx;
    final right = r.right - capRx;
    final larg = right - left;

    // Cilindro: linhas topo/base + elipses (tampas)
    traco
      ..color = accent.withValues(alpha: 0.4 * alfa)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(left, cy - cilR), Offset(right, cy - cilR), traco);
    canvas.drawLine(Offset(left, cy + cilR), Offset(right, cy + cilR), traco);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(left, cy),
        width: capRx * 2,
        height: cilR * 2,
      ),
      traco,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(right, cy),
        width: capRx * 2,
        height: cilR * 2,
      ),
      traco,
    );

    final wobbleAmp = cilR * 0.3;
    for (final part in particulas) {
      final cor = part.accent2 ? accent2 : accent;
      final yBase = cy - cilR + part.y * (cilR * 2);
      final wob =
          math.sin(progresso * _tau * part.wobbleFreq * 3 + part.wobbleFase) *
          wobbleAmp;
      final y = (yBase + wob).clamp(cy - cilR + 3, cy + cilR - 3);

      // Rastro: 4 cópias defasadas (desenha da mais distante pra cabeça).
      for (var k = 3; k >= 0; k--) {
        final xNorm = (part.fase + (progresso - k * 0.012) * part.vel) % 1.0;
        final x = left + xNorm * larg;
        final raio = 4.5 * (1 - k * 0.18);
        final op = alfa * (1 - k * 0.22);
        if (k == 0) {
          // Glow só na cabeça (mantém a contagem de blurs baixa)
          brilho
            ..color = cor.withValues(alpha: 0.5 * op)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawCircle(Offset(x, y), raio + 3, brilho);
        }
        preenche.color = cor.withValues(alpha: op);
        canvas.drawCircle(Offset(x, y), raio, preenche);
      }
    }
  }

  // Estágio 2 — rede neural (arestas com stagger + nós pulsando)
  void _estagio2(
    Canvas canvas,
    Rect r,
    double alfa,
    Paint traco,
    Paint preenche,
    Paint brilho,
  ) {
    Offset pos(int i) =>
        Offset(r.left + nos[i].x * r.width, r.top + nos[i].y * r.height);

    final stageT = _rampa(progresso, 0.32, 0.62);
    final perDelay = 0.5 / arestas.length;

    // Arestas — acendem em sequência
    traco.strokeWidth = 1.2;
    traco.maskFilter = null;
    for (var i = 0; i < arestas.length; i++) {
      final e = arestas[i];
      final ap = _rampa(stageT, i * perDelay, i * perDelay + 0.14);
      final op = (0.08 + ap * 0.30) * alfa;
      traco.color = (e.accent2 ? accent2 : accent).withValues(alpha: op);
      canvas.drawLine(pos(e.de), pos(e.para), traco);
    }

    // Nós — pulse senoidal 0.7..1.0
    for (var i = 0; i < nos.length; i++) {
      final pulse = 0.85 + 0.15 * math.sin(progresso * _tau * 2 + i * 0.9);
      final raio = 8.0 * pulse;
      final cor = nos[i].meio ? accent2 : accent;
      final c = pos(i);
      brilho
        ..color = cor.withValues(alpha: 0.5 * alfa)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9 * pulse);
      canvas.drawCircle(c, raio + 4, brilho);
      preenche.color = cor.withValues(alpha: alfa);
      canvas.drawCircle(c, raio, preenche);
    }
  }

  // Estágio 3 — curva de breakthrough desenhando progressivamente
  void _estagio3(
    Canvas canvas,
    Rect r,
    double alfa,
    Paint traco,
    Paint preenche,
    Paint brilho,
  ) {
    // Área da curva com margem pros eixos
    final area = Rect.fromLTRB(
      r.left + 18,
      r.top + 10,
      r.right - 4,
      r.bottom - 16,
    );
    Offset ponto(int i) => Offset(
      area.left + curva[i].dx * area.width,
      area.bottom - curva[i].dy * area.height,
    );

    // Eixos
    traco
      ..color = corEixo.withValues(alpha: 0.15 * alfa)
      ..strokeWidth = 1.2
      ..maskFilter = null;
    canvas.drawLine(
      Offset(area.left, area.top),
      Offset(area.left, area.bottom),
      traco,
    );
    canvas.drawLine(
      Offset(area.left, area.bottom),
      Offset(area.right, area.bottom),
      traco,
    );

    final rev = _rampa(progresso, 0.68, 0.95);
    final n = (rev * (curva.length - 1)).floor();
    if (n < 1) return;

    // Um Path por quadro (fora de qualquer loop)
    final path = Path()..moveTo(ponto(0).dx, ponto(0).dy);
    for (var i = 1; i <= n; i++) {
      final pt = ponto(i);
      path.lineTo(pt.dx, pt.dy);
    }

    // Glow da curva + linha nítida (reusa o mesmo Path)
    traco
      ..color = accent.withValues(alpha: 0.5 * alfa)
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, traco);
    traco
      ..color = accent.withValues(alpha: alfa)
      ..maskFilter = null;
    canvas.drawPath(path, traco);

    // Cabeça da curva — só enquanto ainda está desenhando
    if (rev < 1.0) {
      final cab = ponto(n);
      brilho
        ..color = accent2.withValues(alpha: 0.7 * alfa)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(cab, 8, brilho);
      preenche.color = accent2.withValues(alpha: alfa);
      canvas.drawCircle(cab, 4.5, preenche);
    }
  }

  @override
  bool shouldRepaint(_HeroPainter old) =>
      old.progresso != progresso ||
      old.accent != accent ||
      old.accent2 != accent2 ||
      old.corEixo != corEixo;
}
