// topbar.dart — barra superior inspirada no mockup: logo + status + tema + avatar
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/colors.dart';

class Topbar extends StatelessWidget implements PreferredSizeWidget {
  const Topbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final temaProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = temaProvider.modoEscuro;
    final cores = context.cores;
    // Em telas estreitas esconde o badge e o texto de status pra não sobrepor
    final estreito = MediaQuery.of(context).size.width < 560;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: cores.line),
      ),
      title: Row(
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
            // Badge de versão em mono
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: cores.line),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'v1.0',
                style: GoogleFonts.ibmPlexMono(fontSize: 11, color: cores.text3),
              ),
            ),
          ],
        ],
      ),
      actions: [
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
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Entrar'),
          ),

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
              style: GoogleFonts.ibmPlexMono(
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
