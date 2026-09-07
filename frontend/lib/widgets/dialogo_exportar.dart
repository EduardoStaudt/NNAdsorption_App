// dialogo_exportar.dart — modal de exportação da predição em tela.
//
// A planilha é a mesma do lote, com uma linha só: `loteDeUm` embrulha o
// resultado e os exportadores de `inferencia/lote_local.dart` fazem o resto.
// Um formato só pros dois caminhos é o que deixa em paz quem abre os arquivos.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../inferencia/lote_local.dart';
import '../models/resultado_binario.dart';
import '../services/arquivo_local.dart';
import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

/// Abre o modal de exportação de uma predição.
void abrirDialogoExportar(
  BuildContext context, {
  required String nome,
  required ResultadoBinario resultado,
}) => abrirModal(context, DialogoExportar(nome: nome, resultado: resultado));

class DialogoExportar extends StatefulWidget {
  /// Nome do experimento, que também nomeia o arquivo.
  final String nome;
  final ResultadoBinario resultado;

  const DialogoExportar({
    super.key,
    required this.nome,
    required this.resultado,
  });

  @override
  State<DialogoExportar> createState() => _DialogoExportarState();
}

class _DialogoExportarState extends State<DialogoExportar> {
  bool _escalares = true;
  bool _curvas = false;
  String _formato = 'xlsx';
  String? _erro;

  /// CSV com curvas marcadas: a planilha sai só com os escalares. Avisa em vez
  /// de desmarcar sozinho, que seria mexer na escolha de quem escolheu.
  bool get _csvSemCurvas => _curvas && _formato == 'csv';

  /// Sem nada marcado não há arquivo pra gerar.
  bool get _podeBaixar => _escalares || _curvas;

  /// Nome do arquivo: o do experimento quando existe, senão a data de hoje.
  /// Só o que serve num nome de arquivo sobrevive, o resto vira sublinhado.
  String get _nomeArquivo {
    final limpo = widget.nome
        .trim()
        .replaceAll(RegExp(r'[^\wÀ-ÿ-]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final base = limpo.isEmpty
        ? 'predicao_${DateFormat('yyyy-MM-dd').format(DateTime.now())}'
        : limpo;
    return '${base}_resultado.$_formato';
  }

  void _baixar() {
    if (!_podeBaixar) return;
    final lote = loteDeUm(widget.nome, widget.resultado);
    try {
      final bytes = _formato == 'xlsx'
          ? loteParaXlsx(
              lote,
              todosOsEscalares,
              comCurvas: _curvas,
              comResumo: _escalares,
            )
          : loteParaCsv(lote, todosOsEscalares);
      baixarBytes(
        bytes,
        _nomeArquivo,
        _formato == 'xlsx' ? mediaXlsx : mediaCsv,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return MolduraModal(
      maxLargura: Dim.larguraModalEstreito,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: CabecalhoSecao(
                  eyebrow: 'Exportar',
                  titulo: 'Exportar resultado',
                ),
              ),
              BotaoFecharModal(onTap: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: Espaco.md),
          Divider(height: Borda.fina, color: cores.line),
          const SizedBox(height: Espaco.md),
          CartaoTitulado(
            titulo: 'O que exportar',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CaixaMarcacao(
                  rotulo: 'Escalares',
                  detalhe: 'tempos, πmax e severidade',
                  marcada: _escalares,
                  onMudar: (v) => setState(() => _escalares = v),
                ),
                const SizedBox(height: Espaco.campo),
                CaixaMarcacao(
                  rotulo: 'Curvas completas',
                  detalhe: 'as 4 séries de 100 pontos',
                  marcada: _curvas,
                  onMudar: (v) => setState(() => _curvas = v),
                ),
                Divider(height: Espaco.xl, color: cores.line),
                Row(
                  children: [
                    Text(
                      'Formato',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontSize: Tipo.corpo,
                        fontWeight: FontWeight.w600,
                        color: cores.text2,
                      ),
                    ),
                    const Spacer(),
                    Segmentado(
                      opcoes: kFormatosExport,
                      escolhido: _formato,
                      onEscolher: (f) => setState(() => _formato = f),
                    ),
                  ],
                ),
                if (_csvSemCurvas)
                  Padding(
                    padding: const EdgeInsets.only(top: Espaco.sm),
                    child: Text(
                      'CSV exporta só escalares. Para levar as curvas, '
                      'use XLSX.',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontSize: Tipo.corpo,
                        height: 1.4,
                        color: cores.text3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_erro != null) ...[
            const SizedBox(height: Espaco.cartao),
            Text(
              _erro!,
              style: TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: Tipo.corpo,
                height: 1.4,
                color: cores.erro,
              ),
            ),
          ],
          Divider(height: Espaco.lg, color: cores.line),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: Espaco.md),
                  child: Text(
                    _podeBaixar ? _nomeArquivo : 'Escolha ao menos um conteúdo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _podeBaixar ? 'IBMPlexMono' : 'IBMPlexSans',
                      fontSize: _podeBaixar ? Tipo.dado : Tipo.corpo,
                      color: cores.text3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Espaco.cartao),
              SizedBox(
                width: Dim.larguraBotaoModal,
                child: BotaoPrimario(
                  texto: 'Baixar',
                  icone: Icons.download_outlined,
                  onTap: _podeBaixar ? _baixar : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
