// main.dart — entrada do app: providers, tema e roteamento
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/landing_screen.dart';
import 'screens/platform_screen.dart';
import 'theme/app_theme.dart';

// Transição entre telas: fade + deslize sutil de baixo pra cima
CustomTransitionPage<void> _paginaSuave(GoRouterState state, Widget tela) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: tela,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (_, animacao, _, child) {
      final curva = CurvedAnimation(
        parent: animacao,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curva,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curva),
          child: child,
        ),
      );
    },
  );
}

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const NNAdsorptionApp(),
    ),
  );
}

class NNAdsorptionApp extends StatefulWidget {
  const NNAdsorptionApp({super.key});

  @override
  State<NNAdsorptionApp> createState() => _NNAdsorptionAppState();
}

class _NNAdsorptionAppState extends State<NNAdsorptionApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    // Restaura a preferência de tema salva no navegador.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ThemeProvider>().inicializar();
    });

    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (_, s) => _paginaSuave(s, const LandingScreen()),
        ),
        GoRoute(
          path: '/app',
          pageBuilder: (_, s) => _paginaSuave(s, const PlatformScreen()),
        ),
      ],
      redirect: (context, state) {
        // Não há mais conta: `/app` é público. As duas rotas de sessão viram
        // atalho pra ferramenta — os links da landing continuam valendo, e
        // quem tiver `/login` nos favoritos cai no lugar certo.
        final loc = state.matchedLocation;
        if (loc == '/login' || loc == '/register') return '/app';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final temaProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'NNAdsorption',
      debugShowCheckedModeBanner: false,
      theme: temaClaro(),
      darkTheme: temaEscuro(),
      themeMode: temaProvider.modo,
      routerConfig: _router,
    );
  }
}
