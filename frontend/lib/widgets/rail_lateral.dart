// rail_lateral.dart — trilho de ícones colado na borda esquerda, no formato do
// VS Code: altura inteira da área de trabalho, sem margem, sem canto de card.
//
// O trilho só reporta intenção: quem decide o que abrir é a tela. Ele também
// avisa qual item está sob o cursor (`onEspiar`), pra quem desenha o layout
// mostrar a prévia por cima do conteúdo — o trilho é estreito demais pra
// hospedar essa prévia sozinho.
import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

/// Um ícone do trilho que controla um painel.
class ItemRail {
  final IconData icone;
  final String dica;
  final bool ativo;
  final bool habilitado;
  final VoidCallback onTap;

  /// Tratamento de ação, não de aba: fundo e borda âmbar em vez de só o
  /// desenho. Reservado ao que leva pra fora do app.
  final bool destaque;

  const ItemRail({
    required this.icone,
    required this.dica,
    required this.ativo,
    required this.onTap,
    this.habilitado = true,
    this.destaque = false,
  });
}

class RailLateral extends StatelessWidget {
  /// Itens agrupados no topo — as abas de painel.
  final List<ItemRail> itens;

  /// Item preso no rodapé, separado dos de cima. Sai do fluxo do grupo porque
  /// não é da mesma natureza: leva o resultado pra fora em vez de trocar o que
  /// está na tela.
  final ItemRail? rodape;

  /// Índice do item sob o cursor, ou null. A tela usa pra desenhar a prévia.
  /// O rodapé é o índice logo depois dos de cima.
  final void Function(int? indice) onEspiar;

  const RailLateral({
    super.key,
    required this.itens,
    required this.onEspiar,
    this.rodape,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Container(
      width: Dim.larguraRail,
      // Encostado na borda: só um fio separando do conteúdo, sem raio nem
      // sombra. Não é um card flutuando, é a parede da esquerda.
      decoration: BoxDecoration(
        color: cores.panel,
        border: Border(
          right: BorderSide(color: cores.line, width: Borda.fina),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: Espaco.sm),
          // O alternar não mora aqui: comanda a janela toda, então fica na
          // quina superior esquerda, antes da marca (ver `Topbar`).
          for (final (i, item) in itens.indexed) _monta(item, i),
          if (rodape != null) ...[
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Espaco.sm,
                vertical: Espaco.xs,
              ),
              child: Divider(height: Borda.fina, color: cores.line),
            ),
            _monta(rodape!, itens.length),
            const SizedBox(height: Espaco.sm),
          ],
        ],
      ),
    );
  }

  Widget _monta(ItemRail item, int indice) => _IconeRail(
    icone: item.icone,
    dica: item.dica,
    ativo: item.ativo,
    habilitado: item.habilitado,
    destaque: item.destaque,
    onTap: item.onTap,
    // Espiar só faz sentido no que não está aberto: não se espia o que já
    // está à vista. Vale mesmo desabilitado — é ali que a prévia explica
    // por que o ícone não responde.
    onHover: (dentro) => onEspiar(dentro && !item.ativo ? indice : null),
  );
}

/// Ícone do trilho. Aceso em âmbar quando ativo (estado de seleção, um dos usos
/// que o DESIGN.md reserva pro âmbar) e sob o cursor. O item ativo ganha um
/// traço vertical na borda, como o do VS Code.
class _IconeRail extends StatefulWidget {
  final IconData icone;
  final String dica;
  final bool ativo;
  final bool habilitado;
  final bool destaque;
  final VoidCallback onTap;

  /// Avisado nos eventos de ponteiro — nunca durante o build, senão o
  /// `setState` de quem escuta cairia no meio da montagem da árvore.
  final void Function(bool dentro)? onHover;

  const _IconeRail({
    required this.icone,
    required this.dica,
    required this.ativo,
    required this.onTap,
    this.habilitado = true,
    this.destaque = false,
    this.onHover,
  });

  @override
  State<_IconeRail> createState() => _IconeRailState();
}

