// platform_screen.dart — tela principal da plataforma (/app)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../models/param_defs.dart';
import '../models/prediction.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/export_button.dart';
import '../widgets/barra_acoes.dart';
import '../widgets/history_drawer.dart';
import '../widgets/parameters_panel.dart';
import '../widgets/results_panel.dart';
import '../widgets/topbar.dart';
import '../widgets/ui_comum.dart';
import '../theme/app_sizes.dart';

class PlatformScreen extends StatefulWidget {
  const PlatformScreen({super.key});

  @override
  State<PlatformScreen> createState() => _PlatformScreenState();
}

class _PlatformScreenState extends State<PlatformScreen> {
  final _api = ApiService();

  late final Map<String, TextEditingController> _controladores;

  PredictionResult? _resultado;
  int? _ultimoPredictionId;

  /// Só o layout desktop usa: o painel de parâmetros fica na tela e pode ser
  /// recolhido pra os gráficos ocuparem a largura toda. Estado da sessão —
  /// não persiste, e o padrão é aberto porque é onde o trabalho começa.
  bool _parametrosAbertos = true;

  // Histórico persistido — buscado do backend, não só em memória
  List<PredictionSummary> _historicoItems = [];
  bool _carregandoHistorico = false;

  // Para a aba de comparação (resultados completos em memória)
  final List<PredictionResult> _resultadosMemoria = [];

