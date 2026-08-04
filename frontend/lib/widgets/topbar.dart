// topbar.dart — barra superior inspirada no mockup: logo + status + tema + avatar
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

// Gradiente âmbar (tons do accent) — mesmo do hover do "Começar agora".
const _gradAccent = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFE6D23C), Color(0xFFD4C014)],
);

class Topbar extends StatelessWidget implements PreferredSizeWidget {
  const Topbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(Dim.alturaTopbar);

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: Dim.alturaTopbar,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(Borda.fina),
        child: Divider(height: Borda.fina, color: cores.line),
      ),
      title: const _LogoBadge(),
      actions: const [_AcoesTopbar()],
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
        child: Row(
          children: [
            _LogoBadge(),
            Spacer(),
            _AcoesTopbar(),
          ],
        ),
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
              style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: cores.text3),
            ),
          ),
        ],
      ],
    );
  }
}

/// Ações da direita: status, alternar tema, avatar/login
class _AcoesTopbar extends StatelessWidget {
  const _AcoesTopbar();

  @override
  Widget build(BuildContext context) {
    final temaProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = temaProvider.modoEscuro;
    final estreito = MediaQuery.of(context).size.width < 560;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indicador de status (bolinha pulsante)
        if (authProvider.logado) _StatusDot(comTexto: !estreito),
        const SizedBox(width: 4),

        // Alternar tema
        IconButton(
          tooltip: isDark ? 'Modo claro' : 'Modo escuro',
          icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round),
          onPressed: temaProvider.alternar,
        ),

        // Avatar / login
        if (authProvider.logado)
          _AvatarMenu(email: authProvider.user!.email)
        else
          const _BotaoEntrar(),

        const SizedBox(width: 8),
      ],
    );
  }
}

// Bolinha pulsante — mostra que o backend está conectado
class _StatusDot extends StatefulWidget {
  final bool comTexto; // esconde o "CONECTADO" em telas estreitas
  const _StatusDot({this.comTexto = true});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: cores.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cores.accent.withValues(alpha: (1 - _ctrl.value) * 0.5),
                    blurRadius: 4 + _ctrl.value * 8,
                    spreadRadius: _ctrl.value * 4,
                  ),
                ],
              ),
            ),
          ),
          if (widget.comTexto) ...[
            const SizedBox(width: 6),
            Text(
              'CONECTADO',
              style: TextStyle(fontFamily: 'IBMPlexMono',
                fontSize: 10,
                letterSpacing: 0.5,
                color: cores.text2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarMenu extends StatelessWidget {
  final String email;
  const _AvatarMenu({required this.email});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return PopupMenuButton<String>(
      tooltip: 'Conta',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: cores.accent,
          child: Text(
            email[0].toUpperCase(),
            style: TextStyle(
              color: cores.onAccent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
      onSelected: (valor) async {
        if (valor == 'logout') {
          await context.read<AuthProvider>().sair();
          if (context.mounted) context.go('/');
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(email, style: const TextStyle(fontSize: 12)),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'logout', child: Text('Sair')),
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
              style: TextStyle(fontFamily: 'IBMPlexSans',
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
