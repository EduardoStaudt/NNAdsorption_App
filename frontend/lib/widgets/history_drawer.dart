// history_drawer.dart — histórico de predições. O mesmo conteúdo serve dois
// lugares: o drawer da direita (tablet/mobile) e o painel do trilho (desktop).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../models/prediction.dart';
import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

/// Lista de predições salvas, sem moldura. Quem embrulha decide se é drawer
/// ou painel fixo.
class HistoricoConteudo extends StatelessWidget {
  final List<PredictionSummary> items;
  final bool carregando;
  final VoidCallback onRefresh;
  final void Function(int id) onDelete;
  final void Function(int id) onCarregarPredicao;

  /// Nome que o usuário deu à predição, ou o automático se não deu nenhum.
  final String Function(PredictionSummary item) nomeDe;
  final void Function(int id, String nome) onRenomear;

  /// Fecha a rota depois de carregar — verdadeiro no drawer, que precisa sair
  /// da frente; falso no painel do trilho, que fica onde está.
  final bool fecharAposCarregar;

  const HistoricoConteudo({
    super.key,
    required this.items,
    required this.carregando,
    required this.onRefresh,
    required this.onDelete,
    required this.onCarregarPredicao,
    required this.nomeDe,
    required this.onRenomear,
    this.fecharAposCarregar = false,
  });

  /// A predição inteira já está no navegador — não há detalhe pra buscar nem
  /// erro de rede pra tratar. Quem tem a entrada é a tela, então aqui só passa
  /// o id adiante.
  void _carregarDetalhe(BuildContext context, int id) {
    onCarregarPredicao(id);
    if (fecharAposCarregar) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Column(
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
                  eyebrow: 'Histórico',
                  titulo: 'Predições salvas',
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
                'Nenhuma predição ainda.',
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
                nome: nomeDe(items[i]),
                onTap: () => _carregarDetalhe(ctx, items[i].id),
                onDelete: () => onDelete(items[i].id),
                onRenomear: (nome) => onRenomear(items[i].id, nome),
              ),
            ),
          ),
      ],
    );
  }
}

/// Moldura de drawer pro histórico — usada em tablet e mobile, onde ele entra
/// pela direita por cima do conteúdo.
class HistoryDrawer extends StatelessWidget {
  final List<PredictionSummary> items;
  final bool carregando;
  final VoidCallback onRefresh;
  final void Function(int id) onDelete;
  final void Function(int id) onCarregarPredicao;
  final String Function(PredictionSummary item) nomeDe;
  final void Function(int id, String nome) onRenomear;

  const HistoryDrawer({
    super.key,
    required this.items,
    required this.carregando,
    required this.onRefresh,
    required this.onDelete,
    required this.onCarregarPredicao,
    required this.nomeDe,
    required this.onRenomear,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: Dim.larguraDrawerHistorico,
      backgroundColor: context.cores.panel,
      child: SafeArea(
        child: HistoricoConteudo(
          items: items,
          carregando: carregando,
          onRefresh: onRefresh,
          onDelete: onDelete,
          onCarregarPredicao: onCarregarPredicao,
          nomeDe: nomeDe,
          onRenomear: onRenomear,
          fecharAposCarregar: true,
        ),
      ),
    );
  }
}

// Item do histórico como no mockup: card panel2 que desliza 2px no hover
class _HistItem extends StatefulWidget {
  final PredictionSummary item;
  final String nome;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(String nome) onRenomear;

  const _HistItem({
    required this.item,
    required this.nome,
    required this.onTap,
    required this.onDelete,
    required this.onRenomear,
  });

  @override
  State<_HistItem> createState() => _HistItemState();
}

class _HistItemState extends State<_HistItem> {
  /// Renomear acontece na própria linha — abrir um diálogo pra trocar uma
  /// palavra seria peso demais pro que a ação é.
  TextEditingController? _edicao;

  void _comecarEdicao() {
    setState(() => _edicao = TextEditingController(text: widget.nome));
  }

  void _confirmarEdicao() {
    final texto = _edicao?.text.trim() ?? '';
    widget.onRenomear(texto);
    setState(() {
      _edicao?.dispose();
      _edicao = null;
    });
  }

  @override
  void dispose() {
    _edicao?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final item = widget.item;
    final editando = _edicao != null;
    final data = DateFormat('dd/MM/yy HH:mm').format(item.criadoEm.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.sm),
      child: Hover(
        builder: (emHover) => GestureDetector(
          onTap: editando ? null : widget.onTap,
          child: MouseRegion(
            cursor: editando
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
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
                        if (editando)
                          TextField(
                            controller: _edicao,
                            autofocus: true,
                            style: TextStyle(
                              fontFamily: 'IBMPlexSans',
                              fontSize: Tipo.corpo,
                              fontWeight: FontWeight.w500,
                              color: cores.text,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'Nome do experimento',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: Espaco.sm,
                                vertical: Espaco.xs,
                              ),
                            ),
                            onSubmitted: (_) => _confirmarEdicao(),
                            onTapOutside: (_) => _confirmarEdicao(),
                          )
                        else
                          Text(
                            widget.nome,
                            overflow: TextOverflow.ellipsis,
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
                    tooltip: editando ? 'Salvar nome' : 'Renomear',
                    icon: Icon(
                      editando ? Icons.check : Icons.edit_outlined,
                      size: Icone.m,
                    ),
                    onPressed: editando ? _confirmarEdicao : _comecarEdicao,
                  ),
                  IconButton(
                    tooltip: 'Apagar',
                    // Cor vem do iconButtonTheme, como nos demais IconButton
                    icon: const Icon(Icons.delete_outline, size: Icone.m),
                    onPressed: widget.onDelete,
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
