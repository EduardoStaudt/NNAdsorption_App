// menu_acoes_drawer.dart — menu lateral do desktop: reúne num só lugar as três
// ações que antes eram botões soltos no cabeçalho dos resultados.
//
// Cada item só fecha o menu e chama de volta quem sabe agir; nenhuma ação muda
// de comportamento aqui, só de ponto de entrada. Exportar é a exceção de forma:
// precisa de um formato antes de agir, então abre CSV/XLSX no próprio item em
// vez de fechar o menu pra mostrar outro menu.
import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

class MenuAcoesDrawer extends StatelessWidget {
  /// Estado atual do painel de parâmetros — muda só a dica do item.
  final bool parametrosAbertos;
  final VoidCallback onAlternarParametros;
  final VoidCallback onAbrirHistorico;

  /// Falso quando não há predição em tela: o item fica inerte e diz por quê.
  final bool podeExportar;
  final void Function(String formato) onExportar;

  const MenuAcoesDrawer({
    super.key,
    required this.parametrosAbertos,
    required this.onAlternarParametros,
    required this.onAbrirHistorico,
    required this.podeExportar,
    required this.onExportar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Drawer(
      width: Dim.larguraDrawerMenu,
      backgroundColor: cores.panel,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                Espaco.lg,
                Espaco.md,
                Espaco.lg,
                Espaco.sm,
              ),
              child: CabecalhoSecao(eyebrow: 'Menu', titulo: 'Acoes'),
            ),
            Divider(height: Borda.fina, color: cores.line),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Espaco.md),
                children: [
                  _ItemMenu(
                    icone: Icons.tune,
                    titulo: 'Parametros',
                    dica: parametrosAbertos
                        ? 'Recolher o painel'
                        : 'Mostrar o painel',
                    onTap: () {
                      Navigator.of(context).pop();
                      onAlternarParametros();
                    },
                  ),
                  const SizedBox(height: Espaco.sm),
                  _ItemMenu(
                    icone: Icons.history,
                    titulo: 'Historico',
                    dica: 'Predicoes salvas na sua conta',
                    onTap: () {
                      Navigator.of(context).pop();
                      onAbrirHistorico();
                    },
                  ),
                  const SizedBox(height: Espaco.sm),
                  _ItemExportar(
                    habilitado: podeExportar,
                    onExportar: (formato) {
                      Navigator.of(context).pop();
                      onExportar(formato);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha do menu. Mesmo tato do item de histórico: só a borda acende em âmbar
/// no hover — sem levantar, porque item de lista que dispara ação não é card.
class _ItemMenu extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String dica;
  final VoidCallback? onTap;
  final Widget? extra;

  const _ItemMenu({
    required this.icone,
    required this.titulo,
    required this.dica,
    required this.onTap,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final ativo = onTap != null;

    return Semantics(
      button: true,
      enabled: ativo,
      label: titulo,
      child: Hover(
        builder: (emHover) {
          final aceso = emHover && ativo;
          return MouseRegion(
            cursor: ativo ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: Duracao.rapida,
                padding: const EdgeInsets.symmetric(
                  horizontal: Espaco.cartao,
                  vertical: Espaco.cartao,
                ),
                decoration: BoxDecoration(
                  color: cores.panel2,
                  border: Border.all(
                    width: Borda.fina,
                    color: aceso
                        ? cores.accent.withValues(alpha: Elevacao.bordaHover)
                        : cores.line,
                  ),
                  borderRadius: BorderRadius.circular(Raio.cartao),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icone,
                          size: Icone.m,
                          color: ativo
                              ? (aceso ? cores.accent : cores.text2)
                              : cores.text3,
                        ),
                        const SizedBox(width: Espaco.cartao),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titulo,
                                style: TextStyle(
                                  fontFamily: 'IBMPlexSans',
                                  fontSize: Tipo.corpoGrande,
                                  fontWeight: FontWeight.w600,
                                  color: ativo ? cores.text : cores.text3,
                                ),
                              ),
                              Text(
                                dica,
                                style: TextStyle(
                                  fontFamily: 'IBMPlexSans',
                                  fontSize: Tipo.label,
                                  height: 1.4,
                                  color: cores.text3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ?extra,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Exportar precisa de um formato, então abre CSV/XLSX dentro do próprio item.
class _ItemExportar extends StatefulWidget {
  final bool habilitado;
  final void Function(String formato) onExportar;

  const _ItemExportar({required this.habilitado, required this.onExportar});

  @override
  State<_ItemExportar> createState() => _ItemExportarState();
}

class _ItemExportarState extends State<_ItemExportar> {
  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return _ItemMenu(
      icone: Icons.download,
      titulo: 'Exportar',
      dica: widget.habilitado
          ? 'Baixar a predicao em tela'
          : 'Abra uma predicao no historico primeiro',
      onTap: widget.habilitado
          ? () => setState(() => _aberto = !_aberto)
          : null,
      extra: AnimatedCrossFade(
        duration: Duracao.media,
        sizeCurve: Curves.easeInOut,
        crossFadeState: _aberto && widget.habilitado
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstChild: const SizedBox(width: double.infinity),
        secondChild: Padding(
          padding: const EdgeInsets.only(top: Espaco.cartao),
          child: Column(
            children: [
              Divider(height: Borda.fina, color: cores.line),
              for (final (formato, rotulo) in const [
                ('csv', 'CSV'),
                ('xlsx', 'XLSX'),
              ])
                _LinhaFormato(
                  rotulo: rotulo,
                  onTap: () => widget.onExportar(formato),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinhaFormato extends StatelessWidget {
  final String rotulo;
  final VoidCallback onTap;
  const _LinhaFormato({required this.rotulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Hover(
      builder: (emHover) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            color: Colors.transparent, // garante área de toque na linha toda
            padding: const EdgeInsets.symmetric(vertical: Espaco.sm),
            child: Text(
              rotulo,
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: Tipo.corpo,
                fontWeight: FontWeight.w500,
                color: emHover ? cores.accent : cores.text2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