class _IconeRailState extends State<_IconeRail> {
  bool _emHover = false;

  void _mudouHover(bool dentro) {
    if (_emHover == dentro) return;
    setState(() => _emHover = dentro);
    // Também quando desabilitado: a prévia é justamente onde o usuário
    // descobre por que o ícone não responde.
    widget.onHover?.call(dentro);
  }

  /// Item de ação: em vez de só o desenho acender, ele tem superfície própria.
  /// Sem nada pra exportar fica neutro — âmbar em estado inerte seria ruído,
  /// e a prévia do hover é que explica o porquê.
  Widget _marcaDestaque(AppColors cores) {
    final ligado = widget.habilitado;
    final forte = ligado && (widget.ativo || _emHover);

    return AnimatedContainer(
      duration: Duracao.rapida,
      width: Dim.itemRail - Espaco.sm,
      height: Dim.itemRail - Espaco.sm,
      decoration: BoxDecoration(
        color: !ligado
            ? Colors.transparent
            : forte
            ? cores.accent
            : cores.accent.withValues(alpha: 0.12),
        border: Border.all(
          color: ligado ? cores.accent : cores.line2,
          width: Borda.fina,
        ),
        borderRadius: BorderRadius.circular(Raio.controle),
      ),
      child: Icon(
        widget.icone,
        size: Icone.m,
        color: !ligado
            ? cores.text3
            : forte
            ? cores.onAccent
            : cores.accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final aceso = widget.habilitado && (widget.ativo || _emHover);

    return Tooltip(
      message: widget.dica,
      child: Semantics(
        button: true,
        label: widget.dica,
        selected: widget.ativo,
        enabled: widget.habilitado,
        child: MouseRegion(
          onEnter: (_) => _mudouHover(true),
          onExit: (_) => _mudouHover(false),
          cursor: widget.habilitado
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: widget.habilitado ? widget.onTap : null,
            child: SizedBox(
              width: Dim.larguraRail,
              height: Dim.itemRail,
              child: Stack(
                children: [
                  // Traço de seleção rente à borda esquerda
                  if (widget.ativo)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: Borda.foco,
                        height: Dim.itemRail - Espaco.md,
                        color: cores.accent,
                      ),
                    ),
                  Center(
                    child: widget.destaque
                        ? _marcaDestaque(cores)
                        : Icon(
                            widget.icone,
                            size: Icone.m,
                            color: !widget.habilitado
                                ? cores.text3
                                : aceso
                                ? cores.accent
                                : cores.text2,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Prévia que aparece ao passar o mouse num ícone do trilho: uma versão curta
/// do painel, só pra lembrar o que tem lá dentro. Não recebe clique — some ao
/// tirar o mouse, e quem quiser mexer clica no ícone.
///
/// Tamanho fixo de propósito: os três painéis têm conteúdos de alturas bem
/// diferentes e, sem travar, a caixa mudaria de tamanho a cada ícone. O que
/// não couber é cortado — é prévia, não o painel.
class PeekPainel extends StatelessWidget {
  final String titulo;
  final Widget child;

  const PeekPainel({super.key, required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return IgnorePointer(
      child: SizedBox(
        width: Dim.larguraPeek,
        height: Dim.alturaPeek,
        child: Painel(
          padding: const EdgeInsets.all(Espaco.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontFamily: 'Archivo',
                  fontSize: Tipo.titulo,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: cores.text,
                ),
              ),
              const SizedBox(height: Espaco.sm),
              // ClipRect + OverflowBox: o conteúdo se monta na altura que
              // quiser e a prévia mostra só o topo, sem estourar layout.
              Expanded(
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    maxHeight: double.infinity,
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Linha simples de prévia, pra quando o painel não tem conteúdo estruturado
/// (ou está vazio).
class PeekLinha extends StatelessWidget {
  final String texto;
  const PeekLinha(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Espaco.xxs),
      child: Text(
        texto,
        style: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: Tipo.label,
          height: 1.5,
          color: context.cores.text2,
        ),
      ),
    );
  }
}
