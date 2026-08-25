// painel_flat_parametros.dart — os mesmos 31 parâmetros da coluna da esquerda,
// só que como tabela editável estreita, colada na borda direita.
//
// Por que os dois existem: o accordion é onde se monta um experimento (rótulo
// descritivo, faixa, erro explicado); este aqui é a referência de contexto que
// fica à vista enquanto se lê o gráfico — "com que número saiu essa curva?".
// Por isso só o símbolo do artigo aparece, e o campo não tem decoração nenhuma
// em repouso: tem que se ler como tabela, não como formulário.
//
// Os dois painéis compartilham o `Map<String, TextEditingController>` da tela,
// então editar aqui muda lá e vice-versa sem provider nenhum no meio — quem
// avisa quem é o próprio controlador.
import 'package:flutter/material.dart';
import '../models/param_defs.dart';
import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'export_button.dart' show kFormatosExport;
import 'ui_comum.dart';

class PainelFlatParametros extends StatelessWidget {
  final Map<String, TextEditingController> controladores;
  final VoidCallback onComparar;
  final void Function(String formato) onExportar;
  final VoidCallback onRodar;

  /// Onde o painel está agora. Muda só de que lado fica o fio que o separa do
  /// resto: à esquerda na lateral, em cima quando desce. A largura sempre vem
  /// do pai — na lateral quem a define é o arraste da alça.
  final bool naLateral;

  const PainelFlatParametros({
    super.key,
    required this.controladores,
    required this.onComparar,
    required this.onExportar,
    required this.onRodar,
    this.naLateral = true,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final fio = BorderSide(color: cores.line, width: Borda.fina);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.bg,
        border: naLateral ? Border(left: fio) : Border(top: fio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Titulo(),
          const _Fio(),
          // Só a tabela rola; as ações ficam ancoradas embaixo.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Espaco.campo),
              children: [
                _Cartao(child: _Componentes(controladores: controladores)),
                const SizedBox(height: Espaco.sm),
                _Cartao(
                  child: _SecaoGlobal(
                    titulo: 'Isoterma',
                    icone: Icons.grain,
                    campos: kPackingFields,
                    controladores: controladores,
                  ),
                ),
                const SizedBox(height: Espaco.sm),
                _Cartao(
                  child: _SecaoGlobal(
                    titulo: 'Operação e Geometria',
                    icone: Icons.settings_outlined,
                    campos: kOperationFields,
                    controladores: controladores,
                  ),
                ),
              ],
            ),
          ),
          const _Fio(),
          _Acoes(
            onComparar: onComparar,
            onExportar: onExportar,
            onRodar: onRodar,
          ),
        ],
      ),
    );
  }
}

/// Alça de redimensionar, entre a coluna central e o painel. Faixa fina com o
/// grip de três pontos e cursor de coluna — o mesmo gesto de editor de código.
/// Arrastar pra a esquerda alarga o painel; pra a direita, estreita.
class AlcaPainelFlat extends StatelessWidget {
  final void Function(double dx) onArrastar;
  final VoidCallback onComecar;
  final VoidCallback onTerminar;

