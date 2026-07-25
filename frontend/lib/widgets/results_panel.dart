// results_panel.dart — painel direito com 4 abas de resultados
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show BrowserContextMenu;
import 'package:google_fonts/google_fonts.dart';
import '../models/prediction.dart';
import '../theme/colors.dart';
import 'charts/line_profile_chart.dart';
import 'export_button.dart';
import 'ui_comum.dart';

// Os 5 KPIs finais do modelo: (chave no resultado, unidade).
// Usado tanto na aba Comparacao quanto na aba Resultados Finais.
const _kpis = [
  ('C_out_final', 'mol/m³'),
  ('q_out_final', 'mol/kg'),
  ('T_out_final', 'K'),
  ('N_ads_final', 'mol'),
  ('Qtot_final', 'kg'),
];

// Pega o valor de um KPI pelo nome da chave
double _valorKpi(PredictionResult r, String chave) => switch (chave) {
      'C_out_final' => r.cOutFinal,
      'q_out_final' => r.qOutFinal,
      'T_out_final' => r.tOutFinal,
      'N_ads_final' => r.nAdsFinal,
      _ => r.qtotFinal,
    };

class ResultsPanel extends StatefulWidget {
  final PredictionResult? resultado;
  final List<PredictionResult> historico;
  final bool carregando; // true enquanto o /predict está rodando
  // Slot generico pra botoes de acao (historico, exportar, etc.) —
  // ResultsPanel so sabe que existe um espaco pra eles, nao o que sao.
  final Widget actions;
  // Lógica de exportação (CSV/XLSX) — reaproveitada no modal de gráfico ampliado
  final void Function(String format)? onExport;

  const ResultsPanel({
    super.key,
    required this.resultado,
    required this.historico,
    required this.carregando,
    required this.actions,
    this.onExport,
  });

  @override
  State<ResultsPanel> createState() => _ResultsPanelState();
}

class _ResultsPanelState extends State<ResultsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra do topo: abas + ações. Em tela larga fica tudo numa linha;
        // em tela estreita as ações vão pra uma linha própria em cima.
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final abas = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final (i, label) in const [
                      'Graficos',
                      'Tabela',
                      'Comparacao',
                      'Resultados Finais',
                    ].indexed)
                      _TabChip(label: label, controller: _tabs, index: i),
                  ],
                ),
              );

              if (constraints.maxWidth >= 680) {
                return Row(children: [Expanded(child: abas), widget.actions]);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: widget.actions,
                  ),
                  const SizedBox(height: 8),
                  abas,
                ],
              );
            },
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _TabGraficos(
                resultado: widget.resultado,
                carregando: widget.carregando,
                onExport: widget.onExport,
              ),
              _TabTabela(resultado: widget.resultado),
              _TabComparacao(historico: widget.historico),
              _TabResultadosFinais(resultado: widget.resultado, carregando: widget.carregando),
            ],
          ),
        ),
      ],
    );
  }
}

