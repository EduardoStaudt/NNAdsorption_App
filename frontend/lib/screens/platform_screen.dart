// platform_screen.dart — tela principal da plataforma (/app)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../models/prediction.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/export_button.dart';
import '../widgets/history_drawer.dart';
import '../widgets/parameters_panel.dart';
import '../widgets/results_panel.dart';
import '../widgets/topbar.dart';
import '../widgets/ui_comum.dart';

// Breakpoints de layout: desktop ≥ 1200, tablet ≥ 800, mobile < 800
const _breakpointDesktop = 1200.0;
const _breakpointTablet = 800.0;

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
  bool _predicionando = false;

  // Histórico persistido — buscado do backend, não só em memória
  List<PredictionSummary> _historicoItems = [];
  bool _carregandoHistorico = false;

  // Para a aba de comparação (resultados completos em memória)
  final List<PredictionResult> _resultadosMemoria = [];

  @override
  void initState() {
    super.initState();
    _controladores = {
      for (final chave in valoresPadrao.keys)
        chave: TextEditingController(text: valoresPadrao[chave]),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
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

  Future<void> _rodarPredicao() async {
    final token = context.read<AuthProvider>().token!;

    final inputs = <String, double>{};
    for (final entry in _controladores.entries) {
      final valor = double.tryParse(entry.value.text.replaceAll(',', '.'));
      if (valor == null) {
        _avisar('Valor invalido em "${entry.key}"');
        return;
      }
      inputs[entry.key] = valor;
    }

    setState(() => _predicionando = true);
    try {
      final resposta = await _api.predict(token, inputs);
      setState(() {
        _resultado = resposta.result;
        _ultimoPredictionId = resposta.predictionId;
        _resultadosMemoria.add(resposta.result);
      });
      if (mounted) _avisar('Predicao concluida com sucesso.');
      // Atualiza o histórico no drawer após cada predição bem-sucedida
      await _fetchHistory();
    } catch (e) {
      if (mounted) _avisar('Erro: $e');
    } finally {
      if (mounted) setState(() => _predicionando = false);
    }
  }

  void _resetarValores() {
    for (final entry in valoresPadrao.entries) {
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
  Widget _painelParametros({VoidCallback? aposRodar}) {
    return ParametersPanel(
      controladores: _controladores,
      carregando: _predicionando,
      onPredict: () {
        aposRodar?.call(); // fecha drawer/bottom sheet antes de rodar
        _rodarPredicao();
      },
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
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: _painelParametros(aposRodar: () => Navigator.pop(ctx)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token;

    return Scaffold(
      key: _scaffoldKey,
      appBar: const Topbar(),
      // Drawer esquerdo com os parâmetros (usado no layout tablet)
      drawer: Drawer(
        width: 372,
        backgroundColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: _painelParametros(
            aposRodar: () => Navigator.pop(context),
          ),
        ),
      ),
      endDrawer: token != null
          ? HistoryDrawer(
              items: _historicoItems,
              carregando: _carregandoHistorico,
              token: token,
              onRefresh: _fetchHistory,
              onDelete: _deletarPredicao,
              onCarregarPredicao: (resultado) {
                setState(() {
                  _resultado = resultado;
                  _resultadosMemoria.add(resultado);
                });
                // O drawer já chama Navigator.pop() em _carregarDetalhe — não fazer aqui
              },
            )
          : null,
      body: FundoPontilhado(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final largura = constraints.maxWidth;
            if (largura >= _breakpointDesktop) return _layoutDesktop();
            if (largura >= _breakpointTablet) return _layoutCompacto(mobile: false);
            return _layoutCompacto(mobile: true);
          },
        ),
      ),
    );
  }

  // Botões que aparecem à direita das abas (histórico + exportar + parâmetros)
  Widget _acoes({required bool mostrarParametros, required bool mobile}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mostrarParametros)
          TextButton.icon(
            onPressed: mobile
                ? _abrirParametrosMobile
                : () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Parametros'),
          ),
        TextButton.icon(
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          icon: const Icon(Icons.history, size: 18),
          label: const Text('Historico'),
        ),
        const SizedBox(width: 4),
        ExportButton(
          habilitado: _ultimoPredictionId != null,
          onExport: _exportar,
        ),
      ],
    );
  }

  // Desktop (≥1200px): painel fixo de 352px + resultados ao lado
  Widget _layoutDesktop() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EntradaSuave(
            child: SizedBox(width: 352, child: _painelParametros()),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: EntradaSuave(
              atrasoMs: 60,
              child: ResultsPanel(
                resultado: _resultado,
                historico: _resultadosMemoria,
                carregando: _predicionando,
                actions: _acoes(mostrarParametros: false, mobile: false),
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
      padding: EdgeInsets.all(mobile ? 10 : 18),
      child: EntradaSuave(
        child: ResultsPanel(
          resultado: _resultado,
          historico: _resultadosMemoria,
          carregando: _predicionando,
          actions: _acoes(mostrarParametros: true, mobile: mobile),
        ),
      ),
    );
  }
}
