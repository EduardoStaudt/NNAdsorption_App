// parameters_panel.dart — painel com os accordions dos parâmetros de entrada.
//
// Os campos vêm de `models/param_defs.dart` (fonte da verdade: tabela do artigo
// Computers & Chem. Eng.). Hoje são 28 = 8 por componente × 2 + 12 fixos; subir
// `kNumComponentes` lá gera as sub-seções novas aqui sem tocar neste arquivo.
//
// A árvore tem dois níveis e cada um abre um item por vez:
//   Adsorvente ─┬─ Carreador (8 campos)
//               └─ Gás Forte  (8 campos)
//   Recheio                   (3 campos)
//   Operacao e Geometria      (9 campos)
import 'package:flutter/material.dart';
import '../models/param_defs.dart';
import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'export_button.dart';
import 'ui_comum.dart';

/// Folha da árvore: um título e os campos dele, já com a chave de payload.
typedef _Secao = ({String titulo, List<(String chave, ParamDef def)> campos});

/// Card de topo do painel, em duas formas.
sealed class _CardTopo {
  final String titulo;
  const _CardTopo(this.titulo);

  /// Todos os campos do card. A contagem de erro do cabeçalho soma estes — por
  /// isso um card aninhado devolve os das sub-seções, e o aviso sobe sozinho.
  List<(String, ParamDef)> get campos;
}

/// Os campos aparecem direto dentro do card.
class _CardSimples extends _CardTopo {
  @override
  final List<(String, ParamDef)> campos;
  const _CardSimples(super.titulo, this.campos);
}

/// Cada seção vira um accordion aninhado — é o caso do Adsorvente, que ganha
/// um bloco por componente.
class _CardAninhado extends _CardTopo {
  final List<_Secao> secoes;
  const _CardAninhado(super.titulo, this.secoes);

  @override
  List<(String, ParamDef)> get campos => [for (final s in secoes) ...s.campos];
}

/// Monta os cards na mesma ordem do payload: componentes, recheio, operação.
List<_CardTopo> _cards() => [
  _CardAninhado('Adsorvente', [
    for (var c = 1; c <= kNumComponentes; c++)
      (
        titulo: nomeComponente(c),
        campos: [
          for (final f in kPerComponentFields)
            (chaveComponente(f.baseKey, c), f),
        ],
      ),
  ]),
  _CardSimples('Recheio', [for (final f in kPackingFields) (f.baseKey, f)]),
  _CardSimples('Operação e Geometria', [
    for (final f in kOperationFields) (f.baseKey, f),
  ]),
];

/// Quais accordions estão abertos. Fica fora do widget porque a tela monta um
/// `ParametersPanel` por layout — o do trilho, o do drawer do tablet e o do
/// bottom sheet do mobile. Com estado próprio, o sheet nasceria no card 1 toda
/// vez que fosse reaberto, e redimensionar a janela perderia o que estava
/// aberto.
class EstadoAccordion extends ChangeNotifier {
  int? _cardAberto = 0;
  final List<int?> _secaoAberta;

  EstadoAccordion() : _secaoAberta = [for (final _ in _cards()) 0];

  int? get cardAberto => _cardAberto;
  int? secaoAberta(int card) => _secaoAberta[card];

  void abrirCard(int i) {
    _cardAberto = _cardAberto == i ? null : i;
    notifyListeners();
  }

  void abrirSecao(int card, int i) {
    _secaoAberta[card] = _secaoAberta[card] == i ? null : i;
    notifyListeners();
  }
}

class ParametersPanel extends StatefulWidget {
  final Map<String, TextEditingController> controladores;
  final VoidCallback onResetar;

  /// Exportar mora aqui no rodapé, ao lado do Resetar: as duas são ações sobre
  /// o experimento em tela, e é onde a mão já está quando o trabalho acaba.
  final bool podeExportar;
  final void Function(String formato) onExportar;

  /// `false` entrega o conteúdo sem a caixa do `Painel` — é como o painel do
  /// trilho o usa, encostado no trilho e sem canto arredondado no meio.
  final bool moldurado;

  /// Estado compartilhado dos accordions. Sem ele o painel cuida do próprio.
  final EstadoAccordion? estado;

