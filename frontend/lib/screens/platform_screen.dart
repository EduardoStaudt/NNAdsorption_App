// platform_screen.dart — tela principal da plataforma (/app)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../models/param_defs.dart';
import '../inferencia/preditor_onnx.dart';
import '../models/prediction.dart';
import '../models/resultado_binario.dart';
import '../services/armazenamento_local.dart';
import '../widgets/export_button.dart';
import '../widgets/dialogo_exportar.dart';
import '../widgets/dialogo_lote.dart';
import '../widgets/history_drawer.dart';
import '../widgets/painel_flat_parametros.dart';
import '../widgets/parameters_panel.dart';
import '../widgets/rail_lateral.dart';
import '../widgets/topbar.dart';
import '../widgets/ui_comum.dart';
import '../widgets/zona_resultados.dart';
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
  final _historicoLocal = HistoricoLocal();
  final _presets = PresetsLocal();

  late final Map<String, TextEditingController> _controladores;

  /// Predição em tela, se veio do histórico. Guardamos a entrada inteira
  /// porque é dela que sai o resultado cru pra exportar.
  EntradaHistorico? _entradaEmTela;

  /// Espelho em memória do que está no navegador. Evita reler o localStorage a
  /// cada rebuild, e é dele que sai o resumo da lista.
  List<EntradaHistorico> _entradas = [];

  // --- Trilho lateral (só desktop) ---

  /// Painel aberto agora, ou null com tudo fechado. Um valor só: abrir um
  /// fecha o anterior por construção.
  _Painel? _aberto = _Painel.parametros;

  /// Último painel aberto — é o que o botão de alternar reabre. Começa
  /// preenchido porque a tela nasce nos parâmetros.
  _Painel? _ultimo = _Painel.parametros;

  /// Cursor parado no ícone do histórico, com o painel dele fechado. É a única
  /// prévia que existe — quem decide isso é o `flutuante` do `ItemRail`, e por
  /// isso aqui basta um bool: o trilho nunca reporta os parâmetros.
  bool _espiandoHistorico = false;

  /// Um estado de accordion só pros três layouts que montam o painel.
  final _estadoAccordion = EstadoAccordion();

  /// Nome que o usuário deu ao experimento em preparo. Vazio deixa o nome
  /// automático valer.
  final _nomeExperimento = TextEditingController();

  /// Curvas que a coluna central desenha. Começam nas sintéticas dos valores
  /// padrão e passam a ser as do último experimento rodado ou carregado.
  ResultadoBinario _binarioEmTela = ResultadoBinario.exemplo();

  /// Experimento do histórico sobreposto ao atual. Só em memória: recarregar a
  /// página desfaz a comparação, e isso é o esperado.
  ResultadoBinario? _comparacao;
  String? _nomeComparacao;

  /// Qual entrada do histórico está sobreposta. Só serve pra lista marcar a
  /// escolhida e pra saber que o clique agora troca a comparação.
  int? _idComparacao;

  /// O nome vive na própria entrada do histórico, então sobrevive ao reload.
  String _nomeDe(PredictionSummary p) =>
      _entradas.where((e) => e.id == p.id).firstOrNull?.nome ??
      'Predição #${p.id}';

  Future<void> _renomear(int id, String nome) async {
    final novo = nome.trim();
    await _historicoLocal.renomear(id, novo);
    if (!mounted) return;
    // Renomeou a que está em tela: o campo do pé acompanha
    if (_entradaEmTela?.id == id) _nomeExperimento.text = novo;
    await _fetchHistory();
  }

  // --- Painel flat da direita, redimensionável pela alça ---

  /// Largura que o arraste vem mantendo. Não sobrevive ao reload: recarregar a
  /// página devolve o padrão.
  double _larguraFlat = Dim.larguraPainelFlat;

  /// Largura de antes de colapsar — é ela que a seta traz de volta.
  double _ultimaLarguraFlat = Dim.larguraPainelFlat;

  bool _flatColapsado = false;

  /// Com a alça na mão a largura tem que acompanhar o cursor no mesmo frame;
  /// a animação só vale pro colapso.
  bool _arrastandoFlat = false;

  /// Guarda a largura de agora antes de o arraste começar a mexer nela. É este
  /// valor que a seta traz de volta — anotar durante o arraste devolveria a
  /// largura do último frame antes de colapsar, que é sempre o limiar.
  void _comecarArrasteFlat() {
    setState(() {
      _arrastandoFlat = true;
      if (!_flatColapsado) _ultimaLarguraFlat = _larguraFlat;
    });
  }

  /// `teto` vem do layout: é o que sobra sem espremer a coluna central.
  void _arrastarFlat(double dx, double teto) {
    setState(() {
      // Metade do limiar como piso: dá pra continuar arrastando depois de
      // colapsar, e voltar reabre.
      _larguraFlat = (_larguraFlat - dx).clamp(
        Dim.larguraColapsaFlat / 2,
        teto,
      );
      _flatColapsado = _larguraFlat < Dim.larguraColapsaFlat;
    });
  }

  void _abrirFlat() {
    setState(() {
      _flatColapsado = false;
      _larguraFlat = _ultimaLarguraFlat;
    });
  }

  /// Faixa de largura da última vez que a tela foi medida. Só a *troca* de
  /// faixa recolhe o accordion sozinho — dentro da mesma faixa, o que a pessoa
  /// abriu continua aberto.
  bool? _eraEstreito;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final estreito = MediaQuery.sizeOf(context).width < Breakpoint.flatEmbaixo;
    if (estreito == _eraEstreito) return;
    _eraEstreito = estreito;
    // Numa coluna estreita o painel cobriria o gráfico inteiro, então ele entra
    // recolhido. Sem `setState`: o build já vem logo depois deste callback.
    if (estreito) _aberto = null;
  }

  void _alternarPainel(_Painel painel) {
    setState(() {
      _aberto = _aberto == painel ? null : painel;
      if (_aberto != null) _ultimo = _aberto;
      // Abriu ou fechou de verdade: a prévia perdeu a razão de existir.
      _espiandoHistorico = false;
    });
  }

  /// Abre/fecha sem trocar de painel. Sem nada aberto e sem nada lembrado não
  /// há painel padrão pra escolher sozinho — o botão fica inerte.
  void _alternarTrilho() {
    if (_aberto == null && _ultimo == null) return;
    setState(() {
      _aberto = _aberto == null ? _ultimo : null;
      _espiandoHistorico = false;
    });
  }

  // Histórico persistido — buscado do backend, não só em memória
  List<PredictionSummary> _historicoItems = [];
  bool _carregandoHistorico = false;

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
    // O aviso vive no Overlay, fora desta tela: sair sem fechar deixaria a
    // caixa pendurada na próxima rota.
    fecharAviso();
    _estadoAccordion.dispose();
    _nomeExperimento.dispose();
    for (final ctrl in _controladores.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _avisar(String mensagem) => mostrarAviso(context, mensagem);

  /// Relê o histórico do navegador. Sem rede no meio, é rápido o bastante pra
  /// rodar a cada mudança em vez de manter dois estados em sincronia.
  Future<void> _fetchHistory() async {
    setState(() => _carregandoHistorico = true);
    final entradas = await _historicoLocal.listar();
    if (!mounted) return;
    setState(() {
      _entradas = entradas;
      _historicoItems = [
        for (final e in entradas) PredictionSummary.doLocal(e),
      ];
      _carregandoHistorico = false;
    });
  }

  Future<void> _deletarPredicao(int id) async {
    await _historicoLocal.apagar(id);
    if (!mounted) return;
    if (_entradaEmTela?.id == id) setState(() => _entradaEmTela = null);
    // Apagou o que estava sobreposto: a comparação perdeu o outro lado.
    if (_idComparacao == id) _removerComparacao();
    await _fetchHistory();
  }

  void _resetarValores() {
    for (final entry in textosPadrao().entries) {
      _controladores[entry.key]?.text = entry.value;
    }
  }

  /// Exportar precisa do resultado inteiro, que só existe numa predição em
  /// tela. Sem uma, o botão fica apagado.
  void _exportar() {
    final entrada = _entradaEmTela;
    if (entrada == null) return;
    abrirDialogoExportar(
      context,
      nome: entrada.nome,
      resultado: _binarioEmTela,
    );
  }

  // GlobalKey em vez de Builder — abre os drawers sem precisar de um context extra
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Painel de parâmetros reutilizado nos layouts. `onRodar` só é passado onde
  // o painel cobre a tela e precisa sair da frente antes de rodar.
  Widget _painelParametros({bool moldurado = true, VoidCallback? onRodar}) {
    return ParametersPanel(
      controladores: _controladores,
      onResetar: _resetarValores,
      podeExportar: _entradaEmTela != null,
      onExportar: _exportar,
      moldurado: moldurado,
      estado: _estadoAccordion,
      nome: _nomeExperimento,
      onRodar: onRodar ?? _rodar,
      onCarregarPreset: _abrirPresets,
      onSalvarPreset: _salvarPreset,
    );
  }

  /// Nome do experimento, ou um automático com a hora — é o que vai pro
  /// histórico e o que dá pra reconhecer na lista depois.
  String _nomeDoExperimento() {
    final digitado = _nomeExperimento.text.trim();
    if (digitado.isNotEmpty) return digitado;
    return 'Experimento ${DateFormat('dd/MM/yy HH:mm').format(DateTime.now())}';
  }

  /// Roda a predição e guarda o que voltou no navegador.
  Future<void> _rodar() async {
    final inputs = <String, double>{};
    for (final (chave, def) in camposAtivos()) {
      final texto = _controladores[chave]!.text;
      if (!campoValido(def, texto)) {
        _avisar('Corrija $chave antes de rodar: ${erroDoCampo(def, texto)}');
        return;
      }
      inputs[chave] = lerNumero(texto)!;
    }

    _avisar('Rodando...');
    try {
      // A rede roda aqui mesmo, no navegador: não há mais backend de predição.
      final binario = await PreditorOnnx.instancia.predizer(inputs);
      final entrada = await _historicoLocal.salvar(
        nome: _nomeDoExperimento(),
        inputs: inputs,
        // O resultado agora É o binário — não existe mais o dicionário de 22
        // campos que o `/predict` antigo devolvia.
        resultado: const {},
        binario: binario.paraJson(),
      );
      if (!mounted) return;
      setState(() {
        _entradaEmTela = entrada;
        _binarioEmTela = binario;
      });
      await _fetchHistory();
      if (mounted) {
        _avisar(
          binario.avisos.isEmpty
              ? 'Predição salva no histórico deste navegador.'
              : 'Rodou com ${binario.avisos.length} parâmetro(s) fora da '
                    'faixa de treino.',
        );
      }
    } catch (e) {
      if (mounted) _avisar('$e');
    }
  }

  // --- Comparação com um experimento do histórico ---

  /// Curvas de uma entrada do histórico. Entradas antigas (gravadas antes de o
  /// campo existir) não têm o formato binário; nesse caso não há o que
  /// sobrepor.
  ResultadoBinario? _binarioDe(EntradaHistorico entrada) =>
      entrada.binario.isEmpty ? null : ResultadoBinario.deJson(entrada.binario);

  Future<void> _escolherComparacao() async {
    if (_entradas.isEmpty) {
      _avisar('Nenhum experimento salvo. Rode uma predição primeiro.');
      return;
    }

    final escolhida = await showDialog<EntradaHistorico>(
      context: context,
      builder: (ctx) => _DialogoComparar(entradas: _entradas),
    );
    if (escolhida == null || !mounted) return;

    final binario = _binarioDe(escolhida);
    if (binario == null) {
      _avisar('"${escolhida.nome}" foi salvo antes das curvas comparáveis.');
      return;
    }
    setState(() {
      _comparacao = binario;
      _nomeComparacao = escolhida.nome;
      _idComparacao = escolhida.id;
      // Abre o histórico no trilho: daqui em diante trocar de experimento
      // comparado é um clique na lista, sem passar pelo modal de novo.
      _aberto = _Painel.historico;
      _ultimo = _Painel.historico;
      _espiandoHistorico = false;
    });
  }

  /// Troca o experimento sobreposto. É o que um clique na lista faz enquanto a
  /// comparação está ativa — o "atual" só muda depois de tirar a comparação.
  void _trocarComparacao(int id) {
    final entrada = _entradas.where((e) => e.id == id).firstOrNull;
    if (entrada == null) return;
    final binario = _binarioDe(entrada);
    if (binario == null) {
      _avisar('"${entrada.nome}" foi salvo antes das curvas comparáveis.');
      return;
    }
    setState(() {
      _comparacao = binario;
      _nomeComparacao = entrada.nome;
      _idComparacao = id;
    });
  }

  /// Clique num item do painel do trilho. Com comparação ativa a lista é um
  /// seletor de comparado; sem ela, carrega a predição como sempre.
  void _clicarNoHistorico(int id) =>
      _comparacao == null ? _mostrarPredicao(id) : _trocarComparacao(id);

  void _removerComparacao() => setState(() {
    _comparacao = null;
    _nomeComparacao = null;
    _idComparacao = null;
  });

  // --- Presets ---

  Future<void> _salvarPreset() async {
    final nome = _nomeExperimento.text.trim();
    if (nome.isEmpty) {
      _avisar('Dê um nome ao experimento pra salvar o preset.');
      return;
    }
    await _presets.salvar(nome, {
      for (final e in _controladores.entries) e.key: e.value.text,
    });
    if (mounted) _avisar('Preset salvo: $nome');
  }

  Future<void> _abrirPresets() async {
    final salvos = await _presets.listar();
    if (!mounted) return;
    if (salvos.isEmpty) {
      _avisar('Nenhum preset salvo neste navegador ainda.');
      return;
    }

    final escolhido = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Carregar preset'),
        children: [
          for (final nome in salvos.keys)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, nome),
              child: Text(nome),
            ),
        ],
      ),
    );
    if (escolhido == null) return;

    for (final e in salvos[escolhido]!.entries) {
      _controladores[e.key]?.text = e.value;
    }
    _nomeExperimento.text = escolhido;
    if (mounted) _avisar('Preset carregado: $escolhido');
  }

  // Em telas menores os parâmetros ficam num bottom sheet, que cobre 85% da
  // altura: rodar sem fechá-lo deixaria o resultado atrás da folha.
  void _abrirParametrosMobile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(Espaco.campo),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: _painelParametros(
            onRodar: () {
              Navigator.pop(ctx);
              _rodar();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Uma leitura só de largura serve o corpo e a escolha do drawer. O corpo
    // ocupa a tela inteira, então isto é o mesmo que o LayoutBuilder media.
    final largura = MediaQuery.sizeOf(context).width;
    // A tela binária (trilho + accordion + gráficos + flat) vale de tablet pra
    // cima; ela mesma se reorganiza conforme a largura. Abaixo disso o layout
    // compacto mostra a mesma zona de resultados em coluna única.
    final largo = largura >= Breakpoint.tablet;

    return Scaffold(
      key: _scaffoldKey,
      appBar: Topbar(
        // Só o layout largo tem trilho — no compacto o alternar não teria o
        // que fazer.
        painelAberto: largo ? _aberto != null : null,
        onAlternarPainel: largo ? _alternarTrilho : null,
      ),
      endDrawer: HistoryDrawer(
        items: _historicoItems,
        carregando: _carregandoHistorico,
        onRefresh: _fetchHistory,
        onDelete: _deletarPredicao,
        // O drawer se fecha sozinho depois de carregar
        onCarregarPredicao: _mostrarPredicao,
        nomeDe: _nomeDe,
        onRenomear: _renomear,
      ),
      body: FundoPontilhado(
        child: largo ? _layoutDesktop() : _layoutCompacto(largura),
      ),
    );
  }

  /// Layout compacto: as três ações continuam à mostra no cabeçalho. Aqui o
  /// toque é caro e a tela é estreita demais pra ceder uma faixa fixa ao
  /// trilho. Num celular os dois rótulos mais o "Exportar" não cabem na
  /// linha, e aí sobram os ícones.
  Widget _acoes({required bool comRotulo}) {
    void abrirHistorico() => _scaffoldKey.currentState?.openEndDrawer();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (comRotulo) ...[
          TextButton.icon(
            onPressed: _abrirParametrosMobile,
            icon: const Icon(Icons.tune, size: Icone.m),
            label: const Text('Parâmetros'),
          ),
          TextButton.icon(
            onPressed: abrirHistorico,
            icon: const Icon(Icons.history, size: Icone.m),
            label: const Text('Histórico'),
          ),
        ] else ...[
          IconButton(
            tooltip: 'Parâmetros de entrada',
            onPressed: _abrirParametrosMobile,
            icon: const Icon(Icons.tune, size: Icone.m),
          ),
          IconButton(
            tooltip: 'Histórico de predições',
            onPressed: abrirHistorico,
            icon: const Icon(Icons.history, size: Icone.m),
          ),
        ],
        const SizedBox(width: Espaco.xxs),
        ExportButton(habilitado: _entradaEmTela != null, onExport: _exportar),
      ],
    );
  }

  /// Tela binária. A largura decide onde o painel flat mora: ao lado enquanto
  /// sobra coluna central pro gráfico, embaixo quando não sobra. Como o
  /// accordion recolhido devolve 380px, fechar ele pode trazer o flat de volta
  /// pra lateral sem a janela mudar de tamanho.
  Widget _layoutDesktop() {
    return LayoutBuilder(
      builder: (context, restricoes) {
        final larguraAccordion = _aberto == null
            ? 0.0
            : Dim.larguraPainelParametros;
        // O que o painel pode ocupar sem espremer o gráfico. Vira o teto do
        // arraste: a alça trava aqui em vez de deixar a coluna central virar
        // uma tira.
        final teto =
            (restricoes.maxWidth -
                    Dim.larguraRail -
                    larguraAccordion -
                    Breakpoint.centroMinimo)
                .clamp(Dim.larguraMinPainelFlat, Dim.larguraMaxPainelFlat);
        return _corpoBinario(
          larguraFlat: _larguraFlat.clamp(Dim.larguraMinPainelFlat, teto),
          teto: teto,
          naLateral:
              restricoes.maxWidth >= Breakpoint.flatEmbaixo &&
              restricoes.maxWidth -
                      Dim.larguraRail -
                      larguraAccordion -
                      Dim.larguraMinPainelFlat >=
                  Breakpoint.centroMinimo,
        );
      },
    );
  }

  Widget _corpoBinario({
    required double larguraFlat,
    required double teto,
    required bool naLateral,
  }) {
    final cores = context.cores;

    // Na lateral a largura vem do arraste, e o `OverflowBox` abaixo já a impõe;
    // embaixo, o painel ocupa o que o pai der.
    final flat = PainelFlatParametros(
      controladores: _controladores,
      naLateral: naLateral,
      onComparar: _escolherComparacao,
      onExportar: _entradaEmTela == null ? null : _exportar,
      // Mesma ação do "Rodar modelo" do accordion: com o painel esquerdo
      // recolhido, este é o único jeito de disparar.
      onRodar: _rodar,
    );
    // Coluna central: a mesma zona que o layout compacto mostra. Até a
    // primeira predição são as curvas sintéticas do `ResultadoBinario.exemplo()`.
    final centro = EntradaSuave(atrasoMs: 60, child: _zonaResultados());

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Trilho colado na borda, sem padding em volta — a moldura da tela
            // começa só depois dele.
            RailLateral(
              onEspiar: (i) => setState(() => _espiandoHistorico = i != null),
              itens: [
                ItemRail(
                  icone: Icons.tune,
                  rotulo: 'Parâmetros de entrada',
                  ativo: _aberto == _Painel.parametros,
                  onTap: () => _alternarPainel(_Painel.parametros),
                  // Mudo no hover: o painel de parâmetros é alto e denso, e
                  // a prévia dele só mostrava o topo cortado — informação de
                  // menos pra atrapalhar tanto. Um clique abre o painel
                  // inteiro, que é o que a pessoa quer de qualquer forma.
                  flutuante: false,
                ),
                ItemRail(
                  icone: Icons.history,
                  rotulo: 'Histórico de predições',
                  ativo: _aberto == _Painel.historico,
                  onTap: () => _alternarPainel(_Painel.historico),
                ),
                // Abre modal em vez de painel: o lote é um desvio de fluxo
                // (sobe planilha, roda, baixa) e não some pra dentro do
                // trilho como os dois de cima.
                ItemRail.acao(
                  icone: Icons.dataset_outlined,
                  rotulo: 'Predição em lote',
                  onTap: () => abrirDialogoLote(context),
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
                        _historico(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Na lateral, o flat é a quarta coluna; embaixo, ele divide a
            // vertical com o gráfico. Nos dois casos são os mesmos
            // controladores do accordion, sem estado duplicado no meio.
            Expanded(
              child: naLateral
                  ? centro
                  // Embaixo, o gráfico fica com a maior parte da vertical, mas
                  // o flat precisa de altura pra mostrar tabela e não só as
                  // ações. Os dois rolam por dentro.
                  : Column(
                      children: [
                        Expanded(flex: 3, child: centro),
                        Expanded(flex: 2, child: flat),
                      ],
                    ),
            ),
            if (naLateral) ...[
              // Colapsado, a alça sai de cena e a tira com a seta toma o lugar
              // do painel — sem ela não haveria como trazê-lo de volta.
              if (_flatColapsado)
                BotaoAbrirFlat(onAbrir: _abrirFlat)
              else
                AlcaPainelFlat(
                  onComecar: _comecarArrasteFlat,
                  onArrastar: (dx) => _arrastarFlat(dx, teto),
                  onTerminar: () => setState(() => _arrastandoFlat = false),
                ),
              // Durante o arraste a largura tem que acompanhar o cursor no
              // mesmo frame; a animação fica só pro colapso. O `OverflowBox`
              // segura o conteúdo na largura de destino pra ele não se
              // reorganizar enquanto o painel fecha.
              AnimatedContainer(
                duration: _arrastandoFlat ? Duration.zero : Duracao.media,
                curve: Curves.easeInOut,
                width: _flatColapsado ? 0 : larguraFlat,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: larguraFlat,
                    maxWidth: larguraFlat,
                    child: flat,
                  ),
                ),
              ),
            ],
          ],
        ),
        // Prévia por cima de tudo: mostra o que tem lá dentro sem abrir nada.
        if (_espiandoHistorico)
          Positioned(
            left: Dim.larguraRail + Espaco.sm,
            top: Espaco.lg,
            child: _peekHistorico(),
          ),
      ],
    );
  }

  /// Traz uma predição do histórico pra tela. Serve o painel do trilho e o
  /// drawer, que só diferem em fechar ou não depois. A entrada inteira já está
  /// em memória — inclusive os parâmetros que a geraram, que voltam pros campos.
  void _mostrarPredicao(int id) {
    final entrada = _entradas.where((e) => e.id == id).firstOrNull;
    if (entrada == null) return;

    final binario = _binarioDe(entrada);
    setState(() {
      _entradaEmTela = entrada;
      if (binario != null) _binarioEmTela = binario;
      _nomeExperimento.text = entrada.nome;
    });
    for (final e in entrada.inputs.entries) {
      final valor = e.value;
      if (valor is num) {
        _controladores[e.key]?.text = formatarNumero(valor.toDouble());
      }
    }
  }

  /// Histórico sem moldura, pro painel do trilho. Fica aberto depois de
  /// carregar — é painel fixo, não sai da frente de ninguém.
  Widget _historico() => HistoricoConteudo(
    items: _historicoItems,
    carregando: _carregandoHistorico,
    onRefresh: _fetchHistory,
    onDelete: _deletarPredicao,
    onCarregarPredicao: _clicarNoHistorico,
    comparandoId: _idComparacao,
    nomeDe: _nomeDe,
    onRenomear: _renomear,
  );

  /// Prévia do hover do trilho. Só o histórico tem uma: responde "tem o quê lá
  /// dentro?" sem abrir nada, e o que não couber a caixa corta.
  Widget _peekHistorico() => PeekPainel(
    titulo: 'Histórico',
    child: _carregandoHistorico
        ? const PeekLinha('Carregando...')
        : _historicoItems.isEmpty
        ? const PeekLinha('Nenhuma predição ainda')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final p in _historicoItems)
                _PreviaPredicao(item: p, nome: _nomeDe(p)),
            ],
          ),
  );

  /// Abaixo de 800px: a mesma zona de resultados do layout largo, em coluna
  /// única. Sem trilho e sem painel fixo — os parâmetros moram no bottom sheet
  /// e o histórico no drawer da direita, os dois abertos pela faixa de ações.
  Widget _layoutCompacto(double largura) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Espaco.campo,
            Espaco.xs,
            Espaco.campo,
            0,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: _acoes(comRotulo: largura >= Breakpoint.abasEmLinha),
          ),
        ),
        // A zona rola por dentro: ruptura, temperatura e os KPIs, empilhados
        // na ordem em que se lê o resultado.
        Expanded(child: EntradaSuave(child: _zonaResultados())),
      ],
    );
  }

  /// As curvas e os KPIs do experimento em tela. É a mesma zona nos dois
  /// layouts: o que muda em volta é onde os parâmetros moram, não o resultado.
  Widget _zonaResultados() => ZonaResultados(
    resultado: _binarioEmTela,
    comparacao: _comparacao,
    nomeComparacao: _nomeComparacao,
    onRemoverComparacao: _removerComparacao,
  );
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

