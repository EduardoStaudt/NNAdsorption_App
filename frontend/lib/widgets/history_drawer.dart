// history_drawer.dart — drawer lateral com histórico de predições
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../models/prediction.dart';
import '../services/api_service.dart';
import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

class HistoryDrawer extends StatelessWidget {
  final List<PredictionSummary> items;
  final bool carregando;
  final String token;
  final VoidCallback onRefresh;
  final void Function(int id) onDelete;
  final void Function(int id, PredictionResult resultado) onCarregarPredicao;

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
      onCarregarPredicao(id, resultado);
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
      width: Dim.larguraDrawerHistorico,
      backgroundColor: cores.panel,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Espaco.lg,
                Espaco.md,
                Espaco.sm,
                Espaco.sm,
              ),
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
                    icon: const Icon(Icons.refresh, size: Icone.m),
                    onPressed: onRefresh,
                  ),
                ],
              ),
            ),
            Divider(height: Borda.fina, color: cores.line),
            if (carregando)
              // Skeletons enquanto o histórico carrega
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(Espaco.md),
                  children: [
                    for (var i = 0; i < 6; i++)
                      const Padding(
                        padding: EdgeInsets.only(bottom: Espaco.sm),
                        child: Skeleton(
                          largura: double.infinity,
                          altura: Dim.alturaItemHistorico,
                          raio: Raio.cartao,
                        ),
                      ),
                  ],
                ),
              )
            else if (items.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Nenhuma predicao ainda.',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSans',
                      fontSize: Tipo.corpo,
                      color: cores.text2,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(Espaco.md),
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
      padding: const EdgeInsets.only(bottom: Espaco.sm),
      child: Hover(
        builder: (emHover) => GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: Duracao.rapida,
              transform: Matrix4.translationValues(emHover ? 2 : 0, 0, 0),
              padding: const EdgeInsets.symmetric(
                horizontal: Espaco.cartao,
                vertical: Espaco.campo,
              ),
              decoration: BoxDecoration(
                color: cores.panel2,
                // Carrega a predição ao clicar: ganha o fio de âmbar do hover.
                // Sem escala nem sombra — numa lista estreita, levantar cada
                // linha vira agitação; o deslize de 2px já dá o retorno.
                border: Border.all(
                  color: emHover
                      ? cores.accent.withValues(alpha: Elevacao.bordaHover)
                      : cores.line,
                  width: Borda.fina,
                ),
                borderRadius: BorderRadius.circular(Raio.cartao),
              ),
              child: Row(
                children: [
                  // Dot colorido do item
                  Container(
                    width: Espaco.sm,
                    height: Espaco.sm,
                    decoration: BoxDecoration(
                      color: cores.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Espaco.cartao),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Predicao #${item.id}',
                          style: TextStyle(
                            fontFamily: 'IBMPlexSans',
                            fontSize: Tipo.corpo,
                            fontWeight: FontWeight.w500,
                            color: cores.text,
                          ),
                        ),
                        if (item.cOutFinal != null)
                          Text(
                            'C_out=${item.cOutFinal!.toStringAsExponential(3)}',
                            style: TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: Tipo.label,
                              color: cores.text3,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    data,
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: Tipo.label,
                      color: cores.text3,
                    ),
                  ),
                  const SizedBox(width: Espaco.xxs),
                  IconButton(
                    tooltip: 'Apagar',
                    icon: Icon(Icons.delete_outline, size: Icone.m, color: cores.text2),
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
