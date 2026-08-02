// parameters_panel.dart — painel com os accordions dos parâmetros de entrada.
//
// Os campos vêm de `models/param_defs.dart` (fonte da verdade: tabela do artigo
// Computers & Chem. Eng.). Hoje são 28 = 8 por componente × 2 + 12 fixos; subir
// `kNumComponentes` lá gera os grupos novos aqui sem tocar neste arquivo.
import 'package:flutter/material.dart';
import '../models/param_defs.dart';
import '../theme/app_sizes.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

/// Um accordion: título + os campos dele, já com a chave final de payload.
typedef _Grupo = ({String titulo, List<(String chave, ParamDef def)> campos});

/// Monta os grupos na mesma ordem do payload: componentes, recheio, operação.
List<_Grupo> _grupos() => [
      for (var c = 1; c <= kNumComponentes; c++)
        (
          titulo: nomeComponente(c),
          campos: [
            for (final f in kPerComponentFields)
              (chaveComponente(f.baseKey, c), f),
          ],
        ),
      (
        titulo: 'Recheio',
        campos: [for (final f in kPackingFields) (f.baseKey, f)],
      ),
      (
        titulo: 'Operacao e Geometria',
        campos: [for (final f in kOperationFields) (f.baseKey, f)],
      ),
    ];

class ParametersPanel extends StatefulWidget {
  final Map<String, TextEditingController> controladores;
  final VoidCallback onResetar;

  const ParametersPanel({
    super.key,
    required this.controladores,
    required this.onResetar,
  });

  @override
  State<ParametersPanel> createState() => _ParametersPanelState();
}

