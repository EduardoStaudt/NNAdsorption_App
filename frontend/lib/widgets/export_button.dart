// export_button.dart — botão "Exportar" com dropdown CSV/XLSX
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

class ExportButton extends StatelessWidget {
  final bool habilitado;
  final void Function(String format) onExport;

  const ExportButton({super.key, required this.habilitado, required this.onExport});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return PopupMenuButton<String>(
      enabled: habilitado,
      tooltip: habilitado ? 'Exportar resultado' : 'Rode uma predicao primeiro',
      onSelected: onExport,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'csv', child: Text('CSV')),
        PopupMenuItem(value: 'xlsx', child: Text('XLSX')),
      ],
      // Visual do mockup: superfície panel3 que ganha borda accent no hover
      child: Hover(
        builder: (emHover) {
          final ativo = habilitado && emHover;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cores.panel3,
              border: Border.all(color: ativo ? cores.accent : cores.line2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download,
                  size: 16,
                  color: !habilitado
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
                    color: !habilitado
                        ? cores.text3
                        : ativo
                            ? cores.accent
                            : cores.text,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: habilitado ? cores.text2 : cores.text3,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
