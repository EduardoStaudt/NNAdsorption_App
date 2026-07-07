// landing_screen.dart — página inicial pública
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/colors.dart';
import '../widgets/topbar.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Topbar(),
      body: SingleChildScrollView(
        child: Column(
          children: const [
            _SecaoHero(),
            _SecaoFeatures(),
            _SecaoMotivacao(),
            _SecaoAgradecimentos(),
            _SecaoFaq(),
            _Footer(),
          ],
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
    final isDark = context.watch<ThemeProvider>().modoEscuro;
    final largura = MediaQuery.of(context).size.width;
    // Em telas pequenas o hero fica centralizado e com fonte menor
    final mobile = largura < 800;
    final tamanhoTitulo = mobile ? 42.0 : 64.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 24 : largura * 0.15,
        vertical: mobile ? 56 : 80,
      ),
      child: Column(
        crossAxisAlignment:
            mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            'Otimize',
            textAlign: mobile ? TextAlign.center : TextAlign.start,
            style: GoogleFonts.archivo(
              fontSize: tamanhoTitulo,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          ShaderMask(
            // Gradiente da marca: accent do tema → verde do Hero.png
            shaderCallback: (bounds) => LinearGradient(
              colors: [context.cores.accent, const Color(0xFF5CB85C)],
            ).createShader(bounds),
            child: Text(
              'suas operações',
              textAlign: mobile ? TextAlign.center : TextAlign.start,
              style: GoogleFonts.archivo(
                fontSize: tamanhoTitulo,
                fontWeight: FontWeight.w900,
                color: Colors.white, // ShaderMask sobrescreve a cor
              ),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Sua plataforma de previsões de comportamento de colunas de '
              'adsorção em leito fixo a partir de modelos neurais.',
              textAlign: mobile ? TextAlign.center : TextAlign.start,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
            ),
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(
              // Botão escuro nos dois temas: panel2 no escuro, texto no claro
              backgroundColor: isDark ? context.cores.panel2 : context.cores.text,
              foregroundColor: Colors.white,
              // padding generoso garante área de toque > 44px
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            child: const Text('Começar agora'),
          ),
        ],
      ),
    );
  }
}

// --- Seção "No que vamos te ajudar" ---
class _SecaoFeatures extends StatelessWidget {
  const _SecaoFeatures();

  static const _cards = [
    ('📈', 'Predições instantâneas', 'Resultados em segundos a partir dos 22 parâmetros da sua coluna.'),
    ('📊', 'Visualização clara', 'Perfis de concentração, adsorção e temperatura ao longo do leito + curva de breakthrough.'),
    ('💾', 'Exportação pronta', 'Baixe resultados em CSV ou XLSX direto da plataforma.'),
    ('🕓', 'Histórico salvo', 'Acompanhe todas as predições feitas com sua conta.'),
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
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: _cards
                    .map((c) => _FeatureCard(emoji: c.$1, titulo: c.$2, descricao: c.$3))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String descricao;
  const _FeatureCard({required this.emoji, required this.titulo, required this.descricao});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 240,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 12),
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Text(descricao, style: const TextStyle(fontSize: 13, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Seção Motivação ---
class _SecaoMotivacao extends StatelessWidget {
  const _SecaoMotivacao();

  @override
  Widget build(BuildContext context) {
    return _SecaoPlaceholder(titulo: 'Nossa Motivação');
  }
}

// --- Seção Agradecimentos ---
class _SecaoAgradecimentos extends StatelessWidget {
  const _SecaoAgradecimentos();

  @override
  Widget build(BuildContext context) {
    return _SecaoPlaceholder(titulo: 'Agradecimentos', corAlternada: true);
  }
}

class _SecaoPlaceholder extends StatelessWidget {
  final String titulo;
  final bool corAlternada;
  const _SecaoPlaceholder({required this.titulo, this.corAlternada = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: corAlternada ? Theme.of(context).colorScheme.surface : null,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 16),
          Text('Em breve.', style: TextStyle(fontSize: 15, color: context.cores.text2)),
        ],
      ),
    );
  }
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(pergunta, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(resposta, style: const TextStyle(fontSize: 14, height: 1.6)),
          ),
        ],
      ),
    );
  }
}

// --- Footer ---
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          // Wrap em vez de Row — quebra linha em telas estreitas
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            children: [
              Text(
                'NNAdsorption',
                style: GoogleFonts.archivo(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const TextButton(onPressed: null, child: Text('Termos de Uso')),
              const TextButton(onPressed: null, child: Text('Sobre')),
              const TextButton(onPressed: null, child: Text('Fale Conosco')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Projeto de Iniciação Científica — UTFPR Santa Helena',
            style: TextStyle(fontSize: 12, color: context.cores.text3),
          ),
        ],
      ),
    );
  }
}
