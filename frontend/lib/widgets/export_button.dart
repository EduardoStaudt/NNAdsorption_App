// export_button.dart — botão "Exportar" com dropdown CSV/XLSX
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

class ExportButton extends StatefulWidget {
  final bool habilitado;
  final void Function(String format) onExport;

  const ExportButton({super.key, required this.habilitado, required this.onExport});

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
      alignmentOffset: const Offset(0, -1),
      // Menu como extensão do botão: mesma superfície/borda, cantos de baixo
      // arredondados e de cima retos (o topo se junta à base reta do botão).
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(cores.panel2),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(4),
        shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.3)),
        // Sem padding horizontal: o menu tem exatamente a largura do SizedBox
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            side: BorderSide(color: cores.line2),
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
              _itemExport(context, 'csv', 'CSV', Icons.description_outlined),
              _itemExport(context, 'xlsx', 'XLSX', Icons.grid_on_outlined),
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
                    ? () =>
                        controller.isOpen ? controller.close() : controller.open()
                    : null,
                child: AnimatedContainer(
                  key: _chaveBotao,
                  duration: const Duration(milliseconds: 150),
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: cores.panel3,
                    border: Border.all(color: ativo ? cores.accent : cores.line2),
                    // Base reta quando aberto pra se juntar ao topo do menu
                    borderRadius: aberto
                        ? const BorderRadius.vertical(top: Radius.circular(10))
                        : BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download,
                        size: 16,
                        color: !widget.habilitado
                            ? cores.text3
                            : ativo
                                ? cores.accent
                                : cores.text,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Exportar',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !widget.habilitado
                              ? cores.text3
                              : ativo
                                  ? cores.accent
                                  : cores.text,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
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
      BuildContext context, String format, String label, IconData icone) {
    final cores = context.cores;
    return MenuItemButton(
      onPressed: () => widget.onExport(format),
      leadingIcon: Icon(icone, size: 16),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) ? cores.accent : cores.text,
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) ? cores.accent : cores.text2,
        ),
        overlayColor:
            WidgetStatePropertyAll(cores.accent.withValues(alpha: 0.12)),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        // Sem largura mínima fixa: o item acompanha a largura travada do menu
        minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        ),
      ),
      child: Text(label),
    );
  }
}
