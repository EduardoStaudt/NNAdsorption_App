// ui_comum.dart — widgets visuais pequenos reutilizados em várias telas
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';

/// Container padrão dos painéis: fundo panel, borda line, cantos 14px
class Painel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const Painel({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cores.panel,
        border: Border.all(color: cores.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

/// Fundo do app: grade de pontinhos 26x26 + brilho suave no topo (do mockup)
class FundoPontilhado extends StatelessWidget {
  final Widget child;
  const FundoPontilhado({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _PontosPainter(
            corPonto: cores.text.withValues(alpha: 0.035),
            corBrilho: cores.accent.withValues(alpha: 0.05),
          ),
        ),
        child,
      ],
    );
  }
}

class _PontosPainter extends CustomPainter {
  final Color corPonto;
  final Color corBrilho;
  _PontosPainter({required this.corPonto, required this.corBrilho});

  @override
  void paint(Canvas canvas, Size size) {
    // Brilho radial no topo central
    final brilho = Paint()
      ..shader = RadialGradient(
        colors: [corBrilho, Colors.transparent],
      ).createShader(
        Rect.fromCenter(
          center: Offset(size.width / 2, -120),
          width: 900,
          height: 840,
        ),
      );
    canvas.drawRect(Offset.zero & size, brilho);

    // Grade de pontinhos a cada 26px — desenhados de uma vez só com
    // drawPoints (bem mais rápido que milhares de drawCircle)
    final pontos = <Offset>[
      for (double x = 0; x < size.width; x += 26)
        for (double y = 0; y < size.height; y += 26) Offset(x, y),
    ];
    final tintaPontos = Paint()
      ..color = corPonto
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(PointMode.points, pontos, tintaPontos);
  }

  @override
  bool shouldRepaint(_PontosPainter old) =>
      old.corPonto != corPonto || old.corBrilho != corBrilho;
}

/// "Eyebrow" do mockup: tracinho accent + texto mono maiúsculo
class Eyebrow extends StatelessWidget {
  final String texto;
  const Eyebrow(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Row(
      children: [
        Container(width: 14, height: 2, color: cores.accent),
        const SizedBox(width: 8),
        Text(
          texto.toUpperCase(),
          style: GoogleFonts.ibmPlexMono(
            fontSize: 11,
            letterSpacing: 1.5,
            color: cores.text3,
          ),
        ),
      ],
    );
  }
}

/// Cabeçalho de seção do mockup: eyebrow + título em Archivo 800
class CabecalhoSecao extends StatelessWidget {
  final String eyebrow;
  final String titulo;
  const CabecalhoSecao({super.key, required this.eyebrow, required this.titulo});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(eyebrow),
        const SizedBox(height: 4),
        Text(
          titulo,
          style: GoogleFonts.archivo(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: cores.text,
          ),
        ),
      ],
    );
  }
}

/// Detecta hover do mouse e reconstrói o filho — pra efeitos de hover
class Hover extends StatefulWidget {
  final Widget Function(bool emHover) builder;
  const Hover({super.key, required this.builder});

  @override
  State<Hover> createState() => _HoverState();
}

class _HoverState extends State<Hover> {
  bool _emHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _emHover = true),
      onExit: (_) => setState(() => _emHover = false),
      child: widget.builder(_emHover),
    );
  }
}

/// Afunda levemente o filho enquanto pressionado (feedback tátil)
class EscalaAoClicar extends StatefulWidget {
  final Widget child;
  const EscalaAoClicar({super.key, required this.child});

  @override
  State<EscalaAoClicar> createState() => _EscalaAoClicarState();
}

class _EscalaAoClicarState extends State<EscalaAoClicar> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressionado = true),
      onPointerUp: (_) => setState(() => _pressionado = false),
      onPointerCancel: (_) => setState(() => _pressionado = false),
      child: AnimatedScale(
        scale: _pressionado ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Bloco cinza pulsante usado como "skeleton" enquanto algo carrega
class Skeleton extends StatefulWidget {
  final double? largura;
  final double altura;
  final double raio;
  const Skeleton({super.key, this.largura, this.altura = 14, this.raio = 6});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.largura,
        height: widget.altura,
        decoration: BoxDecoration(
          color: cores.panel3,
          borderRadius: BorderRadius.circular(widget.raio),
        ),
      ),
    );
  }
}

/// Entrada suave: aparece subindo 10px com fade (efeito "rise" do mockup)
class EntradaSuave extends StatelessWidget {
  final Widget child;
  final int atrasoMs;
  const EntradaSuave({super.key, required this.child, this.atrasoMs = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + atrasoMs),
      curve: Interval(
        atrasoMs / (500 + atrasoMs),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (_, t, filho) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 10 * (1 - t)), child: filho),
      ),
      child: child,
    );
  }
}