  @override
  void initState() {
    super.initState();
    _controladores = {
      for (final e in textosPadrao().entries)
        e.key: TextEditingController(text: e.value),
    };
    // Carrega o histórico assim que a tela monta
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchHistory());
  }

  @override
  void dispose() {
    for (final ctrl in _controladores.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _fetchHistory() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _carregandoHistorico = true);
    try {
      final lista = await _api.getHistory(token);
      if (mounted) {
        setState(() {
          _historicoItems = lista;
          _carregandoHistorico = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregandoHistorico = false);
        _avisar('Erro ao carregar historico: $e');
      }
    }
  }

  Future<void> _deletarPredicao(int id) async {
    final token = context.read<AuthProvider>().token!;
    try {
      await _api.deletePrediction(token, id);
      setState(() => _historicoItems.removeWhere((p) => p.id == id));
    } catch (e) {
      if (mounted) _avisar('Erro ao apagar: $e');
    }
  }

  void _resetarValores() {
    for (final entry in textosPadrao().entries) {
      _controladores[entry.key]?.text = entry.value;
    }
  }

  Future<void> _exportar(String format) async {
    if (_ultimoPredictionId == null) {
      _avisar('Rode uma predicao primeiro.');
      return;
    }
    final token = context.read<AuthProvider>().token!;
    final url = Uri.parse(
      '$kBackendUrl/predict/$_ultimoPredictionId/export?format=$format&token=$token',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (mounted) _avisar('Exportacao iniciada (${format.toUpperCase()}).');
    } catch (e) {
      if (mounted) _avisar('Erro ao exportar: $e');
    }
  }

  // GlobalKey em vez de Builder — abre os drawers sem precisar de um context extra
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Painel de parâmetros reutilizado nos 3 layouts
  Widget _painelParametros() {
    return ParametersPanel(
      controladores: _controladores,
      onResetar: _resetarValores,
    );
  }

  // Em telas menores os parâmetros ficam num bottom sheet
  void _abrirParametrosMobile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(Espaco.campo),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: _painelParametros(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token;
    // Uma leitura só de largura serve o corpo e a escolha do drawer. O corpo
    // ocupa a tela inteira, então isto é o mesmo que o LayoutBuilder media.
    final largura = MediaQuery.sizeOf(context).width;
    final desktop = largura >= Breakpoint.desktop;

    return Scaffold(
      key: _scaffoldKey,
      appBar: const Topbar(),
      // Drawer esquerdo com os parâmetros (usado no layout tablet). No desktop
      // as ações moram na BarraAcoes, que é fixa e não precisa de slot.
      drawer: Drawer(
        width: Dim.larguraDrawerParametros,
        backgroundColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(Espaco.campo),
          child: _painelParametros(),
        ),
      ),
      endDrawer: token != null
          ? HistoryDrawer(
              items: _historicoItems,
              carregando: _carregandoHistorico,
              token: token,
              onRefresh: _fetchHistory,
              onDelete: _deletarPredicao,
              onCarregarPredicao: (id, resultado) {
                setState(() {
                  _resultado = resultado;
                  // Habilita o Exportar: agora é esta a predição em tela
                  _ultimoPredictionId = id;
                  _resultadosMemoria.add(resultado);
                });
                // O drawer já chama Navigator.pop() em _carregarDetalhe — não fazer aqui
              },
            )
          : null,
      body: FundoPontilhado(
        child: desktop
            ? _layoutDesktop()
            : _layoutCompacto(mobile: largura < Breakpoint.tablet),
      ),
    );
  }

  /// Tablet e mobile: os três botões continuam à mostra no cabeçalho. Aqui o
  /// toque é caro e a tela é estreita demais pra ceder uma faixa fixa.
  Widget _acoes({required bool mobile}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: mobile
              ? _abrirParametrosMobile
              : () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.tune, size: Icone.m),
          label: const Text('Parametros'),
        ),
        TextButton.icon(
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          icon: const Icon(Icons.history, size: Icone.m),
          label: const Text('Historico'),
        ),
        const SizedBox(width: Espaco.xxs),
        ExportButton(
          habilitado: _ultimoPredictionId != null,
          onExport: _exportar,
        ),
      ],
    );
  }

  // Desktop (≥1200px): painel de parâmetros fixo + resultados ao lado
  Widget _layoutDesktop() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espaco.xl,
        Espaco.lg,
        Espaco.xl,
        Espaco.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Faixa fixa de ações, sempre visível na borda esquerda
          Align(
            alignment: Alignment.topLeft,
            child: BarraAcoes(
              parametrosAbertos: _parametrosAbertos,
              onAlternarParametros: () =>
                  setState(() => _parametrosAbertos = !_parametrosAbertos),
              onAbrirHistorico: () =>
                  _scaffoldKey.currentState?.openEndDrawer(),
              podeExportar: _ultimoPredictionId != null,
              onExportar: _exportar,
            ),
          ),
          const SizedBox(width: Espaco.lg),
          // Recolhe até zero levando junto o respiro da direita. O painel
          // continua montado — o `ClipRect` esconde e o `OverflowBox` segura a
          // largura original, senão o conteúdo se reorganizaria durante a
          // animação. Manter montado também preserva quais accordions estavam
          // abertos quando o usuário reabre.
          EntradaSuave(
            child: AnimatedContainer(
              key: const ValueKey('faixa-parametros'),
              duration: Duracao.media,
              curve: Curves.easeOut,
              width: _parametrosAbertos
                  ? Dim.larguraPainelParametros + Espaco.lg
                  : 0,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: Dim.larguraPainelParametros + Espaco.lg,
                  maxWidth: Dim.larguraPainelParametros + Espaco.lg,
                  child: Padding(
                    padding: const EdgeInsets.only(right: Espaco.lg),
                    child: _painelParametros(),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: EntradaSuave(
              atrasoMs: 60,
              child: ResultsPanel(
                resultado: _resultado,
                historico: _resultadosMemoria,
                // Sem /predict ligado: nada roda daqui até o modelo binário sair
                carregando: false,
                // No desktop as ações estão na barra fixa à esquerda
                actions: const SizedBox.shrink(),
                onExport: _exportar,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tablet (800-1199px) e mobile (<800px): só os resultados na tela;
  // parâmetros ficam num drawer (tablet) ou bottom sheet (mobile)
  Widget _layoutCompacto({required bool mobile}) {
    return Padding(
      padding: EdgeInsets.all(mobile ? Espaco.campo : Espaco.lg),
      child: EntradaSuave(
        child: ResultsPanel(
          resultado: _resultado,
          historico: _resultadosMemoria,
          // Sem /predict ligado: nada roda daqui até o modelo binário sair
          carregando: false,
          actions: _acoes(mobile: mobile),
          onExport: _exportar,
        ),
      ),
    );
  }
}
