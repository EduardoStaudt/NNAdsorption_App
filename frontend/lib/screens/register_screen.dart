// register_screen.dart — tela de cadastro
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_sizes.dart';
import '../widgets/auth_comum.dart';
import '../widgets/ui_comum.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaSenhaCtrl = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaSenhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _erro = null);

    try {
      await context.read<AuthProvider>().registrar(
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
      titulo: 'Criar conta',
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
              autofill: const [AutofillHints.newPassword],
              validador: (v) {
                // Mesmas regras do backend: 8+ chars, 1 letra e 1 número
                if (v == null || v.length < 8) {
                  return 'Senha deve ter pelo menos 8 caracteres';
                }
                if (!v.contains(RegExp(r'[A-Za-z]')) ||
                    !v.contains(RegExp(r'\d'))) {
                  return 'Senha deve ter pelo menos 1 letra e 1 número';
                }
                return null;
              },
            ),
            const SizedBox(height: Espaco.md),

            CampoAuth(
              controlador: _confirmaSenhaCtrl,
              rotulo: 'Confirmar senha',
              senha: true,
              autofill: const [AutofillHints.newPassword],
              acaoTeclado: TextInputAction.done,
              onSubmit: _cadastrar,
              validador: (v) {
                if (v != _senhaCtrl.text) return 'As senhas não coincidem';
                return null;
              },
            ),

            if (_erro != null) ErroAuth(texto: _erro!),

            const SizedBox(height: Espaco.lg),
            BotaoPrimario(
              texto: 'Criar conta',
              carregando: carregando,
              onTap: _cadastrar,
            ),

            const SizedBox(height: Espaco.xs),
            LinkAuth(
              texto: 'Já tem conta? Entrar',
              onTap: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
