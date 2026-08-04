// auth_comum.dart — peças compartilhadas por login e cadastro. As duas telas
// têm a mesma moldura (fundo da bancada + painel centrado) e os mesmos campos;
// só muda o título, a lista de campos e a ação.
import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

/// Moldura das telas de acesso: fundo pontilhado do app e um painel centrado
/// com largura de leitura. Rolável pra não estourar em tela baixa nem com o
/// teclado aberto.
class MolduraAuth extends StatelessWidget {
  final String titulo;
  final Widget child;

  const MolduraAuth({super.key, required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Scaffold(
      body: FundoPontilhado(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Espaco.xl),
            child: EntradaSuave(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Dim.larguraAuth),
                child: Painel(
                  padding: const EdgeInsets.all(Espaco.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        titulo,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: Tipo.valor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: cores.text,
                        ),
                      ),
                      const SizedBox(height: Espaco.lg),
                      child,
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

/// Campo de texto das telas de acesso. Só existe pra não repetir o mesmo
/// `TextFormField` quatro vezes — as bordas e a cor de erro vêm do tema.
class CampoAuth extends StatelessWidget {
  final TextEditingController controlador;
  final String rotulo;
  final String? Function(String?) validador;
  final bool senha;
  final Iterable<String>? autofill;
  final TextInputType? tipoTeclado;
  final TextInputAction acaoTeclado;
  final VoidCallback? onSubmit;

  const CampoAuth({
    super.key,
    required this.controlador,
    required this.rotulo,
    required this.validador,
    this.senha = false,
    this.autofill,
    this.tipoTeclado,
    this.acaoTeclado = TextInputAction.next,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (!senha) {
      return TextFormField(
        controller: controlador,
        validator: validador,
        keyboardType: tipoTeclado,
        autofillHints: autofill,
        textInputAction: acaoTeclado,
        onFieldSubmitted: (_) => onSubmit?.call(),
        style: TextStyle(
          fontFamily: 'IBMPlexSans',
          fontSize: Tipo.corpoGrande,
          color: context.cores.text,
        ),
        decoration: InputDecoration(labelText: rotulo),
      );
    }
    return _CampoSenha(
      controlador: controlador,
      rotulo: rotulo,
      validador: validador,
      autofill: autofill,
      acaoTeclado: acaoTeclado,
      onSubmit: onSubmit,
    );
  }
}

/// Senha com botão de mostrar/esconder — sem isso o usuário não tem como
/// conferir o que digitou antes de enviar.
class _CampoSenha extends StatefulWidget {
  final TextEditingController controlador;
  final String rotulo;
  final String? Function(String?) validador;
  final Iterable<String>? autofill;
  final TextInputAction acaoTeclado;
  final VoidCallback? onSubmit;

  const _CampoSenha({
    required this.controlador,
    required this.rotulo,
    required this.validador,
    required this.autofill,
    required this.acaoTeclado,
    required this.onSubmit,
  });

  @override
  State<_CampoSenha> createState() => _CampoSenhaState();
}

class _CampoSenhaState extends State<_CampoSenha> {
  bool _visivel = false;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return TextFormField(
      controller: widget.controlador,
      validator: widget.validador,
      obscureText: !_visivel,
      autofillHints: widget.autofill,
      textInputAction: widget.acaoTeclado,
      onFieldSubmitted: (_) => widget.onSubmit?.call(),
      style: TextStyle(
        fontFamily: 'IBMPlexSans',
        fontSize: Tipo.corpoGrande,
        color: cores.text,
      ),
      decoration: InputDecoration(
        labelText: widget.rotulo,
        suffixIcon: IconButton(
          tooltip: _visivel ? 'Esconder senha' : 'Mostrar senha',
          // Sem cor fixa: quem pinta é o iconButtonTheme (text2, âmbar no hover)
          icon: Icon(
            _visivel
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: Icone.m,
          ),
          onPressed: () => setState(() => _visivel = !_visivel),
        ),
      ),
    );
  }
}

/// Erro vindo do backend (email já cadastrado, senha errada). Ícone + texto,
/// nunca só cor — mesma linguagem do erro de campo do painel de parâmetros.
class ErroAuth extends StatelessWidget {
  final String texto;
  const ErroAuth({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: Espaco.cartao),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: Icone.pp, color: cores.erro),
            const SizedBox(width: Espaco.xs),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: Tipo.corpo,
                  height: 1.4,
                  color: cores.erro,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Link pra outra tela de acesso. Texto discreto que acende no hover — sem
/// âmbar, porque a ação principal da tela já é a do botão.
class LinkAuth extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  const LinkAuth({super.key, required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Hover(
      builder: (emHover) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Espaco.sm),
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: Tipo.corpo,
                color: emHover ? cores.text : cores.text2,
                decoration: emHover ? TextDecoration.underline : null,
                decorationColor: cores.text2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
