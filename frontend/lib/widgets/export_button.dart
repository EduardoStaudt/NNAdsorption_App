// export_button.dart — botão "Exportar" com dropdown CSV/XLSX
import 'package:flutter/material.dart';
import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

/// Formatos oferecidos, na ordem. Fonte única pro menu do botão e pro painel
/// do trilho — se um formato novo entrar, os dois ganham juntos.
const kFormatosExport = [
  (formato: 'csv', rotulo: 'CSV', icone: Icons.description_outlined),
  (formato: 'xlsx', rotulo: 'XLSX', icone: Icons.grid_on_outlined),
];

class ExportButton extends StatefulWidget {
  final bool habilitado;
  final void Function(String format) onExport;

  const ExportButton({
    super.key,
    required this.habilitado,
    required this.onExport,
  });

  @override
  State<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<ExportButton> {
  final _chaveBotao = GlobalKey();
  double? _larguraBotao; // medida do botão → largura exata do menu

  void _medirBotao() {
    final ctx = _chaveBotao.currentContext;
    if (ctx == null) return;
    final w = (ctx.findRenderObject() as RenderBox).size.width;
    if (w != _larguraBotao) setState(() => _larguraBotao = w);
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    // Mede o botão após o layout pra o menu casar exatamente com a largura dele
    WidgetsBinding.instance.addPostFrameCallback((_) => _medirBotao());

    return MenuAnchor(
      // Cola o menu no botão (sobrepõe 1px pra as bordas virarem uma linha só)
      alignmentOffset: const Offset(0, -Borda.fina),
      // Menu como extensão do botão: mesma superfície/borda, cantos de baixo
      // arredondados e de cima retos (o topo se junta à base reta do botão).
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(cores.panel2),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(4),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: 0.3),
        ),
        // Sem padding horizontal: o menu tem exatamente a largura do SizedBox
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: Espaco.xs),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(Raio.controle),
            ),
            side: BorderSide(color: cores.line2, width: Borda.fina),
          ),
        ),
      ),
      menuChildren: [
        // Largura travada = largura do botão (mesmas bordas esq./dir.)
        SizedBox(
          width: _larguraBotao,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in kFormatosExport)
                _itemExport(context, f.formato, f.rotulo, f.icone),
            ],
          ),
        ),
      ],
      builder: (context, controller, _) {
        return Hover(
          builder: (emHover) {
            // Destaque accent SÓ no hover real — independe do menu estar aberto
            final ativo = widget.habilitado && emHover;
            final aberto = controller.isOpen;
            return MouseRegion(
              cursor: widget.habilitado
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: GestureDetector(
                onTap: widget.habilitado
                    ? () => controller.isOpen
                          ? controller.close()
                          : controller.open()
                    : null,
                child: AnimatedContainer(
                  key: _chaveBotao,
                  duration: Duracao.rapida,
                  height: Dim.alturaBotaoCompacto,
                  padding: const EdgeInsets.symmetric(horizontal: Espaco.md),
                  decoration: BoxDecoration(
                    color: cores.panel3,
                    border: Border.all(
                      color: ativo ? cores.accent : cores.line2,
                      width: Borda.fina,
                    ),
                    // Base reta quando aberto pra se juntar ao topo do menu
                    borderRadius: aberto
                        ? const BorderRadius.vertical(
                            top: Radius.circular(Raio.controle),
                          )
                        : BorderRadius.circular(Raio.controle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    // Numa metade de linha o botão recebe largura de fora, e aí
                    // o `min` não vale mais: sem isto o conteúdo encosta na
                    // esquerda e sobra um vão à direita.
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download,
                        size: Icone.p,
                        color: !widget.habilitado
                            ? cores.text3
                            : ativo
                            ? cores.accent
                            : cores.text,
                      ),
                      const SizedBox(width: Espaco.sm),
                      // Flexível porque o botão também vive numa metade de
                      // linha, ao lado do "Resetar valores": lá a largura vem
                      // de fora e o rótulo tem que ceder antes de estourar.
                      Flexible(
                        child: Text(
                          'Exportar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'IBMPlexSans',
                            fontSize: Tipo.corpo,
                            fontWeight: FontWeight.w600,
                            color: !widget.habilitado
                                ? cores.text3
                                : ativo
                                ? cores.accent
                                : cores.text,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: Icone.m,
                        color: widget.habilitado ? cores.text2 : cores.text3,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Item do menu — hover accent (texto + ícone + tint de fundo)
  Widget _itemExport(
    BuildContext context,
    String format,
    String label,
    IconData icone,
  ) {
    final cores = context.cores;
    return MenuItemButton(
      onPressed: () => widget.onExport(format),
      leadingIcon: Icon(icone, size: Icone.p),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) ? cores.accent : cores.text,
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) ? cores.accent : cores.text2,
        ),
        overlayColor: WidgetStatePropertyAll(
          cores.accent.withValues(alpha: 0.12),
        ),
        textStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: Tipo.corpo,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Sem largura mínima fixa: o item acompanha a largura travada do menu
        minimumSize: const WidgetStatePropertyAll(Size(0, Dim.alturaItemMenu)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: Espaco.md, vertical: Espaco.xxs),
        ),
      ),
      child: Text(label),
    );
  }
}