class _ParametersPanelState extends State<ParametersPanel> {
  final Set<int> _abertos = {0};
  final _grupo = _grupos();

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Painel(
      child: Column(
        children: [
          // Cabeçalho da seção, como no mockup
          const Padding(
            padding: EdgeInsets.fromLTRB(Espaco.lg, Espaco.lg, Espaco.lg, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CabecalhoSecao(
                eyebrow: 'Entrada',
                titulo: 'Parametros de Entrada',
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Espaco.md),
              children: [
                for (var i = 0; i < _grupo.length; i++) ...[
                  _AccordionItem(
                    numero: i + 1,
                    titulo: _grupo[i].titulo,
                    campos: _grupo[i].campos,
                    controladores: widget.controladores,
                    aberto: _abertos.contains(i),
                    onToggle: () => setState(() {
                      if (_abertos.contains(i)) {
                        _abertos.remove(i);
                      } else {
                        _abertos.add(i);
                      }
                    }),
                  ),
                  const SizedBox(height: Espaco.sm),
                ],
              ],
            ),
          ),
          // Botões de ação
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
                _BotaoFantasma(
                  texto: 'Resetar valores',
                  onTap: widget.onResetar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
          label: 'Rodar predicao — indisponivel',
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
                    'Rodar predicao',
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
          'Disponivel quando o modelo binario ($kNumComponentes componentes, '
          '$totalParametros parametros) estiver treinado.',
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
                  style: TextStyle(fontFamily: 'IBMPlexSans',
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

class _AccordionItem extends StatelessWidget {
  final int numero;
  final String titulo;
  final List<(String, ParamDef)> campos;
  final Map<String, TextEditingController> controladores;
  final bool aberto;
  final VoidCallback onToggle;

  const _AccordionItem({
    required this.numero,
    required this.titulo,
    required this.campos,
    required this.controladores,
    required this.aberto,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return AnimatedContainer(
      duration: Duracao.media,
      decoration: BoxDecoration(
        color: cores.panel2,
        border: Border.all(
          color: aberto ? cores.line2 : cores.line,
          width: Borda.fina,
        ),
        borderRadius: BorderRadius.circular(Raio.cartao),
      ),
      child: Column(
        children: [
          // Header do accordion (fundo panel3 no hover)
          Hover(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: Espaco.md,
                    vertical: Espaco.md,
                  ),
                  child: Row(
                    children: [
                      // Chip com o número do grupo — preenche accent quando aberto
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
                          style: TextStyle(fontFamily: 'IBMPlexMono',
                            fontSize: Tipo.label,
                            color: aberto ? cores.onAccent : cores.text3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: Espaco.cartao),
                      Expanded(
                        child: Text(
                          titulo,
                          style: TextStyle(fontFamily: 'IBMPlexSans',
                            fontSize: Tipo.corpoGrande,
                            fontWeight: FontWeight.w600,
                            color: cores.text,
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
                        child: Icon(Icons.chevron_right, size: Icone.m, color: cores.text2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Corpo expandível (~300ms como no mockup)
          AnimatedCrossFade(
            duration: Duracao.lenta,
            sizeCurve: Curves.easeInOut,
            crossFadeState: aberto ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                Espaco.md,
                0,
                Espaco.md,
                Espaco.md,
              ),
              child: Column(
                children: [
                  for (final (chave, def) in campos)
                    _CampoInput(def: def, controlador: controladores[chave]!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Contador à direita do título do accordion. Vira "N com erro" em vermelho
/// quando há campo inválido dentro — senão um erro ficaria escondido no grupo
/// fechado e o usuário só descobriria ao tentar rodar.
class _ContagemDoGrupo extends StatefulWidget {
  final List<(String, ParamDef)> campos;
  final Map<String, TextEditingController> controladores;

  const _ContagemDoGrupo({required this.campos, required this.controladores});

  @override
  State<_ContagemDoGrupo> createState() => _ContagemDoGrupoState();
}

class _ContagemDoGrupoState extends State<_ContagemDoGrupo> {
  // Montado uma vez: `Listenable.merge` tem identidade nova a cada chamada, e
  // recriá-lo no build faria o AnimatedBuilder re-assinar os 8 controladores
  // toda vez que o cabeçalho reconstrói (ele vive dentro de um Hover).
  late final Listenable _campos = Listenable.merge(
    [for (final (chave, _) in widget.campos) widget.controladores[chave]!],
  );

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

/// Um parâmetro: rótulo em linha própria (os nomes da tabela são longos) e,
/// abaixo, a linha de dados — símbolo à esquerda, valor à direita, unidade.
/// Valida a cada tecla contra o intervalo do `ParamDef`; como os campos nascem
/// preenchidos com padrões válidos, o erro só aparece depois de o usuário mexer.
class _CampoInput extends StatelessWidget {
  final ParamDef def;
  final TextEditingController controlador;

  const _CampoInput({required this.def, required this.controlador});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    // Só depende do tema, não do valor digitado — fora do builder.
    final bordaErro = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Raio.campo),
      borderSide: BorderSide(color: cores.erro, width: Borda.foco),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espaco.xs),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controlador,
        builder: (context, valor, _) {
          final erro = erroDoCampo(def, valor.text);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                def.label,
                style: TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: Tipo.corpo,
                  height: 1.3,
                  color: cores.text,
                ),
              ),
              const SizedBox(height: Espaco.xxs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      def.symbol,
                      style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: Tipo.label,
                        color: cores.text3,
                      ),
                    ),
                  ),
                  const SizedBox(width: Espaco.sm),
                  SizedBox(
                    width: Dim.larguraInput,
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Espaco.campo,
                          vertical: Espaco.sm,
                        ),
                        // null cai no border do tema (line2 / accent no foco)
                        enabledBorder: erro == null ? null : bordaErro,
                        focusedBorder: erro == null ? null : bordaErro,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Dim.larguraUnidade,
                    child: Padding(
                      padding: const EdgeInsets.only(left: Espaco.sm),
                      child: Text(
                        def.unit,
                        style: TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: Tipo.label,
                          color: cores.text3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (erro != null) _MensagemErro(texto: erro),
            ],
          );
        },
      ),
    );
  }
}

/// Erro do campo: ícone + texto, nunca só cor. `liveRegion` faz o leitor de
/// tela anunciar a mensagem sem o usuário precisar voltar o foco no campo.
class _MensagemErro extends StatelessWidget {
  final String texto;
  const _MensagemErro({required this.texto});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: Espaco.xxs),
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
      ),
    );
  }
}
