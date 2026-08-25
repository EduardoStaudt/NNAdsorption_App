// ui_comum.dart — widgets visuais pequenos reutilizados em várias telas
import 'dart:async' show Timer;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import '../theme/app_sizes.dart';
import '../theme/colors.dart';

/// Aviso flutuante no canto superior direito, na largura de um card de
/// parâmetro. Existe no lugar do `SnackBar`: aquele só nasce embaixo e no meio,
/// justamente onde moram os botões de ação — a mensagem tapava o que a pessoa
/// tinha acabado de clicar.
///
/// Um por vez: dois cliques seguidos empilhariam caixas em cima do gráfico, e
/// a segunda mensagem é sempre a que interessa. Daí o estado de módulo — é a
/// tela inteira que só tem um aviso, não cada widget.
OverlayEntry? _avisoEmTela;
Timer? _relogioAviso;

void mostrarAviso(BuildContext context, String mensagem) {
  final overlay = Overlay.of(context);
  fecharAviso();
  final entrada = OverlayEntry(builder: (_) => _Aviso(mensagem: mensagem));
  _avisoEmTela = entrada;
  overlay.insert(entrada);
  _relogioAviso = Timer(Duracao.aviso, fecharAviso);
}

void fecharAviso() {
  _relogioAviso?.cancel();
  _relogioAviso = null;
  _avisoEmTela?.remove();
  _avisoEmTela = null;
}