/// Escolha do experimento a sobrepor. Lista o histórico do navegador com o que
/// distingue um run do outro: nome, quando rodou, e os dois números que a
/// pessoa está comparando de qualquer forma.
class _DialogoComparar extends StatelessWidget {
  final List<EntradaHistorico> entradas;
  const _DialogoComparar({required this.entradas});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return AlertDialog(
      backgroundColor: cores.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Raio.painel),
        side: BorderSide(color: cores.line, width: Borda.fina),
      ),
      // Estilo explícito: o `titleTextStyle` que o Material herda sai quase
      // apagado sobre esta superfície.
      title: Text(
        'Comparar com',
        style: TextStyle(
          fontFamily: 'IBMPlexSans',
          fontSize: Tipo.titulo,
          fontWeight: FontWeight.w600,
          color: cores.text,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: Espaco.sm),
      content: SizedBox(
        width: Dim.larguraCardParametros,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: entradas.length,
          itemBuilder: (_, i) => _ItemComparar(entrada: entradas[i]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _ItemComparar extends StatelessWidget {
  final EntradaHistorico entrada;
  const _ItemComparar({required this.entrada});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final binario = entrada.binario;
    final tBreak = (binario['t_break'] as num?)?.toStringAsFixed(1);
    final severidade = (binario['severidade'] as num?)?.toStringAsFixed(2);
    final quando = DateFormat(
      'dd/MM/yy HH:mm',
    ).format(entrada.criadoEm.toLocal());

    return Hover(
      builder: (emHover) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => Navigator.pop(context, entrada),
          child: Container(
            color: emHover ? cores.panel3 : Colors.transparent,
            padding: const EdgeInsets.symmetric(
              horizontal: Espaco.lg,
              vertical: Espaco.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entrada.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSans',
                    fontSize: Tipo.corpo,
                    color: cores.text,
                  ),
                ),
                const SizedBox(height: Espaco.xxs),
                Text(
                  [
                    quando,
                    if (tBreak != null) 't_break $tBreak s',
                    if (severidade != null) 'sev. $severidade',
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: Tipo.eixo,
                    color: cores.text3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
