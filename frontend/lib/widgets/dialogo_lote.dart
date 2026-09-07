// dialogo_lote.dart — modal de predição em lote: sobe planilha, roda, baixa.
//
// Tudo acontece no navegador: o parse da planilha, a rede e a exportação. Não
// há servidor no caminho — ver `inferencia/lote_local.dart`.
//
// O lote é efêmero de propósito: entra arquivo, sai arquivo. Nada disso vai
// pro histórico local — o histórico existe pra a predição única, que é a que
// se compara e se reabre.
import 'package:flutter/material.dart';

import '../inferencia/lote_local.dart';
import '../services/arquivo_local.dart';
import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'export_button.dart' show kFormatosExport;
import 'ui_comum.dart';

/// Acima disto o lote demora o bastante pra valer avisar antes de rodar.
const int _loteDemorado = 2000;

/// Extensões aceitas, na ordem em que aparecem pro usuário.
final List<String> _extensoes = [for (final f in kFormatosExport) f.formato];

/// Media type de cada formato.
String _mime(String formato) => formato == 'xlsx' ? mediaXlsx : mediaCsv;

/// Abre o modal de lote. Mesma entrada do gráfico ampliado: fade + escala.
void abrirDialogoLote(BuildContext context) =>
    abrirModal(context, const DialogoLote());

class DialogoLote extends StatefulWidget {
  const DialogoLote({super.key});

  @override
  State<DialogoLote> createState() => _DialogoLoteState();
}

class _DialogoLoteState extends State<DialogoLote> {
  int _aba = 0;

  ArquivoEscolhido? _arquivo;
  PreviaLote? _previa;

  // O que a exportação leva
  bool _escalares = true;
  bool _curvas = false;
  final Set<String> _colunas = {for (final (chave, _) in kEscalaresLote) chave};
  String _formato = 'xlsx';

  bool _rodando = false;
  bool _baixando = false;
  String? _erro;
  ResultadoLote? _resultado;

  @override
  void initState() {
    super.initState();
    // Soltar arquivo em qualquer canto do modal funciona; o canvas do Flutter
    // não repassa evento de arraste, então quem escuta é o documento.
    if (suportaArrastar) {
      aoArrastarArquivo((arquivo) {
        if (mounted) _usarArquivo(arquivo);
      });
    }
  }

  @override
  void dispose() {
    pararDeOuvirArraste();
    super.dispose();
  }

  // --- Arquivo ---

  Future<void> _selecionar() async {
    final arquivo = await escolherArquivo(_extensoes);
    if (arquivo != null && mounted) _usarArquivo(arquivo);
  }

  /// Funil único: o seletor filtra a extensão sozinho, mas o arraste entrega
  /// qualquer arquivo que a pessoa solte na página — a conferência vive aqui.
  void _usarArquivo(ArquivoEscolhido arquivo) {
    final nome = arquivo.nome.toLowerCase();
    if (!_extensoes.any((e) => nome.endsWith('.$e'))) {
      setState(
        () => _erro = 'Só aceito .csv ou .xlsx — "${arquivo.nome}" não serve.',
      );
      return;
    }

    // Agora que o parse é todo local, o .xlsx também tem prévia.
    PreviaLote? previa;
    try {
      previa = lerPrevia(arquivo.bytes, arquivo.nome);
    } catch (_) {
      previa = null; // arquivo ilegível: o erro aparece ao rodar
    }
    setState(() {
      _arquivo = arquivo;
      _previa = previa;
      _resultado = null;
      _erro = null;
    });
  }

  void _limpar() => setState(() {
    _arquivo = null;
    _previa = null;
    _resultado = null;
    _erro = null;
  });

  // --- Ações ---

  Future<void> _rodar() async {
    final arquivo = _arquivo;
    if (arquivo == null || _rodando) return;

    setState(() {
      _rodando = true;
      _erro = null;
      _resultado = null;
    });
    try {
      final linhas = lerPlanilha(arquivo.bytes, arquivo.nome);
      final resposta = await rodarLote(linhas);
      if (mounted) setState(() => _resultado = resposta);
    } catch (e) {
      if (mounted) setState(() => _erro = _mensagemAmigavel(e));
    } finally {
      if (mounted) setState(() => _rodando = false);
    }
  }

