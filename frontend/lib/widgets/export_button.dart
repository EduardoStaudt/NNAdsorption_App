// export_button.dart — botão "Exportar" da predição em tela.
//
// Já foi um dropdown de formatos. Hoje o formato é uma das perguntas do modal
// de exportação, junto com o que levar — o botão só abre a caixa.
import 'package:flutter/material.dart';
import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

/// Formatos oferecidos, na ordem. Fonte única pro modal de exportação e pro de
/// lote — se um formato novo entrar, os dois ganham juntos.
const kFormatosExport = [
  (formato: 'csv', rotulo: 'CSV', icone: Icons.description_outlined),
  (formato: 'xlsx', rotulo: 'XLSX', icone: Icons.grid_on_outlined),
];

class ExportButton extends StatelessWidget {
  /// Falso sem predição em tela: não há o que exportar, e o botão apaga.
  final bool habilitado;
  final VoidCallback onExport;

  const ExportButton({
    super.key,
    required this.habilitado,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Hover(
      builder: (emHoverCru) {
        // Destaque âmbar só no hover real, e só quando há o que exportar.
        final ativo = habilitado && emHoverCru;
        return MouseRegion(
          cursor: habilitado
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: habilitado ? onExport : null,
            child: AnimatedContainer(
              duration: Duracao.rapida,
              height: Dim.alturaBotaoCompacto,
              padding: const EdgeInsets.symmetric(horizontal: Espaco.md),
              decoration: BoxDecoration(
                color: cores.panel3,
                border: Border.all(
                  color: ativo ? cores.accent : cores.line2,
                  width: Borda.fina,
                ),
                borderRadius: BorderRadius.circular(Raio.controle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                // Numa metade de linha o botão recebe largura de fora, e aí o
                // `min` não vale mais: sem isto o conteúdo encosta na esquerda.
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download,
                    size: Icone.p,
                    color: !habilitado
                        ? cores.text3
                        : ativo
                        ? cores.accent
                        : cores.text,
                  ),
                  const SizedBox(width: Espaco.sm),
                  // Flexível porque o mesmo botão vive numa metade de linha, ao
                  // lado do "Resetar valores": lá a largura vem de fora.
                  Flexible(
                    child: Text(
                      'Exportar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontSize: Tipo.corpo,
                        fontWeight: FontWeight.w600,
                        color: !habilitado
                            ? cores.text3
                            : ativo
                            ? cores.accent
                            : cores.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