class _Aviso extends StatelessWidget {
  final String mensagem;
  const _Aviso({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Positioned(
      // Abaixo da topbar e no mesmo recuo da moldura da tela.
      top: Dim.alturaTopbar + Espaco.md,
      right: Espaco.md,
      child: Material(
        color: Colors.transparent,
        child: EntradaSuave(
          child: SizedBox(
            width: Dim.larguraCardParametros,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              // Toque em qualquer lugar dispensa — não vale prender a pessoa
              // esperando os 4 segundos.
              child: GestureDetector(
                onTap: fecharAviso,
                child: Container(
                  padding: const EdgeInsets.all(Espaco.campo),
                  decoration: BoxDecoration(
                    color: cores.panel2,
                    border: Border.all(color: cores.line2, width: Borda.fina),
                    borderRadius: BorderRadius.circular(Raio.controle),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: Icone.p,
                        color: cores.accentForte,
                      ),
                      const SizedBox(width: Espaco.sm),
                      Expanded(
                        child: Text(
                          mensagem,
                          style: TextStyle(
                            fontFamily: 'IBMPlexSans',
                            fontSize: Tipo.corpo,
                            height: 1.4,
                            color: cores.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
        border: Border.all(color: cores.line, width: Borda.fina),
        borderRadius: BorderRadius.circular(Raio.painel),
      ),
      child: child,
    );
  }
}

/// Fundo do app: grade de pontinhos 26x26 + brilho âmbar no topo (do mockup).
/// A grade fica estática; o brilho pode "respirar" lentamente onde faz sentido.
class FundoPontilhado extends StatefulWidget {
  final Widget child;

  /// `true` (padrão): preenche o pai — uso em tela cheia (Scaffold body).
  /// `false`: dimensiona pelo filho — necessário dentro de scroll, onde a
  /// altura é ilimitada e `StackFit.expand` estouraria (constraint infinita).
  final bool expandir;

  /// `true`: o brilho âmbar pulsa devagar (profundidade viva no hero).
  /// Sem cor nova — só intensidade/raio. Respeita "reduzir animações".
  final bool brilhoAnimado;

  const FundoPontilhado({
    super.key,
    required this.child,
    this.expandir = true,
    this.brilhoAnimado = false,
  });

  @override
  State<FundoPontilhado> createState() => _FundoPontilhadoState();
}

class _FundoPontilhadoState extends State<FundoPontilhado>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Só anima se pedido E o sistema não estiver com "reduzir animações"
    final animar =
        widget.brilhoAnimado && !MediaQuery.of(context).disableAnimations;
    if (animar && _ctrl == null) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 7),
      )..repeat(reverse: true);
    } else if (!animar && _ctrl != null) {
      _ctrl!.dispose();
      _ctrl = null;
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    // Pontos: estáticos e isolados em RepaintBoundary (nunca repintam)
    final pontos = RepaintBoundary(
      child: CustomPaint(
        painter: _PontosPainter(cores.text.withValues(alpha: 0.035)),
      ),
    );

    // Brilho: modula intensidade 0.8 → 1.2 quando animado, senão fixo em 1.0
    final ctrl = _ctrl;
    Widget brilho() => CustomPaint(
      painter: _BrilhoPainter(cor: cores.accent, intensidade: 1.0),
    );
    final camadaBrilho = ctrl == null
        ? brilho()
        : AnimatedBuilder(
            animation: ctrl,
            builder: (_, _) {
              final t = Curves.easeInOut.transform(ctrl.value);
              return CustomPaint(
                painter: _BrilhoPainter(
                  cor: cores.accent,
                  intensidade: 0.8 + 0.4 * t,
                ),
              );
            },
          );

    Widget camada(Widget filho) =>
        widget.expandir ? filho : Positioned.fill(child: filho);

    return Stack(
      fit: widget.expandir ? StackFit.expand : StackFit.loose,
      children: [
        camada(camadaBrilho), // brilho no fundo
        camada(pontos), // pontos sobre o brilho
        widget.child,
      ],
    );
  }
}

// Brilho radial âmbar no topo central — alpha e raio modulados por `intensidade`
class _BrilhoPainter extends CustomPainter {
  final Color cor;
  final double intensidade;
  _BrilhoPainter({required this.cor, this.intensidade = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = 0.06 * intensidade; // base um pouco mais pronunciada que a v1
    final w = 900.0 * (0.9 + 0.25 * intensidade);
    final h = 840.0 * (0.9 + 0.25 * intensidade);
    final p = Paint()
      ..shader =
          RadialGradient(
            colors: [
              cor.withValues(alpha: alpha),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCenter(
              center: Offset(size.width / 2, -120),
              width: w,
              height: h,
            ),
          );
    canvas.drawRect(Offset.zero & size, p);
  }

  @override
  bool shouldRepaint(_BrilhoPainter old) =>
      old.cor != cor || old.intensidade != intensidade;
}

class _PontosPainter extends CustomPainter {
  final Color corPonto;
  _PontosPainter(this.corPonto);

  @override
  void paint(Canvas canvas, Size size) {
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
  bool shouldRepaint(_PontosPainter old) => old.corPonto != corPonto;
}

/// Ação principal do sistema: âmbar com o Glow de Ação, levanta 1px no hover e
/// afunda no clique. Só use onde a ação roda de verdade — é a Regra do Âmbar
/// Raro que reserva essa cor. Botão desabilitado usa superfície neutra.
class BotaoPrimario extends StatelessWidget {
  final String texto;
  final IconData? icone;
  final bool carregando;
  final VoidCallback? onTap;

  const BotaoPrimario({
    super.key,
    required this.texto,
    this.icone,
    this.carregando = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final ativo = onTap != null && !carregando;

    return Semantics(
      button: true,
      enabled: ativo,
      label: texto,
      child: Hover(
        builder: (emHover) => EscalaAoClicar(
          child: MouseRegion(
            cursor: ativo ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: ativo ? onTap : null,
              child: AnimatedContainer(
                duration: Duracao.rapida,
                curve: Curves.easeOut,
                height: Dim.alturaBotaoPrimario,
                transform: Matrix4.translationValues(
                  0,
                  emHover && ativo ? -1 : 0,
                  0,
                ),
                decoration: BoxDecoration(
                  color: ativo
                      ? cores.accent
                      : cores.accent.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(Raio.controle),
                  boxShadow: [
                    BoxShadow(
                      color: cores.accent.withValues(
                        alpha: emHover && ativo ? 0.5 : 0.35,
                      ),
                      blurRadius: emHover && ativo ? 26 : 22,
                      offset: const Offset(0, 6),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: Center(
                  child: carregando
                      ? SizedBox(
                          width: Icone.m,
                          height: Icone.m,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cores.onAccent,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icone != null) ...[
                              Icon(icone, size: Icone.m, color: cores.onAccent),
                              const SizedBox(width: Espaco.xs),
                            ],
                            // Idem `BotaoContorno`: o rótulo cede antes de a
                            // linha estourar, porque o mesmo botão aparece em
                            // colunas de largura bem diferente.
                            Flexible(
                              child: Text(
                                texto,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'IBMPlexSans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: Tipo.corpoGrande,
                                  color: cores.onAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ação secundária: transparente com borda, esclarece no hover. É o contraponto
/// do `BotaoPrimario` — nada de âmbar aqui, senão a Regra do Âmbar Raro se
/// perde. Sem `icone` é só o rótulo centrado.
class BotaoContorno extends StatelessWidget {
  final String texto;
  final IconData? icone;
  final double altura;
  final VoidCallback onTap;

  const BotaoContorno({
    super.key,
    required this.texto,
    required this.onTap,
    this.icone,
    this.altura = Dim.alturaBotaoSecundario,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Hover(
      builder: (emHover) => EscalaAoClicar(
        child: GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: Duracao.rapida,
              height: altura,
              decoration: BoxDecoration(
                border: Border.all(
                  color: emHover ? cores.text2 : cores.line2,
                  width: Borda.fina,
                ),
                borderRadius: BorderRadius.circular(Raio.controle),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icone != null) ...[
                      // Ícone no degrau menor: nas duas colunas estreitas do
                      // painel flat, 16px comem a letra final do rótulo.
                      Icon(
                        icone,
                        size: Icone.pp,
                        color: emHover ? cores.text : cores.text2,
                      ),
                      const SizedBox(width: Espaco.xxs),
                    ],
                    // Flexível porque o mesmo botão serve a coluna de 352px e a
                    // de 200px: onde não couber, corta com reticências em vez
                    // de estourar a linha.
                    Flexible(
                      child: Text(
                        texto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'IBMPlexSans',
                          fontWeight: FontWeight.w600,
                          fontSize: Tipo.corpo,
                          color: emHover ? cores.text : cores.text2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
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
  const CabecalhoSecao({
    super.key,
    required this.eyebrow,
    required this.titulo,
  });

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
          style: TextStyle(
            fontFamily: 'Archivo',
            fontSize: Tipo.tituloGrande,
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

/// Afunda levemente o filho enquanto pressionado (feedback tátil).
/// Os defaults preservam o comportamento da plataforma; a landing passa
/// uma escala menor e uma curva com leve "spring-back" no retorno.
class EscalaAoClicar extends StatefulWidget {
  final Widget child;
  final double escala; // escala enquanto pressionado
  final Duration duracao;
  final Curve curva;
  const EscalaAoClicar({
    super.key,
    required this.child,
    this.escala = 0.98,
    this.duracao = const Duration(milliseconds: 120),
    this.curva = Curves.easeOut,
  });

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
        scale: _pressionado ? widget.escala : 1.0,
        duration: widget.duracao,
        curve: widget.curva,
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
      opacity: Tween(
        begin: 0.45,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
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
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - t)),
          child: filho,
        ),
      ),
      child: child,
    );
  }
}

/// Ícone de alternar a barra lateral, no desenho que virou convenção (o
/// `panel-left`). A moldura é a mesma nos dois estados — é a janela — e a
/// divisória é o próprio painel:
///
/// - **Aberto:** a divisória vertical fina perto da borda esquerda mostra o
///   painel ocupando a sua faixa. É o desenho clássico de recolher/expandir
///   sidebar.
/// - **Fechado:** só a moldura, lisa. O painel recolheu até zero, então não há
///   faixa nenhuma pra separar.
///
/// Desenhado à mão porque nenhum ícone do Material chega perto:
/// `view_sidebar_outlined` põe a divisória à direita e dois blocos dentro,
/// `vertical_split` tem linhas de conteúdo, `crop_16_9` não tem divisória.
class IconePainelEsquerdo extends StatelessWidget {
  final bool aberto;
  final Color cor;
  final double tamanho;

  const IconePainelEsquerdo({
    super.key,
    required this.aberto,
    required this.cor,
    this.tamanho = Icone.m,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(tamanho),
      painter: _PainelEsquerdoPainter(aberto: aberto, cor: cor),
    );
  }
}

class _PainelEsquerdoPainter extends CustomPainter {
  final bool aberto;
  final Color cor;
  _PainelEsquerdoPainter({required this.aberto, required this.cor});

  @override
  void paint(Canvas canvas, Size size) {
    final traco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..color = cor;

    // Quase quadrado, como a janela que ele representa. A moldura é a mesma
    // nos dois estados; a divisória é o que aparece e some.
    final moldura = RRect.fromRectAndRadius(
      Rect.fromLTWH(1.25, 1.75, size.width - 2.5, size.height - 3.5),
      const Radius.circular(3),
    );
    canvas.drawRRect(moldura, traco);

    // Fechado: só a janela, lisa — o painel recolheu e não há faixa a separar.
    if (!aberto) return;

    final divisao = moldura.left + moldura.width * 0.33;
    canvas.drawLine(
      Offset(divisao, moldura.top),
      Offset(divisao, moldura.bottom),
      traco,
    );
  }

  @override
  bool shouldRepaint(_PainelEsquerdoPainter old) =>
      old.aberto != aberto || old.cor != cor;
}
