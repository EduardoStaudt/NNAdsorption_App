// rail_lateral.dart — trilho de ícones colado na borda esquerda, no formato do
// VS Code: altura inteira da área de trabalho, sem margem, sem canto de card.
//
// O trilho só reporta intenção: quem decide o que abrir é a tela. Ele também
// avisa qual item está sob o cursor (`onEspiar`), pra quem desenha o layout
// mostrar a prévia por cima do conteúdo — o trilho é estreito demais pra
// hospedar essa prévia sozinho. Nem todo item quer isso: ver `flutuante`.
import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

/// Um ícone do trilho que controla um painel.
class ItemRail {
  final IconData icone;

  /// Nome do painel. Sempre vai pro leitor de tela; só vira tooltip visível se
  /// `flutuante` deixar.
  final String rotulo;
  final bool ativo;
  final bool habilitado;
  final VoidCallback onTap;

  /// Se o hover pode fazer algo aparecer por cima da tela — tooltip ou prévia.
  /// `false` deixa o ícone mudo: passar o mouse só o acende.
  final bool flutuante;

  const ItemRail({
    required this.icone,
    required this.rotulo,
    required this.ativo,
    required this.onTap,
    this.habilitado = true,
    this.flutuante = true,
  });
}

class RailLateral extends StatelessWidget {
  /// Itens agrupados no topo — as abas de painel.
  final List<ItemRail> itens;

  /// Índice do item sob o cursor, ou null. A tela usa pra desenhar a prévia.
  final void Function(int? indice) onEspiar;

  const RailLateral({super.key, required this.itens, required this.onEspiar});

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
        ],
      ),
    );
  }

  Widget _monta(ItemRail item, int indice) => _IconeRail(
    icone: item.icone,
    rotulo: item.rotulo,
    // Tooltip só no item ativo. No item fechado quem explica é a prévia, que
    // nasce do mesmo hover — os dois juntos se atropelavam, com o balão caindo
    // em cima do que a prévia acabara de mostrar.
    comDica: item.flutuante && item.ativo,
    ativo: item.ativo,
    habilitado: item.habilitado,
    onTap: item.onTap,
    // Espiar só faz sentido no que não está aberto: não se espia o que já está
    // à vista.
    onHover: item.flutuante
        ? (dentro) => onEspiar(dentro && !item.ativo ? indice : null)
        : null,
  );
}

/// Ícone do trilho. Aceso em âmbar quando ativo (estado de seleção, um dos usos
/// que o DESIGN.md reserva pro âmbar) e sob o cursor. O item ativo ganha um
/// traço vertical na borda, como o do VS Code.
class _IconeRail extends StatefulWidget {
  final IconData icone;
  final String rotulo;
  final bool comDica;
  final bool ativo;
  final bool habilitado;
  final VoidCallback onTap;

  /// Avisado nos eventos de ponteiro — nunca durante o build, senão o
  /// `setState` de quem escuta cairia no meio da montagem da árvore.
  final void Function(bool dentro)? onHover;

  const _IconeRail({
    required this.icone,
    required this.rotulo,
    required this.comDica,
    required this.ativo,
    required this.onTap,
    this.habilitado = true,
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
    widget.onHover?.call(dentro);
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final aceso = widget.habilitado && (widget.ativo || _emHover);

    // Quem decide se cabe tooltip é o trilho; aqui só se obedece. O rótulo vai
    // pro `Semantics` de qualquer jeito — sem ele o ícone ficaria sem nome.
    final conteudo = Semantics(
      button: true,
      label: widget.rotulo,
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
                  child: Icon(
                    widget.icone,
                    size: Icone.m,
                    // `accentForte`: o ícone é desenho fino, e o âmbar de
                    // sinal sobre o painel claro não se lê. O traço de
                    // seleção ao lado continua no âmbar cheio.
                    color: !widget.habilitado
                        ? cores.text3
                        : aceso
                        ? cores.accentForte
                        : cores.text2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // Sem tooltip o `Tooltip` nem entra na árvore: um `message: ''` continuaria
    // registrando o gesto e abrindo um balão vazio.
    return widget.comDica
        ? Tooltip(message: widget.rotulo, child: conteudo)
        : conteudo;
  }
}

/// Prévia que aparece ao passar o mouse num ícone do trilho: uma versão curta
/// do painel, só pra lembrar o que tem lá dentro. Não recebe clique — some ao
/// tirar o mouse, e quem quiser mexer clica no ícone.
///
/// Tamanho fixo de propósito: o conteúdo varia de altura (o histórico não tem
/// limite de itens) e, sem travar, a caixa mudaria de tamanho conforme o que
/// coubesse dentro. O que passar é cortado — é prévia, não o painel.
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