// Aba em formato de chip (como no mockup): ativa = accent preenchido
class _TabChip extends StatelessWidget {
  final String label;
  final TabController controller;
  final int index;
  const _TabChip({required this.label, required this.controller, required this.index});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, _) {
          final ativo = controller.index == index;
          return Hover(
            builder: (emHover) => GestureDetector(
              onTap: () => controller.animateTo(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: ativo ? cores.accent : cores.panel2,
                  border: Border.all(
                    color: ativo
                        ? cores.accent
                        : emHover
                            ? cores.line2
                            : cores.line,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ativo
                        ? cores.onAccent
                        : emHover
                            ? cores.text
                            : cores.text2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Aviso central usado quando ainda não há predição
class _AvisoVazio extends StatelessWidget {
  final String texto;
  const _AvisoVazio(this.texto);

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Center(
      child: Text(
        texto,
        style: GoogleFonts.ibmPlexSans(fontSize: 14, color: cores.text2),
      ),
    );
  }
}

// --- Aba 1: Gráficos (2x2, sem scroll, fill available) ---
class _TabGraficos extends StatelessWidget {
  final PredictionResult? resultado;
  final bool carregando;
  final void Function(String format)? onExport;
  const _TabGraficos({
    required this.resultado,
    required this.carregando,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    if (!carregando && resultado == null) {
      return const _AvisoVazio('Rode uma predicao para ver os graficos.');
    }

    final r = resultado;
    // (título, fórmula em mono, config do gráfico). O modal lê os campos desta
    // config pra reconstruir o mesmo gráfico ampliado, com zoom/pan.
    final graficos = carregando || r == null
        ? null
        : <(String, String, LineProfileChart)>[
            (
              'Concentracao',
              'C(z)',
              LineProfileChart(
                xs: r.zPoints,
                ys: r.cZPoints,
                eixoX: 'z (m)',
                eixoY: 'C (mol/m³)',
                cor: cores.data2,
                tooltip: (x, y) =>
                    'z=${x.toStringAsFixed(3)}\nC=${y.toStringAsFixed(4)}',
              ),
            ),
            (
              'Adsorcao',
              'q(z)',
              LineProfileChart(
                xs: r.zPoints,
                ys: r.qZPoints,
                eixoX: 'z (m)',
                eixoY: 'q (mol/kg)',
                cor: cores.data1,
                tooltip: (x, y) =>
                    'z=${x.toStringAsFixed(3)}\nq=${y.toStringAsFixed(4)}',
              ),
            ),
            (
              'Temperatura',
              'T(z)',
              LineProfileChart(
                xs: r.zPoints,
                ys: r.tZPoints,
                eixoX: 'z (m)',
                eixoY: 'T (K)',
                cor: cores.data3,
                tooltip: (x, y) =>
                    'z=${x.toStringAsFixed(3)}\nT=${y.toStringAsFixed(2)}',
              ),
            ),
            (
              'Breakthrough',
              'C_out(t)',
              LineProfileChart(
                xs: r.tPoints,
                ys: r.cOutPoints,
                eixoX: 't (s)',
                eixoY: 'C_out (mol/m³)',
                cor: cores.accent,
                preenchido: true,
                tooltip: (x, y) =>
                    't=${x.toStringAsFixed(1)} s\nC=${y.toStringAsFixed(4)}',
              ),
            ),
          ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cols = constraints.maxWidth < 700 ? 1 : 2;
        final rows = cols == 1 ? 4 : 2;
        // Calcula a proporção largura/altura de cada card pra grade 2x2
        // preencher exatamente o espaço disponível, sem sobrar scroll.
        // O clamp evita cards absurdamente esticados em janelas extremas.
        final cardW = (constraints.maxWidth - 14 * (cols - 1)) / cols;
        final cardH = (constraints.maxHeight - 14 * (rows - 1)) / rows;
        final ratio = cardW / cardH.clamp(100, double.infinity);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: ratio.clamp(0.5, 4.0),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
          ),
          physics: cols == 1
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: 4,
          itemBuilder: (_, i) => graficos == null
              ? const _SkeletonCard()
              : _GraficoCard(
                  titulo: graficos[i].$1,
                  formula: graficos[i].$2,
                  grafico: graficos[i].$3,
                  onExport: onExport,
                ),
        );
      },
    );
  }
}

// Skeleton de um card de gráfico enquanto a predição roda
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const Painel(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(largura: 130, altura: 14),
          SizedBox(height: 12),
          Expanded(child: Skeleton(largura: double.infinity, altura: double.infinity, raio: 8)),
        ],
      ),
    );
  }
}

