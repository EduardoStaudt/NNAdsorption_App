// login_screen.dart — tela de login
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_sizes.dart';
import '../widgets/auth_comum.dart';
import '../widgets/ui_comum.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _erro = null);

    try {
      await context.read<AuthProvider>().entrar(
        _emailCtrl.text.trim(),
        _senhaCtrl.text,
      );
      if (mounted) context.go('/app');
    } catch (e) {
      setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final carregando = context.watch<AuthProvider>().carregando;

    return MolduraAuth(
      titulo: 'Entrar',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoAuth(
              controlador: _emailCtrl,
              rotulo: 'Email',
              tipoTeclado: TextInputType.emailAddress,
              autofill: const [AutofillHints.email],
              validador: (v) {
                if (v == null || v.isEmpty) return 'Informe o email';
                if (!v.contains('@')) return 'Email inválido';
                return null;
              },
            ),
            const SizedBox(height: Espaco.md),

            CampoAuth(
              controlador: _senhaCtrl,
              rotulo: 'Senha',
              senha: true,
              autofill: const [AutofillHints.password],
              acaoTeclado: TextInputAction.done,
              onSubmit: _entrar,
              validador: (v) {
                if (v == null || v.length < 8) {
                  return 'Senha deve ter pelo menos 8 caracteres';
                }
                return null;
              },
            ),

            if (_erro != null) ErroAuth(texto: _erro!),

            const SizedBox(height: Espaco.lg),
            BotaoPrimario(
              texto: 'Entrar',
              carregando: carregando,
              onTap: _entrar,
            ),

            const SizedBox(height: Espaco.xs),
            LinkAuth(
              texto: 'Não tem conta? Cadastre-se',
              onTap: () => context.go('/register'),
            ),
          ],
        ),
      ),
    );
  }
}
