// landing_screen.dart — página inicial pública
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/colors.dart';
import '../widgets/hero_animacao.dart';
import '../widgets/topbar.dart';
import '../widgets/ui_comum.dart';

// Gradiente da marca (tons do accent) — usado no hover do botão "Começar agora".
const _gradienteAccent = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFE6D23C), Color(0xFFD4C014)],
);

// Gradiente do título "suas operações": só tons de amarelo/âmbar, mas com
// contraste forte de luminosidade (claro em cima → dourado profundo embaixo),
// pra ser nítido à distância. Diagonal acompanha o peso da Archivo 900.
const _gradienteTitulo = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFFF4C7), Color(0xFFE6D23C), Color(0xFF8B6F00)],
  stops: [0.0, 0.5, 1.0],
);

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scroll = ScrollController();
  bool _rolou = false; // saiu do topo → header vira vidro

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_aoRolar);
  }

  // Só reconstrói quando cruza o limiar — não a cada pixel rolado
  void _aoRolar() {
    final rolou = _scroll.hasClients && _scroll.offset > 8;
    if (rolou != _rolou) setState(() => _rolou = rolou);
  }

  @override
  void dispose() {
    _scroll.removeListener(_aoRolar);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topo = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(
        children: [
          // Conteúdo rolável — o header fixo sobrepõe o topo (o hero reserva
          // esse espaço no próprio padding). O footer é a última seção do fluxo.
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: EdgeInsets.only(top: topo),
              child: const Column(
                children: [
                  _SecaoHero(),
                  _SecaoFeatures(),
                  _SecaoCta(),
                  _SecaoFaq(),
                  _Footer(),
                ],
              ),
            ),
          ),
          // Header de vidro — rente no topo; vira pill flutuante ao rolar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _BarraFlutuante(
              // Vidro ao sair do topo; encaixado rente quando em scroll=0
              vidro: _rolou,
              ancoradaNoTopo: true,
              child: const TopbarConteudo(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra fixa (header/footer) que transiciona suave entre dois estados:
/// rente à borda + sólida (scroll=0) → pill de vidro flutuante (rolando).
/// Um único `t` (0→1) dirige padding, raio, blur, cor, borda e sombra.
class _BarraFlutuante extends StatelessWidget {
  final bool vidro; // true: pill de vidro flutuante · false: encaixada rente
  final bool ancoradaNoTopo; // define o lado da sombra (pra baixo/pra cima)
  final Widget child;

  const _BarraFlutuante({
    required this.vidro,
    required this.ancoradaNoTopo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: vidro ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, t, filho) {
        final cores = context.cores;
        final raio = BorderRadius.circular(16 * t);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 12 * t, vertical: 8 * t),
          child: ClipRRect(
            borderRadius: raio,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14 * t, sigmaY: 14 * t),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // sólida em repouso → ~68% translúcida ao flutuar (mais vidro)
                  color: Color.lerp(cores.bg, cores.bg.withValues(alpha: 0.68), t),
                  borderRadius: raio,
                  border: Border.all(color: cores.line.withValues(alpha: t)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15 * t),
                      blurRadius: 24 * t,
                      offset: Offset(0, (ancoradaNoTopo ? 8 : -8) * t),
                      spreadRadius: -6 * t,
                    ),
                  ],
                ),
                child: filho,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

// Botão primário da landing — compartilhado entre o hero e a seção de CTA
// final, pra manter um único estilo de ação principal.
class _BotaoComecar extends StatelessWidget {
  const _BotaoComecar();

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final isDark = context.watch<ThemeProvider>().modoEscuro;
    final corSolida = isDark ? cores.panel2 : cores.text;
    // Altura fixa 52, largura pelo conteúdo, StadiumBorder. Hover: crossfade
    // (200ms) sólido→gradiente + glow juntos. Clique: afunda 0.97 spring-back.
    return SizedBox(
      height: 52,
      child: Hover(
        builder: (emHover) => EscalaAoClicar(
          escala: 0.97,
          duracao: const Duration(milliseconds: 180),
          curva: Curves.easeOutBack,
          child: AnimatedScale(
            scale: emHover ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                // Sempre gradiente (repouso: escuro→escuro) → o AnimatedContainer
                // cruza gradiente↔gradiente E o glow juntos: transição única.
                gradient: emHover
                    ? _gradienteAccent
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [corSolida, corSolida],
                      ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: cores.accent.withValues(alpha: emHover ? 0.5 : 0.0),
                    blurRadius: emHover ? 30 : 0,
                    spreadRadius: emHover ? 1 : 0,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => context.go('/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  overlayColor: Colors.white.withValues(alpha: 0.08),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: const StadiumBorder(),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: emHover ? cores.onAccent : Colors.white,
                  ),
                  child: const Text('Começar agora'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Botão secundário: mesma altura (52), padding (24) e radius (26) do primário,
// largura pelo conteúdo. Ghost: borda line → accent no hover + leve elevação.
class _BotaoSecundario extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  const _BotaoSecundario({required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return SizedBox(
      height: 52,
      child: Hover(
        builder: (emHover) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onPressed,
            child: AnimatedScale(
              scale: emHover ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: cores.panel,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: emHover ? cores.accent.withValues(alpha: 0.7) : cores.line,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: emHover ? 0.18 : 0.0),
                      blurRadius: emHover ? 22 : 0,
                      offset: Offset(0, emHover ? 10 : 0),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                // Center(widthFactor: 1): centraliza vertical SEM expandir largura
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    texto,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cores.text,
                    ),
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

// --- Hero ---
class _SecaoHero extends StatelessWidget {
  const _SecaoHero();

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final largura = MediaQuery.of(context).size.width;
    // Em telas pequenas o hero fica centralizado e com fonte menor
    final mobile = largura < 800;
    final tamanhoTitulo = mobile ? 42.0 : 64.0;
    final alinhamento = mobile ? TextAlign.center : TextAlign.start;
    // Gutter proporcional no desktop, com piso e teto (ver adapt)
    final padH = mobile ? 24.0 : (largura * 0.15).clamp(48.0, 260.0);
    // Respeita "reduzir animações" do sistema: sem stagger, conteúdo já visível
    final semAnimacao = MediaQuery.of(context).disableAnimations;

    // Cada bloco entra subindo com um pequeno atraso encadeado (title →
    // subtítulo → CTA). Sob reduced-motion, renderiza direto no estado final.
    Widget entrada(int atrasoMs, Widget filho) =>
        semAnimacao ? filho : EntradaSuave(atrasoMs: atrasoMs, child: filho);

    final titulo = Column(
      crossAxisAlignment:
          mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Otimize',
          textAlign: alinhamento,
          style: GoogleFonts.archivo(
            fontSize: tamanhoTitulo,
            fontWeight: FontWeight.w900,
            height: 1.05,
            color: cores.text,
          ),
        ),
        // "suas operações" com gradiente da marca dentro do texto. O ShaderMask
        // cobre só a caixa reportada do glifo; com a altura de linha justa, os
        // descendentes (p, ç, g) ficavam FORA da máscara e apareciam brancos.
        // O padding inferior estende a caixa (e o Rect do gradiente) abaixo dos
        // descendentes, cobrindo-os com folga.
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => _gradienteTitulo.createShader(bounds),
          child: Padding(
            padding: EdgeInsets.only(bottom: tamanhoTitulo * 0.22),
            child: Text(
              'suas operações',
              textAlign: alinhamento,
              style: GoogleFonts.archivo(
                fontSize: tamanhoTitulo,
                fontWeight: FontWeight.w900,
                height: 1.05,
                color: Colors.white, // srcIn faz o gradiente preencher o texto
              ),
            ),
          ),
        ),
      ],
    );

    // Coluna de textos (mantém os staggers de entrada)
    final textos = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        entrada(0, titulo),
        // Menor pra compensar o padding inferior do título (descendentes)
        const SizedBox(height: 10),
        entrada(
          120,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Sua plataforma de previsões de comportamento de colunas de '
              'adsorção em leito fixo a partir de modelos neurais.',
              textAlign: alinhamento,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 36),
        entrada(220, const _BotaoComecar()),
      ],
    );

    // Janela de sistema com a animação do hero (entra depois do CTA)
    final janela = entrada(
      300,
      const AspectRatio(aspectRatio: 1.5, child: HeroAnimacao()),
    );

    // Desktop: texto à esquerda, janela à direita. Mobile: empilhado.
    final conteudo = mobile
        ? Column(children: [textos, const SizedBox(height: 48), janela])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 6, child: textos),
              const SizedBox(width: 48),
              Expanded(flex: 5, child: janela),
            ],
          );

    return FundoPontilhado(
      // Dentro do SingleChildScrollView a altura é ilimitada: dimensiona pelo filho
      expandir: false,
      // Brilho âmbar respira devagar — profundidade viva sem cor nova
      brilhoAnimado: true,
      child: Container(
        width: double.infinity,
        // Topo generoso pra limpar o header fixo (que sobrepõe esta faixa)
        padding: EdgeInsets.fromLTRB(
          padH,
          mobile ? 96 : 112,
          padH,
          mobile ? 56 : 80,
        ),
        child: conteudo,
      ),
    );
  }
}

// --- Seção "No que vamos te ajudar" ---
class _SecaoFeatures extends StatelessWidget {
  const _SecaoFeatures();

  // Ícones do Material (mesmo vocabulário da plataforma) — nada de emoji.
  static const _cards = [
    (Icons.bolt_outlined, 'Predições instantâneas', 'Resultados em segundos a partir dos 22 parâmetros da sua coluna.'),
    (Icons.insights_outlined, 'Visualização clara', 'Perfis de concentração, adsorção e temperatura ao longo do leito + curva de breakthrough.'),
    (Icons.download_outlined, 'Exportação pronta', 'Baixe resultados em CSV ou XLSX direto da plataforma.'),
    (Icons.history_outlined, 'Histórico salvo', 'Acompanhe todas as predições feitas com sua conta.'),
  ];

  @override
  Widget build(BuildContext context) {
    // Sem cor de fundo na section — evita a "ilha" cinza
    // Container com largura total, conteudo limitado a 1100px e centralizado
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                'No que vamos te ajudar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 40),
              // Grade responsiva com altura uniforme por linha: IntrinsicHeight +
              // Expanded fazem todos os cards de uma linha igualarem o mais alto.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LayoutBuilder(
                  builder: (context, restricoes) {
                    final cols = restricoes.maxWidth >= 860
                        ? 4
                        : restricoes.maxWidth >= 560
                            ? 2
                            : 1;
                    const gap = 20.0;
                    // Largura FIXA por card (não Expanded): assim o IntrinsicHeight
                    // calcula a altura do texto na largura real de cada card e
                    // todos ficam uniformes sem estourar (o texto mais longo não
                    // quebra uma linha a mais do que o previsto).
                    final cardW =
                        ((restricoes.maxWidth - gap * (cols - 1)) / cols)
                            .floorToDouble();
                    final linhas = <Widget>[];
                    for (var i = 0; i < _cards.length; i += cols) {
                      final fim =
                          (i + cols < _cards.length) ? i + cols : _cards.length;
                      final slice = _cards.sublist(i, fim);
                      linhas.add(
                        IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var j = 0; j < cols; j++) ...[
                                if (j > 0) const SizedBox(width: gap),
                                SizedBox(
                                  width: cardW,
                                  child: j < slice.length
                                      ? _FeatureCard(
                                          icone: slice[j].$1,
                                          titulo: slice[j].$2,
                                          descricao: slice[j].$3,
                                        )
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (var k = 0; k < linhas.length; k++) ...[
                          if (k > 0) const SizedBox(height: gap),
                          linhas[k],
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;
  const _FeatureCard({required this.icone, required this.titulo, required this.descricao});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    // Plano por padrão; no hover: sobe (sombra), borda vira accent sutil e
    // escala 1.02 — mesmo padrão do FAQ e dos cards originais.
    return Hover(
      builder: (emHover) => AnimatedScale(
        scale: emHover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cores.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: emHover ? cores.accent.withValues(alpha: 0.7) : cores.line,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: emHover ? 0.18 : 0.0),
                blurRadius: emHover ? 22 : 0,
                offset: Offset(0, emHover ? 10 : 0),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge circular sutil — dá peso visual ao ícone, alinhado ao título
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cores.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, size: 22, color: cores.accent),
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                style: GoogleFonts.archivo(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.2,
                  color: cores.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                descricao,
                style: TextStyle(fontSize: 13, height: 1.5, color: cores.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Borda arredondada que "acende" em âmbar na direção do cursor: sobre a linha
// base, uma borda accent com shader radial centrado no cursor (forte perto,
// fraca longe). `t` controla o fade de entrada/saída.
class _BordaSpotlight extends CustomPainter {
  final Color corBase;
  final Color corAccent;
  final Alignment foco;
  final double t;
  final double raio;

  _BordaSpotlight({
    required this.corBase,
    required this.corAccent,
    required this.foco,
    required this.t,
    required this.raio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      Radius.circular(raio - 1),
    );

    // Borda base (line) sempre visível — mantém o "plano por padrão"
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = corBase;
    canvas.drawRRect(rrect, base);

    if (t <= 0.001) return;

    // Borda accent com gradiente radial no cursor
    final centro = Offset(
      (foco.x * 0.5 + 0.5) * size.width,
      (foco.y * 0.5 + 0.5) * size.height,
    );
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = RadialGradient(
        colors: [
          corAccent.withValues(alpha: 0.9 * t),
          corAccent.withValues(alpha: 0.12 * t),
        ],
      ).createShader(Rect.fromCircle(center: centro, radius: size.longestSide));
    canvas.drawRRect(rrect, accent);
  }

  @override
  bool shouldRepaint(_BordaSpotlight old) =>
      old.t != t ||
      old.foco != foco ||
      old.corBase != corBase ||
      old.corAccent != corAccent ||
      old.raio != raio;
}

// --- Seção FAQ ---
class _SecaoFaq extends StatelessWidget {
  const _SecaoFaq();

  static const _perguntas = [
    (
      'Como funciona?',
      'A plataforma usa uma rede neural treinada com dados reais de colunas de adsorção. '
          'Você informa os 22 parâmetros da sua coluna e recebe os perfis de concentração, '
          'adsorção, temperatura e a curva de breakthrough em segundos.',
    ),
    (
      'O que é adsorção em leito fixo?',
      'É um processo onde um fluido passa por uma coluna preenchida com material sólido '
          'adsorvente, que retém determinados componentes do fluido. Amplamente usado em '
          'purificação de gases, tratamento de água e separação industrial.',
    ),
    (
      'Preciso pagar?',
      'Não. A plataforma é um projeto de pesquisa da UTFPR Santa Helena e está disponível '
          'gratuitamente para fins acadêmicos e científicos.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          Text('Perguntas Frequentes', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: _perguntas
                  .map((faq) => _FaqItem(pergunta: faq.$1, resposta: faq.$2))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String pergunta;
  final String resposta;
  const _FaqItem({required this.pergunta, required this.resposta});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    // Mesmo tato dos cards de features: hover → borda accent sutil + elevação.
    return Hover(
      builder: (emHover) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias, // clipa o splash do ExpansionTile aos cantos
        decoration: BoxDecoration(
          color: cores.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: emHover ? cores.accent.withValues(alpha: 0.7) : cores.line,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: emHover ? 0.16 : 0.0),
              blurRadius: emHover ? 20 : 0,
              offset: Offset(0, emHover ? 8 : 0),
              spreadRadius: -8,
            ),
          ],
        ),
        child: ExpansionTile(
          // Sem as bordas/divisores padrão do ExpansionTile — a borda é do container
          shape: const Border(),
          collapsedShape: const Border(),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          // Mais respiro vertical (~20%) e texto com mais entrelinha
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Text(pergunta, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          children: [
            Text(resposta, style: const TextStyle(fontSize: 14, height: 1.7)),
          ],
        ),
      ),
    );
  }
}

// --- Seção de CTA final: reforça a conversão antes do rodapé ---
class _SecaoCta extends StatelessWidget {
  const _SecaoCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: const _CtaCard(),
        ),
      ),
    );
  }
}

// Card do CTA com efeito spotlight/magnético: um glow radial âmbar segue o
// cursor, o conteúdo desloca sutilmente na direção dele e a borda acende mais
// forte no lado mais próximo. ValueNotifier + AnimatedBuilder evitam reconstruir
// a árvore a cada onHover. Mantém a aura âmbar de fundo (peso de "seção final").
class _CtaCard extends StatefulWidget {
  const _CtaCard();

  @override
  State<_CtaCard> createState() => _CtaCardState();
}

class _CtaCardState extends State<_CtaCard> {
  final _pos = ValueNotifier<Offset>(Offset.zero);
  final _dentro = ValueNotifier<bool>(false);
  late final Listenable _merge = Listenable.merge([_pos, _dentro]);
  Size _tamanho = Size.zero; // tamanho do card (lido no hover, sem LayoutBuilder)

  @override
  void dispose() {
    _pos.dispose();
    _dentro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    // Conteúdo estático — passado como `child`, nunca reconstruído no hover.
    final conteudo = Column(
      children: [
        Text(
          'Comece a prever agora',
          textAlign: TextAlign.center,
          style: GoogleFonts.archivo(
            fontWeight: FontWeight.w800,
            fontSize: 32,
            letterSpacing: -0.5,
            color: cores.text,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(
            'Crie sua conta gratuita e rode sua primeira predição em segundos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.5, color: cores.text2),
          ),
        ),
        const SizedBox(height: 28),
        // Row (mainAxisSize.min): os dois botões lado a lado, largura pelo conteúdo
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BotaoComecar(),
            const SizedBox(width: 12),
            _BotaoSecundario(
              texto: 'Já tenho conta',
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      ],
    );

    void atualiza(Offset local) {
      _tamanho = context.size ?? Size.zero;
      _pos.value = local;
    }

    return MouseRegion(
      onEnter: (e) {
        atualiza(e.localPosition);
        _dentro.value = true;
      },
      onHover: (e) => atualiza(e.localPosition),
      onExit: (_) => _dentro.value = false,
      child: AnimatedBuilder(
        animation: _merge,
        child: conteudo,
        builder: (context, child) {
          final size = _tamanho;
          final dx = size.width > 0
              ? ((_pos.value.dx / size.width) * 2 - 1).clamp(-1.0, 1.0)
              : 0.0;
          final dy = size.height > 0
              ? ((_pos.value.dy / size.height) * 2 - 1).clamp(-1.0, 1.0)
              : 0.0;
          final foco = Alignment(dx, dy);
          final desloc = Offset(dx * 4, dy * 4); // magnético: até 4px

          return TweenAnimationBuilder<double>(
            tween: Tween(end: _dentro.value ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: child,
            builder: (context, t, child) {
              return CustomPaint(
                foregroundPainter: _BordaSpotlight(
                  corBase: cores.line,
                  corAccent: cores.accent,
                  foco: foco,
                  t: t,
                  raio: 24,
                ),
                child: DecoratedBox(
                  // Sem aura estática: fundo neutro em repouso. O único glow é o
                  // spotlight reativo (abaixo), que só aparece com o mouse em cima.
                  decoration: BoxDecoration(
                    color: cores.panel,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Spotlight radial âmbar seguindo o cursor (sutil)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: foco,
                                  radius: 0.8,
                                  colors: [
                                    cores.accent.withValues(alpha: 0.12 * t),
                                    cores.accent.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.7],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Conteúdo com deslocamento magnético (eased via t)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 56,
                            horizontal: 40,
                          ),
                          child: Transform.translate(
                            offset: desloc * t,
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- Footer: faixa full-width, fixa no fim do conteúdo ---
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final isDark = context.watch<ThemeProvider>().modoEscuro;
    // Empilha (centralizado) em telas estreitas; lado a lado no desktop
    final estreito = MediaQuery.of(context).size.width < 640;

    // Wordmark — mesmo logo do header (troca por tema)
    final wordmark = Image.asset(
      isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo_light.png',
      height: 30,
      fit: BoxFit.contain,
    );

    // Texto do logo usa `currentColor`: branco no escuro, preto original no
    // claro. Os quadrados amarelos (#F6C212) ficam inalterados nos dois temas.
    final logoUtfpr = SvgPicture.asset(
      'assets/images/UTFPR_logo.svg',
      height: 34,
      theme: SvgTheme(
        currentColor: isDark ? Colors.white : const Color(0xFF231F20),
      ),
      semanticsLabel: 'UTFPR',
    );

    final Widget conteudo = estreito
        ? Column(
            children: [
              wordmark,
              const SizedBox(height: 24),
              logoUtfpr,
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              wordmark,
              logoUtfpr,
            ],
          );

    return Column(
      children: [
        // Gradiente SÓ na borda superior: fundo da página → superfície do rodapé
        Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [cores.bg, cores.panel2],
            ),
          ),
        ),
        // Corpo: cor sólida única (sem gradiente interno)
        Container(
          width: double.infinity,
          color: cores.panel2,
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 44),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: conteudo,
            ),
          ),
        ),
      ],
    );
  }
}
