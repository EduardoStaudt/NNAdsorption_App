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

  const PainelFlatParametros({
    super.key,
    required this.controladores,
    required this.onComparar,
    required this.onExportar,
    required this.onRodar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Container(
      width: Dim.larguraPainelFlat,
      decoration: BoxDecoration(
        color: cores.panel,
        border: Border(
          left: BorderSide(color: cores.line, width: Borda.fina),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Titulo(),
          const _Fio(),
          // Só a tabela rola; as ações ficam ancoradas embaixo.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Espaco.campo,
                Espaco.campo,
                Espaco.campo,
                Espaco.lg,
              ),
              children: [
                _Componentes(controladores: controladores),
                _SecaoGlobal(
                  titulo: 'Adsorvente',
                  campos: kPackingFields,
                  controladores: controladores,
                ),
                _SecaoGlobal(
                  titulo: 'Operação e Geometria',
                  campos: kOperationFields,
                  controladores: controladores,
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
      padding: const EdgeInsets.symmetric(
        horizontal: Espaco.campo,
        vertical: Espaco.cartao,
      ),
      child: Row(
        children: [
          Icon(Icons.tune, size: Icone.p, color: cores.text2),
          const SizedBox(width: Espaco.xs),
          Text(
            'Entrada',
            style: TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: Tipo.corpoGrande,
              fontWeight: FontWeight.w600,
              color: cores.text,
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
        Row(
          children: [
            Expanded(
              child: _CabecalhoComponente(
                nome: nomeComponente(1),
                icone: Icons.water_drop_outlined,
                cor: cores.data4,
              ),
            ),
            const SizedBox(width: Espaco.sm),
            Expanded(
              child: _CabecalhoComponente(
                nome: nomeComponente(2),
                icone: Icons.local_fire_department_outlined,
                cor: cores.accentForte,
              ),
            ),
          ],
        ),
        const SizedBox(height: Espaco.xs),
        const _Fio(),
        const SizedBox(height: Espaco.xs),
        for (final def in kPerComponentFields)
          Row(
            children: [
              for (var c = 1; c <= kNumComponentes; c++) ...[
                if (c > 1) const SizedBox(width: Espaco.sm),
                Expanded(
                  child: _Linha(
                    def: def,
                    controlador:
                        controladores[chaveComponente(def.baseKey, c)]!,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _CabecalhoComponente extends StatelessWidget {
  final String nome;
  final IconData icone;
  final Color cor;
  const _CabecalhoComponente({
    required this.nome,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: Icone.pp, color: cor),
        const SizedBox(width: Espaco.xxs),
        Expanded(
          child: Text(
            nome,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: Tipo.label,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bloco de campos fixos (Adsorvente, Operação). Uma coluna só, e aqui a
/// unidade cabe — nas colunas dos componentes ela seria cortada.
class _SecaoGlobal extends StatelessWidget {
  final String titulo;
  final List<ParamDef> campos;
  final Map<String, TextEditingController> controladores;

  const _SecaoGlobal({
    required this.titulo,
    required this.campos,
    required this.controladores,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Espaco.md),
        const _Fio(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Espaco.sm),
          child: Text(
            titulo.toUpperCase(),
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: Tipo.eixo,
              letterSpacing: 1, // mesma ideia do Eyebrow, na escala menor
              color: cores.text3,
            ),
          ),
        ),
        for (final def in campos)
          _Linha(
            def: def,
            controlador: controladores[def.baseKey]!,
            mostrarUnidade: true,
          ),
      ],
    );
  }
}

/// Uma linha da tabela: símbolo do artigo, valor editável e (às vezes) unidade.
class _Linha extends StatelessWidget {
  final ParamDef def;
  final TextEditingController controlador;
  final bool mostrarUnidade;

  const _Linha({
    required this.def,
    required this.controlador,
    this.mostrarUnidade = false,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Row(
      children: [
        SizedBox(
          width: Dim.larguraChaveFlat,
          child: Text(
            def.symbol,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: Tipo.eixo,
              color: cores.text2,
            ),
          ),
        ),
        Expanded(child: _Campo(controlador: controlador)),
        if (mostrarUnidade) ...[
          const SizedBox(width: Espaco.xs),
          SizedBox(
            width: Dim.larguraUnidadeFlat,
            child: Text(
              def.unit,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: Tipo.eixo,
                color: cores.text3,
              ),
            ),
          ),
        ],
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
          fontSize: Tipo.eixo,
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
class _BotaoExportar extends StatelessWidget {
  final void Function(String formato) onExportar;
  const _BotaoExportar({required this.onExportar});

  /// Altura do menu montado: uma linha por formato mais o respiro de cima e de
  /// baixo. É o quanto ele precisa subir pra ficar acima do botão.
  static final _alturaMenu =
      kFormatosExport.length * Dim.alturaItemMenu + Espaco.xs * 2;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

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
        for (final f in kFormatosExport)
          MenuItemButton(
            onPressed: () => onExportar(f.formato),
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
              minimumSize: const WidgetStatePropertyAll(
                Size(0, Dim.alturaItemMenu),
              ),
            ),
            child: Text('Exportar ${f.rotulo}'),
          ),
      ],
      builder: (context, controle, _) => BotaoContorno(
        texto: 'Exportar',
        icone: Icons.upload_outlined,
        altura: Dim.alturaBotaoCompacto,
        onTap: () => controle.isOpen ? controle.close() : controle.open(),
      ),
    );
  }
}