  const AlcaPainelFlat({
    super.key,
    required this.onArrastar,
    required this.onComecar,
    required this.onTerminar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => onComecar(),
        onHorizontalDragUpdate: (d) => onArrastar(d.delta.dx),
        onHorizontalDragEnd: (_) => onTerminar(),
        child: Hover(
          builder: (emHover) => SizedBox(
            width: Dim.larguraAlcaFlat,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(height: Espaco.xxs),
                    AnimatedContainer(
                      duration: Duracao.rapida,
                      width: Dim.pontoAlca,
                      height: Dim.pontoAlca,
                      decoration: BoxDecoration(
                        color: emHover ? cores.accentForte : cores.line2,
                        shape: BoxShape.circle,
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

/// Tira que fica no lugar do painel colapsado. Só a seta de trazer de volta —
/// sem ela o painel sumiria sem deixar como reabrir.
class BotaoAbrirFlat extends StatelessWidget {
  final VoidCallback onAbrir;
  const BotaoAbrirFlat({super.key, required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Semantics(
      button: true,
      label: 'Abrir parâmetros de entrada',
      child: Hover(
        builder: (emHover) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onAbrir,
            child: Container(
              width: Dim.larguraAbrirFlat,
              decoration: BoxDecoration(
                color: cores.panel,
                border: Border(
                  left: BorderSide(color: cores.line, width: Borda.fina),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.chevron_left,
                  size: Icone.m,
                  color: emHover ? cores.accentForte : cores.text2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Caixa de uma seção. Mesma superfície e mesmo fio dos cards de gráfico da
/// coluna central — as duas colunas ficam lado a lado e um degrau de fundo
/// diferente entre elas se lê como erro, não como hierarquia.
class _Cartao extends StatelessWidget {
  final Widget child;
  const _Cartao({required this.child});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Container(
      padding: const EdgeInsets.all(Espaco.campo),
      decoration: BoxDecoration(
        color: cores.panel,
        border: Border.all(color: cores.line, width: Borda.fina),
        borderRadius: BorderRadius.circular(Raio.campo),
      ),
      child: child,
    );
  }
}

/// Fio horizontal que separa as faixas do painel.
class _Fio extends StatelessWidget {
  const _Fio();

  @override
  Widget build(BuildContext context) =>
      Container(height: Borda.fina, color: context.cores.line);
}

class _Titulo extends StatelessWidget {
  const _Titulo();

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espaco.campo,
        Espaco.cartao,
        Espaco.campo,
        Espaco.cartao,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: Icone.p, color: cores.text2),
              const SizedBox(width: Espaco.xs),
              Text(
                'Entrada',
                style: TextStyle(
                  // Um degrau acima dos títulos de seção, pra o nome do painel
                  // não ficar menor que o dos blocos dentro dele.
                  fontFamily: 'IBMPlexSans',
                  fontSize: Tipo.tituloGrande,
                  fontWeight: FontWeight.w600,
                  color: cores.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: Espaco.xxs),
          // Contagem derivada de `param_defs.dart`: se a rede ganhar um campo,
          // esta linha muda sozinha.
          Text(
            '$totalParametros parâmetros · $kNumComponentes componentes',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: Tipo.eixo,
              color: cores.text3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Os dois componentes lado a lado: a mesma variável em cada coluna, o que
/// muda é o valor. Ler na horizontal compara carreador e forte de um relance —
/// é a única leitura que o accordion não dá, porque lá um fecha o outro.
class _Componentes extends StatelessWidget {
  final Map<String, TextEditingController> controladores;
  const _Componentes({required this.controladores});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TituloSecao(
          titulo: 'Adsorbato',
          icone: Icons.bubble_chart_outlined,
        ),
        const SizedBox(height: Espaco.xs),
        const _Fio(),
        const SizedBox(height: Espaco.xs),
        // Cabeçalho na mesma grade das linhas: cada nome fica exatamente sobre
        // a coluna de valores dele.
        Row(
          children: [
            const SizedBox(width: Dim.larguraChaveFlat),
            _colunaValor(
              _NomeComponente(nome: nomeComponente(1), cor: cores.data4),
            ),
            _colunaValor(
              _NomeComponente(nome: nomeComponente(2), cor: cores.accentForte),
            ),
            const SizedBox(width: Espaco.xs),
            const SizedBox(width: Dim.larguraUnidadeFlat),
          ],
        ),
        const SizedBox(height: Espaco.xs),
        for (final def in kPerComponentFields)
          _LinhaGrade(
            simbolo: def.symbol,
            unidade: def.unit,
            valores: [
              for (var c = 1; c <= kNumComponentes; c++)
                controladores[chaveComponente(def.baseKey, c)]!,
            ],
          ),
      ],
    );
  }
}

/// Uma coluna de valores da grade. Todas iguais, pra os números das quatro
/// seções caírem na mesma vertical.
Widget _colunaValor(Widget filho) => Expanded(
  child: Padding(
    padding: const EdgeInsets.only(left: Espaco.xs),
    child: filho,
  ),
);

/// Título de um card do painel. Mesmo degrau do "Adsorbato" do accordion: são
/// o mesmo nível de hierarquia, um bloco de parâmetros cada.
class _TituloSecao extends StatelessWidget {
  final String titulo;
  final IconData icone;
  const _TituloSecao({required this.titulo, required this.icone});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Row(
      children: [
        Icon(icone, size: Icone.p, color: cores.text2),
        const SizedBox(width: Espaco.xs),
        Expanded(
          child: Text(
            titulo,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: Tipo.titulo,
              fontWeight: FontWeight.w600,
              color: cores.text,
            ),
          ),
        ),
      ],
    );
  }
}

/// Nome do componente sobre a coluna dele. `FittedBox` porque a coluna tem a
/// largura de um número, não de uma palavra: em vez de cortar "Carreador", o
/// rótulo encolhe o tanto que precisar.
class _NomeComponente extends StatelessWidget {
  final String nome;
  final Color cor;
  const _NomeComponente({required this.nome, required this.cor});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      // Centrado na coluna, não colado no fim dela: o valor é curto e fica no
      // canto direito, então o nome centrado cobre a coluna inteira em vez de
      // se amontoar num lado.
      alignment: Alignment.center,
      child: Text(
        nome,
        maxLines: 1,
        style: TextStyle(
          // Mesmo corpo do "Carreador"/"Gás Forte" do accordion: são a mesma
          // sub-seção, vista de outro jeito.
          fontFamily: 'IBMPlexSans',
          fontSize: Tipo.corpoGrande,
          fontWeight: FontWeight.w600,
          color: cor,
        ),
      ),
    );
  }
}

/// Bloco de campos fixos (Adsorvente, Operação e Geometria). Um valor por
/// linha, ocupando as duas colunas que os componentes usam — o número termina
/// na mesma vertical dos de cima.
class _SecaoGlobal extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final List<ParamDef> campos;
  final Map<String, TextEditingController> controladores;

  const _SecaoGlobal({
    required this.titulo,
    required this.icone,
    required this.campos,
    required this.controladores,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TituloSecao(titulo: titulo, icone: icone),
        const SizedBox(height: Espaco.xs),
        const _Fio(),
        const SizedBox(height: Espaco.xs),
        for (final def in campos)
          _LinhaGrade(
            simbolo: def.symbol,
            unidade: def.unit,
            valores: [controladores[def.baseKey]!],
          ),
      ],
    );
  }
}

/// Uma linha da tabela: símbolo do artigo à esquerda, um valor editável por
/// componente no meio e a unidade à direita. Com um valor só, ele ocupa o miolo
/// inteiro — as bordas da grade são fixas, então as colunas nunca desencontram.
class _LinhaGrade extends StatelessWidget {
  final String simbolo;
  final String unidade;
  final List<TextEditingController> valores;

  const _LinhaGrade({
    required this.simbolo,
    required this.unidade,
    required this.valores,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    // '–' é como `param_defs.dart` marca adimensional; na tabela ele não
    // acrescenta nada e só suja a coluna.
    final temUnidade = unidade.trim() != '–';

    return Row(
      children: [
        SizedBox(
          width: Dim.larguraChaveFlat,
          child: Text(
            simbolo,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              // Mesmo corpo do valor do campo no accordion: os dois painéis
              // mostram o mesmo dado e não podem ter pesos diferentes.
              fontFamily: 'IBMPlexMono',
              fontSize: Tipo.corpoGrande,
              color: cores.text2,
            ),
          ),
        ),
        for (final controlador in valores)
          _colunaValor(_Campo(controlador: controlador)),
        const SizedBox(width: Espaco.xs),
        SizedBox(
          width: Dim.larguraUnidadeFlat,
          child: Text(
            temUnidade ? unidade : '',
            maxLines: 1,
            // Sem isto o Flutter quebra 'mol/(kg·K)' na barra e a segunda
            // metade some — o `maxLines` mostra só a primeira linha.
            softWrap: false,
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: Tipo.dado,
              color: cores.text3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Campo sem moldura: em repouso é texto de tabela. O hover levanta um fio
/// neutro pra dizer "isto se edita" e o foco acende o âmbar — a mesma regra de
/// hover do resto do sistema, na menor escala que existe aqui.
class _Campo extends StatefulWidget {
  final TextEditingController controlador;
  const _Campo({required this.controlador});

  @override
  State<_Campo> createState() => _CampoState();
}

class _CampoState extends State<_Campo> {
  final _foco = FocusNode();
  bool _emHover = false;

  @override
  void initState() {
    super.initState();
    _foco.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final focado = _foco.hasFocus;

    UnderlineInputBorder fio(Color cor) =>
        UnderlineInputBorder(borderSide: BorderSide(color: cor));

    return MouseRegion(
      onEnter: (_) => setState(() => _emHover = true),
      onExit: (_) => setState(() => _emHover = false),
      child: TextField(
        controller: widget.controlador,
        focusNode: _foco,
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        style: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: Tipo.corpoGrande,
          fontWeight: FontWeight.w500,
          color: focado ? cores.accentForte : cores.text,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: Espaco.xxs),
          border: InputBorder.none,
          enabledBorder: _emHover ? fio(cores.line2) : InputBorder.none,
          focusedBorder: fio(cores.accent),
        ),
      ),
    );
  }
}

/// Faixa de ações, fora da rolagem: as duas secundárias em linha e a principal
/// ocupando a largura toda embaixo.
class _Acoes extends StatelessWidget {
  final VoidCallback onComparar;
  final void Function(String formato) onExportar;
  final VoidCallback onRodar;

  const _Acoes({
    required this.onComparar,
    required this.onExportar,
    required this.onRodar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Espaco.campo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: BotaoContorno(
                  texto: 'Comparar',
                  icone: Icons.compare_arrows,
                  altura: Dim.alturaBotaoCompacto,
                  onTap: onComparar,
                ),
              ),
              const SizedBox(width: Espaco.sm),
              Expanded(child: _BotaoExportar(onExportar: onExportar)),
            ],
          ),
          const SizedBox(height: Espaco.sm),
          BotaoPrimario(
            texto: 'Rodar novamente',
            icone: Icons.refresh,
            onTap: onRodar,
          ),
        ],
      ),
    );
  }
}

/// Exportar com o menu subindo: o botão mora colado na base da tela, então um
/// dropdown pra baixo não teria pra onde ir. Mesmos formatos do botão do
/// cabeçalho (`kFormatosExport`), pra um formato novo aparecer nos dois.
class _BotaoExportar extends StatefulWidget {
  final void Function(String formato) onExportar;
  const _BotaoExportar({required this.onExportar});

  @override
  State<_BotaoExportar> createState() => _BotaoExportarState();
}

class _BotaoExportarState extends State<_BotaoExportar> {
  /// Altura do menu montado: uma linha por formato mais o respiro de cima e de
  /// baixo. É o quanto ele precisa subir pra ficar acima do botão.
  static final _alturaMenu =
      kFormatosExport.length * Dim.alturaItemMenu + Espaco.xs * 2;

  final _chaveBotao = GlobalKey();

  /// Largura medida do botão. O menu copia ela pra as bordas dos dois baterem —
  /// aberto, menu e botão têm que se ler como uma peça só.
  double? _larguraBotao;

  void _medirBotao() {
    final ctx = _chaveBotao.currentContext;
    if (ctx == null) return;
    final w = (ctx.findRenderObject() as RenderBox).size.width;
    if (w != _larguraBotao) setState(() => _larguraBotao = w);
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    // Mede depois do layout: durante o build o botão ainda não tem tamanho.
    WidgetsBinding.instance.addPostFrameCallback((_) => _medirBotao());

    return MenuAnchor(
      // Âncora no topo do botão e sobe a própria altura: o menu termina onde o
      // botão começa.
      alignmentOffset: Offset(0, -_alturaMenu - Espaco.xxs),
      style: MenuStyle(
        alignment: Alignment.topLeft,
        backgroundColor: WidgetStatePropertyAll(cores.panel2),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: Espaco.xs),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Raio.chip),
            side: BorderSide(color: cores.line2, width: Borda.fina),
          ),
        ),
      ),
      menuChildren: [
        // Largura travada na do botão: sem isto o menu abre do tamanho do
        // rótulo mais longo e escapa pra fora da coluna.
        SizedBox(
          width: _larguraBotao,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in kFormatosExport)
                MenuItemButton(
                  onPressed: () => widget.onExportar(f.formato),
                  leadingIcon: Icon(f.icone, size: Icone.p),
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.hovered)
                          ? cores.accentForte
                          : cores.text,
                    ),
                    iconColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.hovered)
                          ? cores.accentForte
                          : cores.text2,
                    ),
                    overlayColor: WidgetStatePropertyAll(
                      cores.accent.withValues(alpha: 0.12),
                    ),
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontSize: Tipo.corpo,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Sem largura mínima própria: o item segue o SizedBox
                    minimumSize: const WidgetStatePropertyAll(
                      Size(0, Dim.alturaItemMenu),
                    ),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: Espaco.campo),
                    ),
                  ),
                  child: Text('Exportar ${f.rotulo}'),
                ),
            ],
          ),
        ),
      ],
      builder: (context, controle, _) => KeyedSubtree(
        key: _chaveBotao,
        child: BotaoContorno(
          texto: 'Exportar',
          icone: Icons.upload_outlined,
          altura: Dim.alturaBotaoCompacto,
          onTap: () => controle.isOpen ? controle.close() : controle.open(),
        ),
      ),
    );
  }
}
