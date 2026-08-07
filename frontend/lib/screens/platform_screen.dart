// platform_screen.dart — tela principal da plataforma (/app)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../models/param_defs.dart';
import '../models/prediction.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/export_button.dart';
import '../widgets/history_drawer.dart';
import '../widgets/parameters_panel.dart';
import '../widgets/rail_lateral.dart';
import '../widgets/results_panel.dart';
import '../widgets/topbar.dart';
import '../widgets/ui_comum.dart';
import '../theme/app_sizes.dart';
import '../theme/colors.dart';

/// Painéis que o trilho controla, na ordem em que aparecem nele.
enum _Painel { parametros, historico }

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

  // --- Trilho lateral (só desktop) ---

  /// Painel aberto agora, ou null com tudo fechado. Um valor só: abrir um
  /// fecha o anterior por construção.
  _Painel? _aberto = _Painel.parametros;

  /// Último painel aberto — é o que o botão de alternar reabre. Começa
  /// preenchido porque a tela nasce nos parâmetros.
  _Painel? _ultimo = _Painel.parametros;

  /// Painel sob o cursor no trilho, pra prévia. Não fixa nada.
  _Painel? _espiado;

  /// Um estado de accordion só, dividido entre o painel e a prévia dele —
  /// senão a prévia mostraria grupos abertos que o usuário não abriu.
  final _estadoAccordion = EstadoAccordion();

  /// Nome que o usuário deu ao experimento em preparo. Vazio deixa o nome
  /// automático valer.
  final _nomeExperimento = TextEditingController();

  /// Nomes por predição. Estado da sessão: some ao recarregar, porque o
  /// backend ainda não tem onde guardar isso.
  final Map<int, String> _nomes = {};

  String _nomeDe(PredictionSummary p) => _nomes[p.id]?.trim().isNotEmpty == true
      ? _nomes[p.id]!
      : 'Predicao #${p.id}';

  void _renomear(int id, String nome) {
    setState(() {
      if (nome.trim().isEmpty) {
        _nomes.remove(id);
      } else {
        _nomes[id] = nome.trim();
      }
      // Renomeou a que está em tela: o campo de cima acompanha
      if (id == _ultimoPredictionId) _nomeExperimento.text = _nomes[id] ?? '';
    });
  }

  void _alternarPainel(_Painel painel) {
    setState(() {
      _aberto = _aberto == painel ? null : painel;
      if (_aberto != null) _ultimo = _aberto;
      // Abriu ou fechou de verdade: a prévia perdeu a razão de existir.
      _espiado = null;
    });
  }

  /// Abre/fecha sem trocar de painel. Sem nada aberto e sem nada lembrado não
  /// há painel padrão pra escolher sozinho — o botão fica inerte.
  void _alternarTrilho() {
    if (_aberto == null && _ultimo == null) return;
    setState(() {
      _aberto = _aberto == null ? _ultimo : null;
      _espiado = null;
    });
  }

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
    _estadoAccordion.dispose();
    _nomeExperimento.dispose();
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
  Widget _painelParametros({
    bool moldurado = true,
    bool somenteLeitura = false,
  }) {
    return ParametersPanel(
      controladores: _controladores,
      onResetar: _resetarValores,
      podeExportar: _ultimoPredictionId != null,
      onExportar: _exportar,
      moldurado: moldurado,
      somenteLeitura: somenteLeitura,
      estado: _estadoAccordion,
      nome: _nomeExperimento,
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
      appBar: Topbar(
        // Só o desktop tem trilho — nos outros o alternar não teria o que fazer
        painelAberto: desktop ? _aberto != null : null,
        onAlternarPainel: desktop ? _alternarTrilho : null,
      ),
      // Drawer esquerdo com os parâmetros (usado no layout tablet). No desktop
      // os painéis vivem ao lado do trilho e este slot fica sem uso.
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
              // O drawer se fecha sozinho depois de carregar
              onCarregarPredicao: _mostrarPredicao,
              nomeDe: _nomeDe,
              onRenomear: _renomear,
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
    final token = context.read<AuthProvider>().token;
    final cores = context.cores;
    final espiado = _espiado;

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Trilho colado na borda, sem padding em volta — a moldura da tela
            // começa só depois dele.
            RailLateral(
              onEspiar: (i) => setState(
                () => _espiado = i == null ? null : _Painel.values[i],
              ),
              itens: [
                ItemRail(
                  icone: Icons.tune,
                  dica: 'Parametros de entrada',
                  ativo: _aberto == _Painel.parametros,
                  onTap: () => _alternarPainel(_Painel.parametros),
                ),
                ItemRail(
                  icone: Icons.history,
                  dica: 'Historico de predicoes',
                  ativo: _aberto == _Painel.historico,
                  onTap: () => _alternarPainel(_Painel.historico),
                ),
              ],
            ),
            // Recolhe até zero. O `ClipRect` esconde e o `OverflowBox` segura a
            // largura original, senão o conteúdo se reorganizaria durante a
            // animação. O `IndexedStack` mantém os dois montados: trocar de
            // painel ou fechar não perde accordion aberto nem rolagem.
            //
            // Sem padding e sem card: o painel encosta no trilho e vai de topo
            // a base, separado do resto pelo mesmo fio que o trilho usa.
            AnimatedContainer(
              key: const ValueKey('painel-lateral'),
              duration: Duracao.media,
              curve: Curves.easeOut,
              width: _aberto == null ? 0 : Dim.larguraPainelParametros,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: Dim.larguraPainelParametros,
                  maxWidth: Dim.larguraPainelParametros,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cores.panel,
                      border: Border(
                        right: BorderSide(color: cores.line, width: Borda.fina),
                      ),
                    ),
                    child: IndexedStack(
                      index: (_aberto ?? _ultimo ?? _Painel.parametros).index,
                      children: [
                        _painelParametros(moldurado: false),
                        _historico(token),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Espaco.lg,
                  Espaco.lg,
                  Espaco.lg,
                  Espaco.lg,
                ),
                child: EntradaSuave(
                  atrasoMs: 60,
                  child: ResultsPanel(
                    resultado: _resultado,
                    historico: _resultadosMemoria,
                    // Sem /predict ligado: nada roda daqui até o modelo sair
                    carregando: false,
                    // No desktop as ações moram no trilho
                    actions: const SizedBox.shrink(),
                    onExport: _exportar,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Prévia por cima de tudo: mostra o que tem lá dentro sem abrir nada.
        if (espiado != null)
          Positioned(
            left: Dim.larguraRail + Espaco.sm,
            top: Espaco.lg,
            child: _peek(espiado),
          ),
      ],
    );
  }

  /// Traz uma predição do histórico pra tela. Serve o painel do trilho e o
  /// drawer, que só diferem em fechar ou não depois.
  void _mostrarPredicao(int id, PredictionResult resultado) {
    setState(() {
      _resultado = resultado;
      // Habilita o Exportar: agora é esta a predição em tela
      _ultimoPredictionId = id;
      _resultadosMemoria.add(resultado);
      // O campo do topo passa a nomear a predição que está em tela
      _nomeExperimento.text = _nomes[id] ?? '';
    });
  }

  /// Histórico sem moldura, pro painel do trilho. Fica aberto depois de
  /// carregar — é painel fixo, não sai da frente de ninguém. Sem sessão não há
  /// o que listar; a rota é protegida, então isto só aparece em teste.
  Widget _historico(String? token) {
    if (token == null) {
      return const Center(child: Text('Entre pra ver o historico.'));
    }
    return HistoricoConteudo(
      items: _historicoItems,
      carregando: _carregandoHistorico,
      token: token,
      onRefresh: _fetchHistory,
      onDelete: _deletarPredicao,
      onCarregarPredicao: _mostrarPredicao,
      nomeDe: _nomeDe,
      onRenomear: _renomear,
    );
  }

  /// Versão curta e só-leitura de cada painel, pro hover do trilho. Todas
  /// cabem na mesma caixa — o que passa é cortado pelo `PeekPainel`.
  Widget _peek(_Painel painel) => switch (painel) {
    // O painel inteiro, no estado em que está, só que sem editar. A caixa
    // fixa da prévia corta o que não couber.
    _Painel.parametros => PeekPainel(
      titulo: 'Parametros de Entrada',
      // Largura e altura do painel de verdade dentro da caixa da prévia: o
      // conteúdo se organiza como lá e a prévia mostra a parte de cima.
      child: SizedBox(
        width: Dim.larguraPainelParametros,
        height: Dim.alturaPeek,
        child: _painelParametros(moldurado: false, somenteLeitura: true),
      ),
    ),
    _Painel.historico => PeekPainel(
      titulo: 'Historico',
      child: _carregandoHistorico
          ? const PeekLinha('Carregando...')
          : _historicoItems.isEmpty
          ? const PeekLinha('Nenhuma predicao ainda')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in _historicoItems)
                  _PreviaPredicao(item: p, nome: _nomeDe(p)),
              ],
            ),
    ),
  };

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

/// Predição na prévia do histórico: o mesmo que o item real mostra, sem o
/// cartão nem o botão de apagar.
class _PreviaPredicao extends StatelessWidget {
  final PredictionSummary item;
  final String nome;
  const _PreviaPredicao({required this.item, required this.nome});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final data = DateFormat('dd/MM/yy HH:mm').format(item.criadoEm.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.sm),
      child: Row(
        children: [
          Container(
            width: Espaco.xs,
            height: Espaco.xs,
            decoration: BoxDecoration(
              color: cores.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Espaco.sm),
          Expanded(
            child: Text(
              nome,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: Tipo.corpo,
                color: cores.text,
              ),
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
        ],
      ),
    );
  }
}
