// topbar.dart — barra superior inspirada no mockup: logo + status + tema + avatar
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

// A `AppBar` embrulha as `actions` num `IconButtonTheme` dela, mais perto que o
// do app — por isso o véu do Material voltava a aparecer só aqui (um disco
// cinza no tema claro). Zerar no próprio botão é o único ponto que ela não
// sobrescreve.
const _semVeuDeMaterial = ButtonStyle(
  overlayColor: WidgetStatePropertyAll(Colors.transparent),
);

// Gradiente âmbar (tons do accent) — mesmo do hover do "Começar agora".
const _gradAccent = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFE6D23C), Color(0xFFD4C014)],
);

class Topbar extends StatelessWidget implements PreferredSizeWidget {
  /// Estado do painel lateral. `null` = a tela não tem trilho (tablet, mobile),
  /// e aí o botão de alternar nem aparece.
  final bool? painelAberto;
  final VoidCallback? onAlternarPainel;

  const Topbar({super.key, this.painelAberto, this.onAlternarPainel});

  @override
  Size get preferredSize => const Size.fromHeight(Dim.alturaTopbar);

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final aberto = painelAberto;

    final comTrilho = aberto != null && onAlternarPainel != null;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: Dim.alturaTopbar,
      // Sem recuo padrão quando há trilho: o botão ocupa uma faixa da largura
      // exata do trilho, então o centro dele cai no mesmo eixo X dos ícones
      // logo abaixo. Sem trilho, volta ao recuo normal do AppBar.
      titleSpacing: comTrilho ? 0 : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(Borda.fina),
        child: Divider(height: Borda.fina, color: cores.line),
      ),
      // Alternar antes da marca: é o controle da janela toda, não de um
      // conteúdo específico, então fica na quina superior esquerda.
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (comTrilho)
            SizedBox(
              width: Dim.larguraRail,
              child: Center(
                child: _BotaoAlternarPainel(
                  aberto: aberto,
                  onTap: onAlternarPainel!,
                ),
              ),
            ),
          const _LogoBadge(),
        ],
      ),
      actions: const [_AcoesTopbar(naLanding: false)],
    );
  }
}

/// Alterna o painel lateral. Fora do trilho porque comanda a janela inteira.
class _BotaoAlternarPainel extends StatelessWidget {
  final bool aberto;
  final VoidCallback onTap;

  const _BotaoAlternarPainel({required this.aberto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Tooltip(
      message: aberto ? 'Fechar o painel' : 'Abrir o painel',
      // O botão fica no eixo X do trilho, então o balão caía por cima do
      // primeiro ícone. A margem empurra a área permitida pra depois do trilho.
      margin: const EdgeInsets.only(left: Dim.larguraRail + Espaco.sm),
      child: Semantics(
        button: true,
        label: aberto ? 'Fechar o painel' : 'Abrir o painel',
        child: Hover(
          builder: (emHover) => MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              key: const ValueKey('alternar-painel'),
              onTap: onTap,
              child: SizedBox(
                width: Dim.itemRail,
                height: Dim.itemRail,
                child: Center(
                  child: IconePainelEsquerdo(
                    aberto: aberto,
                    cor: emHover ? cores.accentForte : cores.text2,
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

/// Conteúdo da barra sem o "chrome" do AppBar — logo à esquerda, ações à
/// direita. Reusado pelo header de vidro flutuante da landing.
class TopbarConteudo extends StatelessWidget {
  const TopbarConteudo({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: Dim.alturaTopbar,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Espaco.cartao),
        child: Row(children: [_LogoBadge(), Spacer(), _AcoesTopbar()]),
      ),
    );
  }
}

/// Logo (troca por tema) + badge de versão em mono
class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().modoEscuro;
    final cores = context.cores;
    // Em telas estreitas esconde o badge pra não sobrepor
    final estreito = MediaQuery.of(context).size.width < 560;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo — mostra a versão correta para cada tema
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180, maxHeight: 40),
              child: Image.asset(
                isDark
                    ? 'assets/images/logo_dark.png'
                    : 'assets/images/logo_light.png',
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        ),
        if (!estreito) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: cores.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'v1.0',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 11,
                color: cores.text3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Ações da direita: alternar tema e, na landing, o botão de abrir a
/// ferramenta. Sem contas, não há avatar nem sessão pra mostrar aqui.
class _AcoesTopbar extends StatelessWidget {
  /// O botão de entrar é chamada de ação da landing. Dentro da plataforma a
  /// pessoa já está onde ele levaria.
  final bool naLanding;
  const _AcoesTopbar({this.naLanding = true});

  @override
  Widget build(BuildContext context) {
    final temaProvider = context.watch<ThemeProvider>();
    final isDark = temaProvider.modoEscuro;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 4),

        // Alternar tema
        IconButton(
          tooltip: isDark ? 'Modo claro' : 'Modo escuro',
          icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round),
          onPressed: temaProvider.alternar,
          style: _semVeuDeMaterial,
        ),

        if (naLanding) const _BotaoEntrar(),

        const SizedBox(width: 8),
      ],
    );
  }
}

// Botão "Entrar" com o mesmo hover do "Começar agora": fundo transparente →
// gradiente âmbar + glow, tudo animando junto (200ms, sem defasagem). Texto
// acompanha o fundo (normal → quase-preto sobre o âmbar). Adaptado ao header.
class _BotaoEntrar extends StatelessWidget {
  const _BotaoEntrar();

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Hover(
      builder: (emHover) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go('/login'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              // transparente → gradiente âmbar (crossfade junto com o glow)
              gradient: emHover
                  ? _gradAccent
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.transparent, Colors.transparent],
                    ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: cores.accent.withValues(alpha: emHover ? 0.4 : 0.0),
                  blurRadius: emHover ? 16 : 0,
                  spreadRadius: emHover ? 1 : 0,
                ),
              ],
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: emHover ? cores.onAccent : cores.text,
              ),
              child: const Text('Entrar'),
            ),
          ),
        ),
      ),
    );
  }
}