class _GraficoCard extends StatelessWidget {
  final String titulo;
  final String formula;
  final LineProfileChart grafico;
  final void Function(String format)? onExport;
  const _GraficoCard({
    required this.titulo,
    required this.formula,
    required this.grafico,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    // Card clicável inteiro: abre o gráfico ampliado num modal. No card o
    // gráfico é um preview estático (IgnorePointer); a interatividade
    // (tooltip, zoom, pan) fica no modal.
    return Hover(
      builder: (emHover) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _abrirGraficoAmpliado(
            context,
            titulo: titulo,
            formula: formula,
            grafico: grafico,
            onExport: onExport,
          ),
          child: Painel(
            // "Corner ticks" decorativos nos cantos, como no mockup
            child: CustomPaint(
              foregroundPainter: _CornerTicksPainter(cor: cores.line2),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                titulo,
                                style: GoogleFonts.archivo(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: cores.text,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                formula,
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: cores.text2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Dica de expandir — aparece no hover
                        AnimatedOpacity(
                          opacity: emHover ? 1 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            Icons.open_in_full,
                            size: 15,
                            color: emHover ? cores.accent : cores.text3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Preview estático: não intercepta o tap (que abre o modal)
                    Expanded(child: IgnorePointer(child: grafico)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Abre o gráfico num modal centralizado, quase fullscreen, com zoom/pan.
void _abrirGraficoAmpliado(
  BuildContext context, {
  required String titulo,
  required String formula,
  required LineProfileChart grafico,
  void Function(String format)? onExport,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => _DialogGraficoAmpliado(
      titulo: titulo,
      formula: formula,
      grafico: grafico,
      onExport: onExport,
    ),
    // Entrada suave: fade + leve escala
    transitionBuilder: (_, anim, _, child) {
      final c = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: c,
        child: Transform.scale(scale: 0.96 + 0.04 * c.value, child: child),
      );
    },
  );
}

class _DialogGraficoAmpliado extends StatelessWidget {
  final String titulo;
  final String formula;
  final LineProfileChart grafico;
  final void Function(String format)? onExport;
  const _DialogGraficoAmpliado({
    required this.titulo,
    required this.formula,
    required this.grafico,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final estreito = MediaQuery.of(context).size.width < 600;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(estreito ? 16 : 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 820),
            child: Painel(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              titulo,
                              style: GoogleFonts.archivo(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: cores.text,
                              ),
                            ),
                            Text(
                              formula,
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: cores.text2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onExport != null) ...[
                        ExportButton(habilitado: true, onExport: onExport!),
                        const SizedBox(width: 8),
                      ],
                      _BotaoFecharModal(onTap: () => Navigator.of(context).pop()),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.pinch_outlined, size: 13, color: cores.text3),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Role/pinça pra ampliar · arraste pra mover · toque duplo reseta',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 10.5,
                            color: cores.text3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Zoom "de dados": recalcula min/max dos eixos → os ticks
                  // acompanham o range visível (não é um transform por cima).
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 14, 6),
                      child: _GraficoZoom(base: grafico),
                    ),
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

// Botão de fechar do modal — mesmo tato dos outros controles (borda accent no hover)
class _BotaoFecharModal extends StatelessWidget {
  final VoidCallback onTap;
  const _BotaoFecharModal({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Hover(
      builder: (emHover) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cores.panel3,
              border: Border.all(color: emHover ? cores.accent : cores.line2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.close,
              size: 18,
              color: emHover ? cores.accent : cores.text2,
            ),
          ),
        ),
      ),
    );
  }
}

// Gráfico com zoom/pan "de dados": ajusta a janela [minX,maxX]×[minY,maxY]
// conforme scroll (desktop), pinça e arraste — e o fl_chart recalcula eixos,
// ticks e gridlines pra essa janela (não é um transform por cima do desenho).
class _GraficoZoom extends StatefulWidget {
  final LineProfileChart base;
  const _GraficoZoom({required this.base});

  @override
  State<_GraficoZoom> createState() => _GraficoZoomState();
}

class _GraficoZoomState extends State<_GraficoZoom> {
  // Limites totais dos dados (Y com um respiro)
  late final double _dMinX, _dMaxX, _dMinY, _dMaxY;
  // Janela visível atual
  late double _minX, _maxX, _minY, _maxY;
  double _scaleAnterior = 1.0;
  bool _panDireita = false; // arrastando com o botão direito

  @override
  void initState() {
    super.initState();
    final xs = widget.base.xs;
    final ys = widget.base.ys;
    _dMinX = xs.reduce((a, b) => math.min(a, b));
    _dMaxX = xs.reduce((a, b) => math.max(a, b));
    final yMin = ys.reduce((a, b) => math.min(a, b));
    final yMax = ys.reduce((a, b) => math.max(a, b));
    final padY = (yMax - yMin).abs() * 0.06;
    _dMinY = yMin - (padY == 0 ? 1 : padY);
    _dMaxY = yMax + (padY == 0 ? 1 : padY);
    _reset();
    // Enquanto o gráfico ampliado está aberto, desliga o menu de contexto do
    // browser — assim o arraste com botão direito (pan) não abre o context menu.
    if (kIsWeb) BrowserContextMenu.disableContextMenu();
  }

  @override
  void dispose() {
    if (kIsWeb) BrowserContextMenu.enableContextMenu();
    super.dispose();
  }

  void _reset() {
    _minX = _dMinX;
    _maxX = _dMaxX;
    _minY = _dMinY;
    _maxY = _dMaxY;
  }

  // Mantém a janela dentro dos limites dos dados, preservando a largura
  void _enforceLimites() {
    final rx = _maxX - _minX;
    if (_minX < _dMinX) {
      _minX = _dMinX;
      _maxX = _dMinX + rx;
    }
    if (_maxX > _dMaxX) {
      _maxX = _dMaxX;
      _minX = _dMaxX - rx;
    }
    final ry = _maxY - _minY;
    if (_minY < _dMinY) {
      _minY = _dMinY;
      _maxY = _dMinY + ry;
    }
    if (_maxY > _dMaxY) {
      _maxY = _dMaxY;
      _minY = _dMaxY - ry;
    }
  }

  // Zoom por fator (<1 aproxima) ao redor de uma fração focal em pixels
  void _zoom(double fator, double fracX, double fracY) {
    final fullX = _dMaxX - _dMinX;
    final fullY = _dMaxY - _dMinY;
    final rx = _maxX - _minX;
    final ry = _maxY - _minY;
    final focoX = _minX + fracX * rx;
    final fyData = 1 - fracY; // pixel no topo = maxY
    final focoY = _minY + fyData * ry;
    final nrx = (rx * fator).clamp(fullX * 0.04, fullX);
    final nry = (ry * fator).clamp(fullY * 0.04, fullY);
    _minX = focoX - fracX * nrx;
    _maxX = _minX + nrx;
    _minY = focoY - fyData * nry;
    _maxY = _minY + nry;
    _enforceLimites();
  }

  void _pan(double dxData, double dyData) {
    _minX += dxData;
    _maxX += dxData;
    _minY += dyData;
    _maxY += dyData;
    _enforceLimites();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return Listener(
          onPointerSignal: (e) {
            if (e is PointerScrollEvent && w > 0 && h > 0) {
              final fracX = (e.localPosition.dx / w).clamp(0.0, 1.0);
              final fracY = (e.localPosition.dy / h).clamp(0.0, 1.0);
              // rolar pra cima = aproximar
              final fator = e.scrollDelta.dy < 0 ? 0.88 : 1.14;
              setState(() => _zoom(fator, fracX, fracY));
            }
          },
          // Pan com o botão direito (o context menu do browser já foi desligado)
          onPointerDown: (e) {
            if (e.buttons == kSecondaryButton) _panDireita = true;
          },
          onPointerMove: (e) {
            if (_panDireita && w > 0 && h > 0) {
              setState(() => _pan(
                    -e.delta.dx * (_maxX - _minX) / w,
                    e.delta.dy * (_maxY - _minY) / h,
                  ));
            }
          },
          onPointerUp: (_) => _panDireita = false,
          onPointerCancel: (_) => _panDireita = false,
          child: GestureDetector(
            onDoubleTap: () => setState(_reset),
            onScaleStart: (_) => _scaleAnterior = 1.0,
            onScaleUpdate: (d) {
              if (w <= 0 || h <= 0) return;
              setState(() {
                // arraste → pan
                if (d.focalPointDelta != Offset.zero) {
                  _pan(
                    -d.focalPointDelta.dx * (_maxX - _minX) / w,
                    d.focalPointDelta.dy * (_maxY - _minY) / h,
                  );
                }
                // pinça → zoom (incremento desde o último update)
                if (d.scale != 1.0) {
                  final fator = _scaleAnterior / d.scale;
                  _scaleAnterior = d.scale;
                  final fracX = (d.localFocalPoint.dx / w).clamp(0.0, 1.0);
                  final fracY = (d.localFocalPoint.dy / h).clamp(0.0, 1.0);
                  _zoom(fator, fracX, fracY);
                }
              });
            },
            child: LineProfileChart(
              xs: widget.base.xs,
              ys: widget.base.ys,
              eixoX: widget.base.eixoX,
              eixoY: widget.base.eixoY,
              cor: widget.base.cor,
              preenchido: widget.base.preenchido,
              tooltip: widget.base.tooltip,
              minX: _minX,
              maxX: _maxX,
              minY: _minY,
              maxY: _maxY,
            ),
          ),
        );
      },
    );
  }
}

// Desenha os "L" técnicos nos cantos superior-direito e inferior-esquerdo
class _CornerTicksPainter extends CustomPainter {
  final Color cor;
  _CornerTicksPainter({required this.cor});

  @override
  void paint(Canvas canvas, Size size) {
    final tinta = Paint()
      ..color = cor.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const m = 9.0; // margem até o canto
    const t = 11.0; // tamanho do "L"

    // canto superior direito
    canvas.drawPath(
      Path()
        ..moveTo(size.width - m - t, m)
        ..lineTo(size.width - m, m)
        ..lineTo(size.width - m, m + t),
      tinta,
    );
    // canto inferior esquerdo
    canvas.drawPath(
      Path()
        ..moveTo(m, size.height - m - t)
        ..lineTo(m, size.height - m)
        ..lineTo(m + t, size.height - m),
      tinta,
    );
  }

  @override
  bool shouldRepaint(_CornerTicksPainter old) => old.cor != cor;
}

// --- Aba 2: Tabela estilo mockup ---
class _TabTabela extends StatelessWidget {
  final PredictionResult? resultado;
  const _TabTabela({required this.resultado});

  @override
  Widget build(BuildContext context) {
    if (resultado == null) {
      return const _AvisoVazio('Rode uma predicao para ver a tabela.');
    }

    final r = resultado!;
    final cores = context.cores;

    return Painel(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho: mono maiúsculo com borda mais forte embaixo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: cores.line2)),
              ),
              child: Row(
                children: [
                  for (final (j, col) in ['z (m)', 'C (mol/m³)', 'q (mol/kg)', 'T (K)'].indexed)
                    Expanded(
                      child: Text(
                        col.toUpperCase(),
                        textAlign: j == 0 ? TextAlign.left : TextAlign.right,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: cores.text3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: r.zPoints.length,
                itemBuilder: (_, i) => _LinhaTabela(
                  valores: [
                    r.zPoints[i].toStringAsFixed(4),
                    r.cZPoints[i].toStringAsExponential(3),
                    r.qZPoints[i].toStringAsExponential(3),
                    r.tZPoints[i].toStringAsFixed(2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Linha da tabela com hover (fundo panel2 + texto mais claro)
class _LinhaTabela extends StatelessWidget {
  final List<String> valores;
  const _LinhaTabela({required this.valores});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Hover(
      builder: (emHover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: emHover ? cores.panel2 : Colors.transparent,
          border: Border(bottom: BorderSide(color: cores.line)),
        ),
        child: Row(
          children: [
            for (final (j, val) in valores.indexed)
              Expanded(
                child: Text(
                  val,
                  textAlign: j == 0 ? TextAlign.left : TextAlign.right,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12.5,
                    color: j == 0 || emHover ? cores.text : cores.text2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Aba 3: Comparação ---
class _TabComparacao extends StatefulWidget {
  final List<PredictionResult> historico;
  const _TabComparacao({required this.historico});

  @override
  State<_TabComparacao> createState() => _TabComparacaoState();
}

class _TabComparacaoState extends State<_TabComparacao> {
  int? _indexAtual;
  int? _indexRef;

  @override
  Widget build(BuildContext context) {
    if (widget.historico.length < 2) {
      return const _AvisoVazio('Faca pelo menos 2 predicoes para comparar.');
    }

    final nomes = List.generate(widget.historico.length, (i) => 'Predicao ${i + 1}');
    final atual = _indexAtual != null ? widget.historico[_indexAtual!] : null;
    final ref = _indexRef != null ? widget.historico[_indexRef!] : null;

    return SingleChildScrollView(
      // Espaço no topo pros labels flutuantes dos dropdowns
      // ("Predicao atual" / "Referencia") não serem cortados
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Predicao atual'),
                  value: _indexAtual, // ignore: deprecated_member_use
                  items: List.generate(nomes.length,
                      (i) => DropdownMenuItem(value: i, child: Text(nomes[i]))),
                  onChanged: (v) => setState(() => _indexAtual = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Referencia'),
                  value: _indexRef, // ignore: deprecated_member_use
                  items: List.generate(nomes.length,
                      (i) => DropdownMenuItem(value: i, child: Text(nomes[i]))),
                  onChanged: (v) => setState(() => _indexRef = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (atual != null && ref != null)
            _TabelaComparacao(atual: atual, referencia: ref),
        ],
      ),
    );
  }
}

class _TabelaComparacao extends StatelessWidget {
  final PredictionResult atual;
  final PredictionResult referencia;
  const _TabelaComparacao({required this.atual, required this.referencia});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Painel(
      child: DataTable(
        headingTextStyle: GoogleFonts.ibmPlexMono(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: cores.text3,
        ),
        columns: const [
          DataColumn(label: Text('KPI')),
          DataColumn(label: Text('ATUAL')),
          DataColumn(label: Text('REFERENCIA')),
          DataColumn(label: Text('DELTA')),
        ],
        rows: _kpis.map((kpi) {
          final (chave, unidade) = kpi;
          final valorAtual = _valorKpi(atual, chave);
          final valorRef = _valorKpi(referencia, chave);
          final delta = valorAtual - valorRef;
          final corDelta =
              delta > 0 ? cores.accent : delta < 0 ? cores.data3 : null;
          return DataRow(cells: [
            DataCell(Text('$chave ($unidade)',
                style: GoogleFonts.ibmPlexSans(fontSize: 13))),
            DataCell(Text(valorAtual.toStringAsExponential(3),
                style: GoogleFonts.ibmPlexMono(fontSize: 12))),
            DataCell(Text(valorRef.toStringAsExponential(3),
                style: GoogleFonts.ibmPlexMono(fontSize: 12))),
            DataCell(Text(delta.toStringAsExponential(3),
                style: GoogleFonts.ibmPlexMono(fontSize: 12, color: corDelta))),
          ]);
        }).toList(),
      ),
    );
  }
}

// --- Aba 4: Resultados Finais — KPI cards como no mockup ---
class _TabResultadosFinais extends StatelessWidget {
  final PredictionResult? resultado;
  final bool carregando;
  const _TabResultadosFinais({required this.resultado, required this.carregando});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    if (!carregando && resultado == null) {
      return const _AvisoVazio('Rode uma predicao para ver os resultados.');
    }

    final r = resultado;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CabecalhoSecao(eyebrow: 'Resultado', titulo: 'Saidas Finais'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (chave, unidade) in _kpis)
                _KpiCard(
                  chave: chave,
                  // null enquanto carrega → o card mostra skeleton
                  valor: r == null ? null : _valorKpi(r, chave),
                  unidade: unidade,
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Bloco de contexto placeholder
          SizedBox(
            width: double.infinity,
            child: Painel(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INTERPRETACAO DOS RESULTADOS',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: cores.text3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Em breve: interpretacao e contextualizacao dos resultados.',
                    style: GoogleFonts.ibmPlexSans(fontSize: 13, color: cores.text2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String chave;
  final double? valor; // null enquanto carrega → mostra skeleton
  final String unidade;
  const _KpiCard({required this.chave, required this.valor, required this.unidade});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Hover(
      builder: (emHover) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 200,
        decoration: BoxDecoration(
          color: cores.panel2,
          border: Border.all(color: emHover ? cores.line2 : cores.line),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra accent 26x3 no topo (como no mockup)
            Container(
              height: 3,
              width: 26,
              color: cores.accent,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chave.toUpperCase(),
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 10,
                      letterSpacing: 0.6,
                      color: cores.text3,
                    ),
                  ),
                  const SizedBox(height: 9),
                  if (valor == null)
                    const Skeleton(largura: 120, altura: 25)
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          valor!.toStringAsExponential(3),
                          style: GoogleFonts.archivo(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: cores.text,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unidade,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 11,
                            color: cores.text3,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