  /// Nome do experimento em preparo. Vazio deixa o histórico usar o nome
  /// automático ("Predicao #NN").
  final TextEditingController nome;

  const ParametersPanel({
    super.key,
    required this.controladores,
    required this.onResetar,
    required this.podeExportar,
    required this.onExportar,
    required this.nome,
    this.moldurado = true,
    this.estado,
  });

  @override
  State<ParametersPanel> createState() => _ParametersPanelState();
}

class _ParametersPanelState extends State<ParametersPanel> {
  final _card = _cards();

  late final EstadoAccordion _estado = widget.estado ?? EstadoAccordion();

  @override
  void initState() {
    super.initState();
    _estado.addListener(_aoMudarEstado);
  }

  @override
  void dispose() {
    _estado.removeListener(_aoMudarEstado);
    // Só descarta o que é nosso — o compartilhado é de quem o criou
    if (widget.estado == null) _estado.dispose();
    super.dispose();
  }

  void _aoMudarEstado() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    final conteudo = Column(
      children: [
        // Cabeçalho da seção, como no mockup
        const Padding(
          padding: EdgeInsets.fromLTRB(Espaco.lg, Espaco.lg, Espaco.lg, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CabecalhoSecao(
              eyebrow: 'Entrada',
              titulo: 'Parâmetros de Entrada',
            ),
          ),
        ),
        // Nome do experimento antes dos grupos: é o rótulo do que vem abaixo
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Espaco.lg,
            Espaco.md,
            Espaco.lg,
            0,
          ),
          child: TextField(
            controller: widget.nome,
            style: TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: Tipo.corpoGrande,
              color: cores.text,
            ),
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Nome do experimento',
              hintText: 'opcional',
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Espaco.md),
            children: [
              for (var i = 0; i < _card.length; i++) ...[
                _Accordion(
                  numero: i + 1,
                  titulo: _card[i].titulo,
                  campos: _card[i].campos,
                  controladores: widget.controladores,
                  aberto: _estado.cardAberto == i,
                  onToggle: () => _estado.abrirCard(i),
                  corpo: _corpo(i),
                ),
                const SizedBox(height: Espaco.sm),
              ],
            ],
          ),
        ),
        // Ações sobre o experimento em tela, fixas no pé do painel
        Container(
          padding: const EdgeInsets.all(Espaco.md),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: cores.line, width: Borda.fina),
            ),
          ),
          child: Column(
            children: [
              const _BotaoRodarDesligado(),
              const SizedBox(height: Espaco.sm),
              Row(
                children: [
                  Expanded(
                    child: _BotaoFantasma(
                      texto: 'Resetar valores',
                      onTap: widget.onResetar,
                    ),
                  ),
                  const SizedBox(width: Espaco.sm),
                  ExportButton(
                    habilitado: widget.podeExportar,
                    onExport: widget.onExportar,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return widget.moldurado ? Painel(child: conteudo) : conteudo;
  }

  /// Miolo de um card: os campos direto, ou um accordion por sub-seção.
  Widget _corpo(int card) => switch (_card[card]) {
    _CardSimples(:final campos) => _campos(campos),
    _CardAninhado(:final secoes) => _subSecoes(card, secoes),
  };

  Widget _subSecoes(int card, List<_Secao> secoes) {
    final cores = context.cores;
    return Column(
      children: [
        for (var i = 0; i < secoes.length; i++) ...[
          if (i > 0) Divider(height: Borda.fina, color: cores.line),
          _Accordion(
            titulo: secoes[i].titulo,
            campos: secoes[i].campos,
            controladores: widget.controladores,
            aberto: _estado.secaoAberta(card) == i,
            onToggle: () => _estado.abrirSecao(card, i),
            corpo: _campos(secoes[i].campos),
          ),
        ],
      ],
    );
  }

  Widget _campos(List<(String, ParamDef)> campos) => Column(
    children: [
      for (final (chave, def) in campos)
        _CampoInput(def: def, controlador: widget.controladores[chave]!),
    ],
  );
}

/// Ação principal enquanto o modelo binário não existe: presente pra explicar o
/// fluxo, mas inerte. Sem âmbar — cor cheia em estado inativo é ruído, e o
/// Âmbar de Sinal fica reservado pra ação que de fato roda.
class _BotaoRodarDesligado extends StatelessWidget {
  const _BotaoRodarDesligado();

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          enabled: false,
          label: 'Rodar predição — indisponível',
          child: Container(
            height: Dim.alturaBotaoPrimario,
            decoration: BoxDecoration(
              color: cores.panel2,
              border: Border.all(color: cores.line, width: Borda.fina),
              borderRadius: BorderRadius.circular(Raio.controle),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: Icone.m, color: cores.text3),
                  const SizedBox(width: Espaco.xs),
                  Text(
                    'Rodar predição',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSans',
                      fontWeight: FontWeight.w600,
                      fontSize: Tipo.corpoGrande,
                      color: cores.text3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: Espaco.sm),
        Text(
          'Disponível quando o modelo binário ($kNumComponentes componentes, '
          '$totalParametros parâmetros) estiver treinado.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: Tipo.label,
            height: 1.5,
            color: cores.text3,
          ),
        ),
      ],
    );
  }
}