  Future<void> _baixarResultado() async {
    final resultado = _resultado;
    if (resultado == null || _baixando) return;

    setState(() => _baixando = true);
    final base = _nomeBase(_arquivo?.nome ?? 'lote');
    try {
      final escolhidos = _escalares ? _colunas : <String>{};
      final bytes = _formato == 'xlsx'
          ? loteParaXlsx(resultado, escolhidos, comCurvas: _curvas)
          : loteParaCsv(resultado, escolhidos);
      baixarBytes(bytes, '${base}_resultado.$_formato', _mime(_formato));
    } catch (e) {
      if (mounted) setState(() => _erro = _mensagemAmigavel(e));
    } finally {
      if (mounted) setState(() => _baixando = false);
    }
  }

  void _baixarTemplate(String formato) {
    try {
      final bytes = formato == 'xlsx' ? templateXlsx() : templateCsv();
      baixarBytes(bytes, 'template_lote.$formato', _mime(formato));
    } catch (e) {
      setState(() => _erro = _mensagemAmigavel(e));
    }
  }

  /// Tira a extensão pra usar o nome do arquivo como nome do resultado.
  String _nomeBase(String nome) {
    final ponto = nome.lastIndexOf('.');
    return ponto > 0 ? nome.substring(0, ponto) : nome;
  }

  /// `ErroDePlanilha` já sai pronto pra tela; o resto perde o "Exception: ".
  String _mensagemAmigavel(Object erro) => erro is ErroDePlanilha
      ? erro.mensagem
      : erro.toString().replaceFirst('Exception: ', '');

