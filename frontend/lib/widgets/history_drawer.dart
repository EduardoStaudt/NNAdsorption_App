// history_drawer.dart — drawer lateral com histórico de predições
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../models/prediction.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

class HistoryDrawer extends StatelessWidget {
  final List<PredictionSummary> items;
  final bool carregando;
  final String token;
  final VoidCallback onRefresh;
  final void Function(int id) onDelete;
  final void Function(PredictionResult resultado) onCarregarPredicao;

  const HistoryDrawer({
    super.key,
    required this.items,
    required this.carregando,
    required this.token,
    required this.onRefresh,
    required this.onDelete,
    required this.onCarregarPredicao,
  });

  Future<void> _carregarDetalhe(BuildContext context, int id) async {
    try {
      final detalhe = await ApiService().getPrediction(token, id);
      final outputs = detalhe['outputs'] as Map<String, dynamic>;
      final resultado = PredictionResult.fromJson(outputs);
      onCarregarPredicao(resultado);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar predicao: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Drawer(
      width: 340,
      backgroundColor: cores.panel,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: CabecalhoSecao(
                      eyebrow: 'Historico',
                      titulo: 'Predicoes salvas',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atualizar',
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cores.line),
            if (carregando)
              // Skeletons enquanto o histórico carrega
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    for (var i = 0; i < 6; i++)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 7),
                        child: Skeleton(largura: double.infinity, altura: 52, raio: 9),
                      ),
                  ],
                ),
              )
            else if (items.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Nenhuma predicao ainda.',
                    style: GoogleFonts.ibmPlexSans(fontSize: 13, color: cores.text2),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => _HistItem(
                    item: items[i],
                    onTap: () => _carregarDetalhe(ctx, items[i].id),
                    onDelete: () => onDelete(items[i].id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Item do histórico como no mockup: card panel2 que desliza 2px no hover
class _HistItem extends StatelessWidget {
  final PredictionSummary item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _HistItem({required this.item, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final data = DateFormat('dd/MM/yy HH:mm').format(item.criadoEm.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Hover(
        builder: (emHover) => GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(emHover ? 2 : 0, 0, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cores.panel2,
                border: Border.all(color: emHover ? cores.line2 : cores.line),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  // Dot colorido do item
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: cores.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Predicao #${item.id}',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: cores.text,
                          ),
                        ),
                        if (item.cOutFinal != null)
                          Text(
                            'C_out=${item.cOutFinal!.toStringAsExponential(3)}',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 10.5,
                              color: cores.text3,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    data,
                    style: GoogleFonts.ibmPlexMono(fontSize: 10.5, color: cores.text3),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Apagar',
                    icon: Icon(Icons.delete_outline, size: 18, color: cores.text2),
                    onPressed: onDelete,
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
