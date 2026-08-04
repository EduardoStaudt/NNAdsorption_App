// barra_acoes.dart — faixa fixa de ícones na borda esquerda do desktop.
//
// Reúne as três ações que antes eram botões soltos no cabeçalho dos resultados.
// Fica sempre visível: não abre nem fecha, e cada ícone dispara direto a mesma
// ação de antes. Nenhum comportamento muda aqui, só o ponto de entrada.
import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'export_button.dart';
import 'ui_comum.dart';

class BarraAcoes extends StatelessWidget {
  /// Painel de parâmetros visível — o ícone fica aceso enquanto estiver.
  final bool parametrosAbertos;
  final VoidCallback onAlternarParametros;
  final VoidCallback onAbrirHistorico;

  /// Falso quando não há predição em tela: o ícone apaga e o menu não abre.
  final bool podeExportar;
  final void Function(String formato) onExportar;

  const BarraAcoes({
    super.key,
    required this.parametrosAbertos,
    required this.onAlternarParametros,
    required this.onAbrirHistorico,
    required this.podeExportar,
    required this.onExportar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Dim.larguraBarraAcoes,
      child: Painel(
        padding: const EdgeInsets.symmetric(vertical: Espaco.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconeAcao(
              icone: Icons.tune,
              dica: parametrosAbertos
                  ? 'Recolher os parametros'
                  : 'Mostrar os parametros',
              // Estado ativo é um dos usos permitidos do âmbar, e é o que
              // explica pro usuário que este ícone alterna algo.
              ativo: parametrosAbertos,
              onTap: onAlternarParametros,
            ),
            _IconeAcao(
              icone: Icons.history,
              dica: 'Historico de predicoes',
              onTap: onAbrirHistorico,
            ),
            // O menu de formatos é o mesmo do botão largo, em forma de ícone.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Espaco.xxs),
              child: ExportButton(
                compacto: true,
                habilitado: podeExportar,
                onExport: onExportar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícone da barra: alvo quadrado, sem superfície própria. Em repouso é `text2`;
/// acende em âmbar sob o cursor e fica aceso enquanto `ativo`.
class _IconeAcao extends StatelessWidget {
  final IconData icone;
  final String dica;
  final bool ativo;
  final VoidCallback onTap;

  const _IconeAcao({
    required this.icone,
    required this.dica,
    required this.onTap,
    this.ativo = false,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espaco.xxs),
      child: Tooltip(
        message: dica,
        child: Semantics(
          button: true,
          label: dica,
          selected: ativo,
          child: Hover(
            builder: (emHover) => MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: Duracao.rapida,
                  width: Dim.itemBarraAcoes,
                  height: Dim.itemBarraAcoes,
                  decoration: BoxDecoration(
                    color: ativo ? cores.panel2 : Colors.transparent,
                    borderRadius: BorderRadius.circular(Raio.controle),
                  ),
                  child: Icon(
                    icone,
                    size: Icone.m,
                    color: ativo || emHover ? cores.accent : cores.text2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