  // --- Tela ---

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return MolduraModal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: CabecalhoSecao(
                  eyebrow: 'Lote',
                  titulo: 'Predição em lote',
                ),
              ),
              BotaoFecharModal(onTap: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: Espaco.md),
          Row(
            children: [
              for (final (i, rotulo) in const [
                'Upload de arquivo',
                'Varredura',
              ].indexed)
                ChipAba(
                  rotulo: rotulo,
                  ativo: _aba == i,
                  onTap: () => setState(() => _aba = i),
                ),
            ],
          ),
          const SizedBox(height: Espaco.cartao),
          Divider(height: Borda.fina, color: cores.line),
          Flexible(child: _aba == 0 ? _abaUpload(cores) : _varredura()),
          if (_aba == 0) ...[
            Divider(height: Espaco.lg, color: cores.line),
            _rodape(),
          ],
        ],
      ),
    );
  }

  /// Varredura: gerar o lote aqui dentro variando parâmetros em faixas, em vez
  /// de subir planilha. A estrutura já existe (a rota de lote recebe N linhas
  /// de qualquer origem); falta combinar com o orientador o que se varia.
  ///
  /// Altura fixa, a mesma que a aba de upload tem de piso: dentro do
  /// `Flexible` um `Center` solto esticaria o modal até o teto, e sem altura
  /// nenhuma o modal encolheria à metade só de trocar de aba.
  Widget _varredura() => const SizedBox(
    height: Dim.alturaMinimaAbaLote + Dim.alturaBotaoPrimario,
    child: Center(
      child: AvisoVazio(
        icone: Icons.grid_on_outlined,
        titulo: 'Geração por varredura em desenvolvimento',
        dica:
            'Em breve você poderá fixar alguns parâmetros e variar outros em '
            'faixas, sem montar planilha.',
      ),
    ),
  );

  /// Dois blocos, na ordem da tarefa: de onde vem o lote e o que sai dele.
  /// Os erros de forma da planilha não aparecem aqui — quem os diz é o rodapé,
  /// junto do botão que eles bloqueiam.
  Widget _abaUpload(AppColors cores) {
    final previa = _previa;
    final arquivo = _arquivo;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: Espaco.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Dim.alturaMinimaAbaLote),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Cartao(
              titulo: 'Arquivo de entrada',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (arquivo == null)
                    _ZonaArquivo(onTap: _selecionar)
                  else
                    _CartaoArquivo(
                      arquivo: arquivo,
                      previa: previa,
                      onTrocar: _selecionar,
                      onLimpar: _limpar,
                    ),
                  if (previa != null) ...[
                    if (previa.totalLinhas <= kMaxLinhasLote &&
                        previa.totalLinhas > _loteDemorado) ...[
                      const SizedBox(height: Espaco.cartao),
                      _Mensagem(
                        icone: Icons.schedule,
                        cor: cores.text2,
                        texto:
                            '${previa.totalLinhas} linhas: o lote pode levar '
                            'alguns segundos. Pode rodar mesmo assim.',
                      ),
                    ],
                    if (previa.colunas.isNotEmpty) ...[
                      const SizedBox(height: Espaco.cartao),
                      _TabelaPrevia(previa: previa),
                    ],
                  ],
                  Divider(height: Espaco.xl, color: cores.line),
                  _LinhaTemplate(onBaixar: _baixarTemplate),
                ],
              ),
            ),
            const SizedBox(height: Espaco.cartao),
            _Cartao(titulo: 'O que exportar', child: _seletorSaida(cores)),

            if (_erro != null) ...[
              const SizedBox(height: Espaco.cartao),
              _Mensagem(
                icone: Icons.error_outline,
                cor: cores.erro,
                texto: _erro!,
              ),
            ],
            if (_resultado != null) ...[
              const SizedBox(height: Espaco.cartao),
              _CartaoResumo(resultado: _resultado!),
            ],
          ],
        ),
      ),
    );
  }

  /// Seletor de saída: o que vai pro arquivo e em que formato baixar.
  /// É método, não widget: os quatro campos e os quatro setters são estado
  /// deste modal e não se repetem em lugar nenhum.
  Widget _seletorSaida(AppColors cores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Caixa(
          rotulo: 'Escalares',
          detalhe: 'tempos, πmax e severidade de cada experimento',
          marcada: _escalares,
          onMudar: (v) => setState(() => _escalares = v),
        ),
        // Recuo pra os seis nomes se lerem como filhos de "Escalares".
        if (_escalares)
          Padding(
            padding: const EdgeInsets.only(left: Espaco.xl, top: Espaco.xs),
            child: Wrap(
              spacing: Espaco.md,
              runSpacing: Espaco.xs,
              children: [
                for (final (chave, rotulo) in kEscalaresLote)
                  _Caixa(
                    rotulo: rotulo,
                    mono: true,
                    chip: true,
                    marcada: _colunas.contains(chave),
                    // Desmarcar a última deixaria a planilha só com o nome.
                    onMudar: _colunas.length == 1 && _colunas.contains(chave)
                        ? null
                        : (marcada) => setState(() {
                            if (marcada) {
                              _colunas.add(chave);
                            } else {
                              _colunas.remove(chave);
                            }
                          }),
                  ),
              ],
            ),
          ),
        const SizedBox(height: Espaco.campo),
        _Caixa(
          rotulo: 'Curvas completas',
          detalhe: '100 pontos de t, y_forte, y_carrier e T_out',
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
            _Segmentado(
              escolhido: _formato,
              onEscolher: (f) => setState(() => _formato = f),
            ),
          ],
        ),
        if (_curvas && _formato == 'csv')
          Padding(
            padding: const EdgeInsets.only(top: Espaco.xs),
            child: Text(
              'O CSV sai só com os escalares — 400 colunas por linha não viram '
              'planilha. Escolha XLSX pra levar as curvas.',
              style: TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: Tipo.corpo,
                color: cores.text3,
              ),
            ),
          ),
      ],
    );
  }

  /// Barra de ação: à esquerda o estado do arquivo, à direita o que se pode
  /// fazer com ele. O botão sozinho não dizia por que estava apagado.
  Widget _rodape() {
    final cores = context.cores;
    final previa = _previa;
    // Arquivo ilegível não tem prévia: aí quem confere é o parse, ao rodar.
    final aceitavel =
        previa == null ||
        (previa.valida && previa.totalLinhas <= kMaxLinhasLote);
    final pronto = _arquivo != null && !_rodando && aceitavel;

    return Row(
      children: [
        Expanded(child: _EstadoLote(estado: _estado(cores, previa))),
        const SizedBox(width: Espaco.cartao),
        if (_resultado != null) ...[
          SizedBox(
            width: Dim.larguraBotaoModal,
            child: BotaoContorno(
              texto: _baixando ? 'Baixando...' : 'Baixar resultado',
              icone: Icons.download_outlined,
              onTap: _baixarResultado,
            ),
          ),
          const SizedBox(width: Espaco.sm),
        ],
        SizedBox(
          width: Dim.larguraBotaoModal,
          child: BotaoPrimario(
            texto: 'Rodar lote',
            icone: Icons.play_arrow_rounded,
            carregando: _rodando,
            onTap: pronto ? _rodar : null,
          ),
        ),
      ],
    );
  }

  /// O que o rodapé diz, na ordem em que a pessoa esbarra nos casos.
  _Estado _estado(AppColors cores, PreviaLote? previa) {
    if (_rodando) {
      final linhas = previa?.totalLinhas;
      return _Estado(
        texto: linhas != null
            ? 'Processando $linhas predições...'
            : 'Processando o lote...',
        cor: cores.text2,
      );
    }
    if (_arquivo == null) {
      return _Estado(texto: 'Selecione um arquivo para começar');
    }
    if (previa == null) {
      return _Estado(
        texto: 'Arquivo carregado — as colunas são conferidas ao rodar',
        cor: cores.data4,
        bolinha: true,
      );
    }
    if (previa.faltando.isNotEmpty) {
      return _Estado(
        texto: previa.faltando.length == 1
            ? 'Falta a coluna ${previa.faltando.first}'
            : 'Faltam ${previa.faltando.length} colunas: '
                  '${previa.faltando.join(', ')}',
        cor: cores.erro,
        bolinha: true,
      );
    }
    if (previa.totalLinhas > kMaxLinhasLote) {
      return _Estado(
        texto:
            '${previa.totalLinhas} linhas — o lote aceita até '
            '$kMaxLinhasLote de uma vez',
        cor: cores.erro,
        bolinha: true,
      );
    }
    return _Estado(
      texto: 'Pronto — ',
      destaque: '${previa.totalLinhas}',
      sufixo: previa.totalLinhas == 1
          ? ' experimento detectado'
          : ' experimentos detectados',
      cor: cores.data4,
      bolinha: true,
    );
  }
}