// Botão "fantasma": transparente com borda, esclarece no hover
class _BotaoFantasma extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  const _BotaoFantasma({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Hover(
      builder: (emHover) => EscalaAoClicar(
        child: GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: Duracao.rapida,
              height: Dim.alturaBotaoSecundario,
              decoration: BoxDecoration(
                border: Border.all(
                  color: emHover ? cores.text2 : cores.line2,
                  width: Borda.fina,
                ),
                borderRadius: BorderRadius.circular(Raio.controle),
              ),
              child: Center(
                child: Text(
                  texto,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSans',
                    fontWeight: FontWeight.w600,
                    fontSize: Tipo.corpo,
                    color: emHover ? cores.text : cores.text2,
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

/// Accordion dos dois níveis. Com `numero`, é um card de topo: fundo `panel2`,
/// borda e chip numerado. Sem `numero`, é uma sub-seção: sem caixa própria, só
/// a linha de cabeçalho — card dentro de card viraria ruído numa coluna de
/// 352px, e a hierarquia já se lê pelo recuo e pelo tamanho do título.
class _Accordion extends StatelessWidget {
  final int? numero;
  final String titulo;

  /// Campos usados só pela contagem de erro. Num card aninhado é a união dos
  /// campos das sub-seções, pra o erro não se esconder num nível fechado.
  final List<(String, ParamDef)> campos;
  final Map<String, TextEditingController> controladores;
  final bool aberto;
  final VoidCallback onToggle;
  final Widget corpo;

  const _Accordion({
    this.numero,
    required this.titulo,
    required this.campos,
    required this.controladores,
    required this.aberto,
    required this.onToggle,
    required this.corpo,
  });

  bool get _ehCard => numero != null;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    final conteudo = Column(
      children: [
        _cabecalho(context),
        // Corpo expandível (~300ms como no mockup)
        AnimatedCrossFade(
          duration: Duracao.lenta,
          sizeCurve: Curves.easeInOut,
          crossFadeState: aberto
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: _ehCard
                ? const EdgeInsets.fromLTRB(Espaco.sm, 0, Espaco.sm, Espaco.sm)
                // Sub-seção: recuo à esquerda alinha os campos com o título dela
                : const EdgeInsets.fromLTRB(Espaco.sm, 0, 0, Espaco.sm),
            child: corpo,
          ),
        ),
      ],
    );

    // Aberto = borda âmbar, nos dois níveis. É o mesmo gesto da aba selecionada
    // dos resultados, e é o que responde "onde eu estou" sem ler nada: uma
    // borda acesa na coluna inteira, e ela cerca o que está em edição.
    //
    // A sub-seção fechada não tem caixa nenhuma; o card fechado mantém o fio
    // `line`, senão ele sumiria no tema claro — `panel2` sobre `panel` dá 1.06:1
    // de contraste, ou seja, nada.
    if (!_ehCard) {
      return AnimatedContainer(
        duration: Duracao.media,
        margin: const EdgeInsets.symmetric(vertical: Espaco.xxs),
        decoration: BoxDecoration(
          border: Border.all(
            color: aberto ? cores.accent : Colors.transparent,
            width: Borda.fina,
          ),
          borderRadius: BorderRadius.circular(Raio.controle),
        ),
        child: conteudo,
      );
    }

    return AnimatedContainer(
      duration: Duracao.media,
      decoration: BoxDecoration(
        color: cores.panel2,
        border: Border.all(
          color: aberto ? cores.accent : cores.line,
          width: Borda.fina,
        ),
        borderRadius: BorderRadius.circular(Raio.cartao),
      ),
      child: conteudo,
    );
  }

  /// Linha clicável. `expanded` no Semantics é o que o leitor de tela anuncia
  /// e o que os testes leem pra checar a seleção única.
  Widget _cabecalho(BuildContext context) {
    final cores = context.cores;
    final numero = this.numero; // promove pra não precisar de `!` abaixo
    final ehCard = numero != null;

    // A camada de hover fica recuada da borda do card nos dois níveis. Sem
    // isso, o cabeçalho do card pintava `panel3` de ponta a ponta, encostando
    // na borda, enquanto o da sub-seção já vinha recuado 8px pelo padding do
    // corpo — e o de cima parecia uma faixa mais pesada, sem que nada no design
    // justificasse a diferença. O recuo externo compensa o padding interno, de
    // modo que o texto continua a 14px da borda do card.
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ehCard ? Espaco.sm : 0,
        vertical: ehCard ? Espaco.xxs : 0,
      ),
      child: Semantics(
        key: ValueKey('accordion-$titulo'),
        button: true,
        expanded: aberto,
        label: titulo,
        child: Hover(
          builder: (emHover) => GestureDetector(
            onTap: onToggle,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: Duracao.media,
                decoration: BoxDecoration(
                  color: emHover ? cores.panel3 : Colors.transparent,
                  borderRadius: BorderRadius.circular(Raio.controle),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: ehCard ? Espaco.xs : Espaco.sm,
                  vertical: ehCard ? Espaco.campo : Espaco.cartao,
                ),
                child: Row(
                  children: [
                    if (ehCard) ...[
                      // Chip do grupo — preenche accent quando aberto
                      AnimatedContainer(
                        duration: Duracao.media,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Espaco.xs,
                          vertical: Espaco.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: aberto ? cores.accent : Colors.transparent,
                          border: Border.all(
                            color: aberto ? cores.accent : cores.line2,
                            width: Borda.fina,
                          ),
                          borderRadius: BorderRadius.circular(Raio.chip),
                        ),
                        child: Text(
                          numero.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: Tipo.label,
                            color: aberto ? cores.onAccent : cores.text3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: Espaco.cartao),
                    ],
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontFamily: 'IBMPlexSans',
                          fontSize: ehCard ? Tipo.corpoGrande : Tipo.corpo,
                          fontWeight: FontWeight.w600,
                          color: ehCard ? cores.text : cores.text2,
                        ),
                      ),
                    ),
                    _ContagemDoGrupo(
                      campos: campos,
                      controladores: controladores,
                    ),
                    const SizedBox(width: Espaco.campo),
                    // Chevron animado
                    AnimatedRotation(
                      turns: aberto ? 0.25 : 0,
                      duration: Duracao.media,
                      child: Icon(
                        Icons.chevron_right,
                        size: ehCard ? Icone.m : Icone.p,
                        color: cores.text2,
                      ),
                    ),
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

/// Contador à direita do título. Vira "N com erro" em vermelho quando há campo
/// inválido dentro — senão um erro ficaria escondido num nível fechado e o
/// usuário só descobriria ao tentar rodar. Como o card do Adsorvente recebe os
/// campos das duas sub-seções, o aviso sobe sozinho pro nível de cima.
class _ContagemDoGrupo extends StatefulWidget {
  final List<(String, ParamDef)> campos;
  final Map<String, TextEditingController> controladores;

  const _ContagemDoGrupo({required this.campos, required this.controladores});

  @override
  State<_ContagemDoGrupo> createState() => _ContagemDoGrupoState();
}

class _ContagemDoGrupoState extends State<_ContagemDoGrupo> {
  // Montado uma vez: `Listenable.merge` tem identidade nova a cada chamada, e
  // recriá-lo no build faria o AnimatedBuilder re-assinar os controladores
  // toda vez que o cabeçalho reconstrói (ele vive dentro de um Hover).
  late final Listenable _campos = Listenable.merge([
    for (final (chave, _) in widget.campos) widget.controladores[chave]!,
  ]);

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return AnimatedBuilder(
      animation: _campos,
      builder: (_, _) {
        final erros = widget.campos
            .where((c) => !campoValido(c.$2, widget.controladores[c.$1]!.text))
            .length;

        return Text(
          erros == 0 ? '${widget.campos.length} campos' : '$erros com erro',
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: Tipo.label,
            color: erros == 0 ? cores.text3 : cores.erro,
          ),
        );
      },
    );
  }
}

/// Um parâmetro: caixa contornada no padrão do "Nome do experimento" — rótulo
/// que começa deitado dentro e sobe cortando a borda quando o campo tem valor
/// ou foco — e a unidade **fora** dela, numa coluna fixa à direita.
///
/// A unidade sai do campo porque ela não é o que se digita: dentro, ficava
/// colada no valor e encostando na borda do card. Fora, vira uma coluna que se
/// lê de cima a baixo. O símbolo continua como prefixo, dentro: ele identifica
/// o campo junto com o rótulo, e o Material o recolhe enquanto o rótulo está
/// deitado — que é o que abre espaço pros nomes longos da tabela.
///
/// Valida a cada tecla contra o intervalo do `ParamDef`; como os campos nascem
/// preenchidos com padrões válidos, o erro só aparece depois de o usuário mexer.
class _CampoInput extends StatelessWidget {
  final ParamDef def;
  final TextEditingController controlador;

  const _CampoInput({required this.def, required this.controlador});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    // Fora do builder: nada aqui depende do que foi digitado, e um `Text` novo
    // a cada tecla faria a `InputDecoration` nunca comparar igual — o Material
    // descarta o cache dela e reaplica os defaults por isso.
    final rotulo = Text(def.label, maxLines: 2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espaco.xs),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controlador,
        builder: (context, valor, _) {
          final erro = erroDoCampo(def, valor.text);

          return Row(
            // Pela linha de base: a unidade assenta na mesma linha do valor,
            // sem depender da altura da caixa nem da mensagem de erro embaixo.
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextFormField(
                  controller: controlador,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: Tipo.corpoGrande,
                    fontWeight: FontWeight.w500,
                    color: erro == null ? cores.text : cores.erro,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    // Rótulo em duas linhas quando não cabe numa: os nomes da
                    // tabela chegam a 34 caracteres, e cortar o fim de "Fração
                    // do carreador na alimentação" deixaria campos
                    // indistinguíveis. O espaço pra segunda linha é reservado
                    // em todo campo (ver `recuoRotuloCampo`), então quebrar ou
                    // não quebrar dá exatamente a mesma altura.
                    label: rotulo,
                    contentPadding: const EdgeInsets.fromLTRB(
                      Espaco.campo,
                      Dim.recuoRotuloCampo,
                      Espaco.campo,
                      Espaco.campo,
                    ),
                    prefixText: def.symbol,
                    // O slot de erro do Material, pra o campo pintar borda e
                    // rótulo sozinho — mas com o ícone que a mensagem sempre
                    // teve, porque cor não pode ser o único sinal.
                    error: erro == null ? null : _MensagemErro(texto: erro),
                  ),
                ),
              ),
              const SizedBox(width: Espaco.sm),
              SizedBox(
                width: Dim.larguraUnidade,
                child: Text(
                  def.unit,
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: Tipo.label,
                    color: cores.text3,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Erro do campo: ícone + texto, nunca só cor. Vai no slot de erro do
/// `InputDecoration`, que já dá o respiro de cima. `liveRegion` faz o leitor de
/// tela anunciar a mensagem sem o usuário precisar voltar o foco no campo.
class _MensagemErro extends StatelessWidget {
  final String texto;
  const _MensagemErro({required this.texto});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: Icone.pp, color: cores.erro),
          const SizedBox(width: Espaco.xs),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: Tipo.label,
                height: 1.4,
                color: cores.erro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