/// O que o rodapé mostra à esquerda do botão. `destaque` sai em mono: é a
/// contagem, e número é o que se procura na frase.
class _Estado {
  final String texto;
  final String? destaque;
  final String? sufixo;
  final Color? cor;
  final bool bolinha;

  const _Estado({
    required this.texto,
    this.destaque,
    this.sufixo,
    this.cor,
    this.bolinha = false,
  });
}

/// Bolinha de estado + frase. Sem arquivo não há bolinha nenhuma: nada
/// aconteceu ainda, e um ponto neutro sugeriria o contrário.
class _EstadoLote extends StatelessWidget {
  final _Estado estado;
  const _EstadoLote({required this.estado});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final cor = estado.cor ?? cores.text3;
    final base = TextStyle(
      fontFamily: 'IBMPlexSans',
      fontSize: Tipo.corpo,
      height: 1.4,
      color: cor,
    );

    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          if (estado.bolinha) ...[
            Container(
              width: Espaco.sm,
              height: Espaco.sm,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            ),
            const SizedBox(width: Espaco.sm),
          ],
          Expanded(
            child: Text.rich(
              TextSpan(
                text: estado.texto,
                children: [
                  if (estado.destaque != null)
                    TextSpan(
                      text: estado.destaque,
                      style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: Tipo.dado,
                        fontWeight: FontWeight.w600,
                        color: cores.text,
                      ),
                    ),
                  if (estado.sufixo != null) TextSpan(text: estado.sufixo),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: base,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card do modal: o eyebrow nomeia o bloco e o conteúdo vem embaixo. Os dois
/// da aba de upload usam o mesmo desenho — um é a entrada, o outro a saída.
class _Cartao extends StatelessWidget {
  final String titulo;
  final Widget child;
  const _Cartao({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Container(
      padding: const EdgeInsets.all(Espaco.md),
      decoration: BoxDecoration(
        color: cores.panel2,
        border: Border.all(color: cores.line, width: Borda.fina),
        borderRadius: BorderRadius.circular(Raio.cartao),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(titulo),
          const SizedBox(height: Espaco.md),
          child,
        ],
      ),
    );
  }
}

/// Formato do arquivo em dois segmentos colados. Diferente dos `ChipAba` de
/// cima, que trocam de aba: aqui os dois são a mesma pergunta, e o trilho em
/// volta é o que diz isso.
class _Segmentado extends StatelessWidget {
  final String escolhido;
  final ValueChanged<String> onEscolher;

  const _Segmentado({required this.escolhido, required this.onEscolher});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Container(
      height: Dim.alturaBotaoCompacto,
      decoration: BoxDecoration(
        border: Border.all(color: cores.line2, width: Borda.fina),
        borderRadius: BorderRadius.circular(Raio.controle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final f in kFormatosExport.reversed)
            _segmento(cores, f.formato, f.rotulo),
        ],
      ),
    );
  }

  Widget _segmento(AppColors cores, String formato, String rotulo) {
    final ativo = escolhido == formato;

    return Semantics(
      button: true,
      selected: ativo,
      label: rotulo,
      child: Hover(
        builder: (emHover) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onEscolher(formato),
            child: AnimatedContainer(
              duration: Duracao.rapida,
              width: Dim.larguraSegmento,
              alignment: Alignment.center,
              color: ativo
                  ? cores.accent
                  : emHover
                  ? cores.panel3
                  : Colors.transparent,
              child: Text(
                rotulo,
                style: TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: Tipo.corpo,
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
        ),
      ),
    );
  }
}

// --- Zona de arquivo ---

/// Alvo de arraste e clique. Borda tracejada porque é a convenção universal de
/// "solte aqui" — e o âmbar só entra no hover, que é quando vira ação.
class _ZonaArquivo extends StatelessWidget {
  final VoidCallback onTap;
  const _ZonaArquivo({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Hover(
      builder: (emHover) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: Duracao.rapida,
            height: Dim.alturaZonaArquivo,
            width: double.infinity,
            decoration: BoxDecoration(
              color: emHover ? cores.panel2 : Colors.transparent,
              borderRadius: BorderRadius.circular(Raio.cartao),
            ),
            child: CustomPaint(
              painter: _BordaTracejada(
                cor: emHover ? cores.accent : cores.line2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file_outlined,
                    size: Icone.g,
                    color: emHover ? cores.accentForte : cores.text3,
                  ),
                  const SizedBox(height: Espaco.sm),
                  Text(
                    suportaArrastar
                        ? 'Arraste a planilha aqui ou clique para escolher'
                        : 'Clique para escolher a planilha',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSans',
                      fontSize: Tipo.corpoGrande,
                      fontWeight: FontWeight.w600,
                      color: emHover ? cores.text : cores.text2,
                    ),
                  ),
                  const SizedBox(height: Espaco.xxs),
                  Text(
                    '.csv ou .xlsx',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: Tipo.label,
                      color: cores.text3,
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

/// Borda tracejada: o Flutter não tem `border-style: dashed`, então o traço é
/// desenhado direto no canvas seguindo o mesmo raio do card.
class _BordaTracejada extends CustomPainter {
  final Color cor;
  const _BordaTracejada({required this.cor});

  @override
  void paint(Canvas canvas, Size size) {
    final caneta = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = Borda.fina;

    final contorno = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(Raio.cartao),
        ),
      );

    const traco = 6.0;
    const vao = 5.0;
    for (final trecho in contorno.computeMetrics()) {
      var inicio = 0.0;
      while (inicio < trecho.length) {
        final fim = (inicio + traco).clamp(0.0, trecho.length);
        canvas.drawPath(trecho.extractPath(inicio, fim), caneta);
        inicio = fim + vao;
      }
    }
  }

  @override
  bool shouldRepaint(_BordaTracejada anterior) => anterior.cor != cor;
}

/// Arquivo escolhido: nome, tamanho e quantas linhas foram detectadas.
class _CartaoArquivo extends StatelessWidget {
  final ArquivoEscolhido arquivo;
  final PreviaLote? previa;
  final VoidCallback onTrocar;
  final VoidCallback onLimpar;

  const _CartaoArquivo({
    required this.arquivo,
    required this.previa,
    required this.onTrocar,
    required this.onLimpar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final linhas = previa?.totalLinhas;

    return Container(
      padding: const EdgeInsets.all(Espaco.campo),
      decoration: BoxDecoration(
        color: cores.panel2,
        border: Border.all(color: cores.line, width: Borda.fina),
        borderRadius: BorderRadius.circular(Raio.cartao),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: Icone.m, color: cores.text2),
          const SizedBox(width: Espaco.campo),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arquivo.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSans',
                    fontSize: Tipo.corpoGrande,
                    fontWeight: FontWeight.w600,
                    color: cores.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  linhas != null
                      ? '${arquivo.tamanhoLegivel} · $linhas '
                            '${linhas == 1 ? 'linha' : 'linhas'}'
                      : '${arquivo.tamanhoLegivel} · prévia só de .csv; '
                            'as colunas são conferidas ao rodar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: Tipo.label,
                    color: cores.text3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Espaco.sm),
          SizedBox(
            width: Dim.larguraBotaoCurto,
            child: BotaoContorno(
              texto: 'Trocar',
              altura: Dim.alturaBotaoCompacto,
              onTap: onTrocar,
            ),
          ),
          const SizedBox(width: Espaco.xs),
          IconButton(
            tooltip: 'Remover arquivo',
            icon: const Icon(Icons.close, size: Icone.m),
            onPressed: onLimpar,
          ),
        ],
      ),
    );
  }
}

/// Link pro modelo pronto. Existe pra ninguém adivinhar 31 nomes de coluna.
class _LinhaTemplate extends StatelessWidget {
  final void Function(String formato) onBaixar;
  const _LinhaTemplate({required this.onBaixar});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Espaco.sm,
      runSpacing: Espaco.xs,
      children: [
        Text(
          'Não sabe o formato?',
          style: TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: Tipo.corpo,
            color: cores.text2,
          ),
        ),
        for (final f in kFormatosExport.reversed)
          SizedBox(
            width: Dim.larguraBotaoTemplate,
            child: BotaoContorno(
              texto: 'Template ${f.rotulo}',
              icone: Icons.download_outlined,
              altura: Dim.alturaBotaoCompacto,
              onTap: () => onBaixar(f.formato),
            ),
          ),
      ],
    );
  }
}

/// Primeiras linhas do arquivo. Rola na horizontal porque são 31 colunas —
/// espremê-las na largura do modal deixaria cada número com dois dígitos.
class _TabelaPrevia extends StatelessWidget {
  final PreviaLote previa;
  const _TabelaPrevia({required this.previa});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Container(
      height: Dim.alturaPreviaLote,
      decoration: BoxDecoration(
        border: Border.all(color: cores.line, width: Borda.fina),
        borderRadius: BorderRadius.circular(Raio.campo),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linha(cores, previa.colunas, cabecalho: true),
            for (final linha in previa.amostra) _linha(cores, linha),
          ],
        ),
      ),
    );
  }

  Widget _linha(
    AppColors cores,
    List<String> celulas, {
    bool cabecalho = false,
  }) {
    return Container(
      color: cabecalho ? cores.panel2 : null,
      child: Row(
        children: [
          for (var i = 0; i < previa.colunas.length; i++)
            Container(
              width: Dim.larguraColunaPrevia,
              padding: const EdgeInsets.symmetric(
                horizontal: Espaco.sm,
                vertical: Espaco.xs,
              ),
              alignment: cabecalho
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Text(
                i < celulas.length ? celulas[i] : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: cabecalho ? Tipo.label : Tipo.dado,
                  fontWeight: cabecalho ? FontWeight.w600 : FontWeight.w500,
                  color: cabecalho ? cores.text2 : cores.text,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Caixa de marcação: quadrado que se enche de âmbar quando ligado. Vive aqui
/// porque só o seletor de saída marca coisas; se uma segunda tela precisar,
/// ela sobe pra `ui_comum.dart`.
/// `onMudar` nulo trava a caixa (o último escalar não pode ser desmarcado).
class _Caixa extends StatelessWidget {
  final String rotulo;
  final String? detalhe;
  final bool marcada;
  final bool mono;

  /// Desenha a caixa dentro de um chip com borda — é o que separa os seis
  /// escalares filhos das duas escolhas de primeiro nível.
  final bool chip;
  final ValueChanged<bool>? onMudar;

  const _Caixa({
    required this.rotulo,
    required this.marcada,
    this.detalhe,
    this.mono = false,
    this.chip = false,
    this.onMudar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final ativa = onMudar != null;

    return Semantics(
      checked: marcada,
      enabled: ativa,
      label: rotulo,
      child: Hover(
        builder: (emHover) => MouseRegion(
          cursor: ativa
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: GestureDetector(
            onTap: ativa ? () => onMudar!(!marcada) : null,
            child: AnimatedContainer(
              duration: Duracao.rapida,
              padding: chip
                  ? const EdgeInsets.symmetric(
                      horizontal: Espaco.sm,
                      vertical: Espaco.xs,
                    )
                  : EdgeInsets.zero,
              decoration: chip
                  ? BoxDecoration(
                      color: marcada ? cores.panel3 : Colors.transparent,
                      border: Border.all(
                        color: marcada
                            ? cores.accent.withValues(
                                alpha: Elevacao.bordaHover,
                              )
                            : cores.line2,
                        width: Borda.fina,
                      ),
                      borderRadius: BorderRadius.circular(Raio.chip),
                    )
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: Duracao.rapida,
                    width: chip ? Icone.pp : Icone.m,
                    height: chip ? Icone.pp : Icone.m,
                    decoration: BoxDecoration(
                      color: marcada ? cores.accent : Colors.transparent,
                      border: Border.all(
                        color: marcada
                            ? cores.accent
                            : emHover && ativa
                            ? cores.text2
                            : cores.line2,
                        width: Borda.fina,
                      ),
                      borderRadius: BorderRadius.circular(Raio.chip),
                    ),
                    child: marcada
                        ? Icon(
                            Icons.check,
                            size: chip ? Tipo.label : Icone.pp,
                            color: cores.onAccent,
                          )
                        : null,
                  ),
                  SizedBox(width: chip ? Espaco.xs : Espaco.sm),
                  Text(
                    rotulo,
                    style: TextStyle(
                      fontFamily: mono ? 'IBMPlexMono' : 'IBMPlexSans',
                      fontSize: mono ? Tipo.dado : Tipo.corpoGrande,
                      fontWeight: FontWeight.w600,
                      color: ativa ? cores.text : cores.text3,
                    ),
                  ),
                  if (detalhe != null) ...[
                    const SizedBox(width: Espaco.sm),
                    Text(
                      detalhe!,
                      style: TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontSize: Tipo.corpo,
                        color: cores.text3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Resultado ---

/// Resumo do que voltou. `tempo_ms` é o número que justifica a feature: mostra
/// o lote inteiro no tempo em que o solver não faz nem uma curva.
class _CartaoResumo extends StatelessWidget {
  final ResultadoLote resultado;
  const _CartaoResumo({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final total = resultado.total;
    final avisos = resultado.comAviso;
    final ms = resultado.tempoMs;

    return Container(
      padding: const EdgeInsets.all(Espaco.campo),
      decoration: BoxDecoration(
        color: cores.panel2,
        border: Border.all(color: cores.accent, width: Borda.fina),
        borderRadius: BorderRadius.circular(Raio.cartao),
      ),
      child: Wrap(
        spacing: Espaco.xl,
        runSpacing: Espaco.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: Icone.m,
                color: cores.accentForte,
              ),
              const SizedBox(width: Espaco.sm),
              Text(
                'Lote pronto',
                style: TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: Tipo.corpoGrande,
                  fontWeight: FontWeight.w600,
                  color: cores.text,
                ),
              ),
            ],
          ),
          _Numero(rotulo: 'predições', valor: '$total'),
          _Numero(
            rotulo: 'fora da faixa',
            valor: '$avisos',
            alerta: avisos > 0,
          ),
          _Numero(rotulo: 'na rede', valor: _tempo(ms)),
        ],
      ),
    );
  }

  String _tempo(int ms) =>
      ms < 1000 ? '$ms ms' : '${(ms / 1000).toStringAsFixed(1)} s';
}

class _Numero extends StatelessWidget {
  final String rotulo;
  final String valor;
  final bool alerta;
  const _Numero({
    required this.rotulo,
    required this.valor,
    this.alerta = false,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          valor,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: Tipo.corpoGrande,
            fontWeight: FontWeight.w600,
            color: alerta ? cores.data3 : cores.text,
          ),
        ),
        const SizedBox(width: Espaco.xs),
        Text(
          rotulo,
          style: TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: Tipo.corpo,
            color: cores.text3,
          ),
        ),
      ],
    );
  }
}

/// Linha de aviso, erro ou progresso. A cor vem de fora porque o desenho é o
/// mesmo — o que muda é o peso do que está sendo dito. `liveRegion` porque a
/// mensagem aparece sem a pessoa ter mexido no foco.
class _Mensagem extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String texto;
  const _Mensagem({
    required this.icone,
    required this.cor,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: Icone.p, color: cor),
          const SizedBox(width: Espaco.sm),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: Tipo.corpo,
                height: 1.4,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
