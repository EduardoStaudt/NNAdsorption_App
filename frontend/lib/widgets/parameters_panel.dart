// parameters_panel.dart — painel com accordions dos 22 inputs
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import 'ui_comum.dart';

class InputField {
  final String chave;
  final String rotulo;
  final String simbolo; // ex.: "L", "eps"
  final String unidade;
  const InputField(this.chave, this.rotulo, this.simbolo, this.unidade);
}

const _grupos = [
  (
    titulo: 'Geometria da Coluna',
    campos: [
      InputField('L', 'Comprimento', 'L', 'm'),
      InputField('Nz', 'Nos espaciais', 'Nz', ''),
      InputField('D_col', 'Diametro', 'D_col', 'm'),
    ],
  ),
  (
    titulo: 'Condicoes de Operacao',
    campos: [
      InputField('u', 'Velocidade superficial', 'u', 'm/s'),
      InputField('T_in', 'Temperatura entrada', 'T_in', 'K'),
      InputField('C_in', 'Concentracao entrada', 'C_in', 'mol/m³'),
      InputField('dt', 'Passo de tempo', 'dt', 's'),
      InputField('t_end', 'Tempo total', 't_end', 's'),
    ],
  ),
  (
    titulo: 'Propriedades do Solido',
    campos: [
      InputField('eps', 'Porosidade', 'eps', ''),
      InputField('rho_B', 'Densidade do leito', 'rho_B', 'kg/m³'),
      InputField('qmax', 'Cap. max. adsorcao', 'q_max', 'mol/kg'),
      InputField('b', 'Constante Langmuir', 'b', 'm³/mol'),
      InputField('n', 'Exp. Freundlich', 'n', ''),
      InputField('cp_s', 'Calor esp. solido', 'cp_s', 'J/kg·K'),
    ],
  ),
  (
    titulo: 'Fluido e Transferencia',
    campos: [
      InputField('D_ax', 'Difusividade axial', 'D_ax', 'm²/s'),
      InputField('kL', 'Coef. transf. massa', 'kL', 'm/s'),
      InputField('lam_z', 'Condutividade ax.', 'lam_z', 'W/m·K'),
      InputField('rho_g', 'Densidade gas', 'rho_g', 'kg/m³'),
      InputField('cp_g', 'Calor esp. gas', 'cp_g', 'J/kg·K'),
      InputField('h_w', 'Coef. calor parede', 'h_w', 'W/m²·K'),
      InputField('T_wall', 'Temp. parede', 'T_wall', 'K'),
      InputField('dH', 'Calor de adsorcao', 'dH', 'J/mol'),
    ],
  ),
];

class ParametersPanel extends StatefulWidget {
  final Map<String, TextEditingController> controladores;
  final bool carregando;
  final VoidCallback onPredict;
  final VoidCallback onResetar;

  const ParametersPanel({
    super.key,
    required this.controladores,
    required this.carregando,
    required this.onPredict,
    required this.onResetar,
  });

  @override
  State<ParametersPanel> createState() => _ParametersPanelState();
}

class _ParametersPanelState extends State<ParametersPanel> {
  final Set<int> _abertos = {0};

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Painel(
      child: Column(
        children: [
          // Cabeçalho da seção, como no mockup
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
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
              padding: const EdgeInsets.all(14),
              children: [
                for (var i = 0; i < _grupos.length; i++) ...[
                  _AccordionItem(
                    numero: i + 1,
                    titulo: _grupos[i].titulo,
                    campos: _grupos[i].campos,
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
                  const SizedBox(height: 9),
                ],
              ],
            ),
          ),
          // Botões de ação
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: cores.line)),
            ),
            child: Column(
              children: [
                _BotaoRodar(
                  carregando: widget.carregando,
                  onTap: widget.onPredict,
                ),
                const SizedBox(height: 9),
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

// Botão principal "Rodar predicao": accent com glow, levanta 1px no hover
class _BotaoRodar extends StatelessWidget {
  final bool carregando;
  final VoidCallback onTap;
  const _BotaoRodar({required this.carregando, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Hover(
      builder: (emHover) => EscalaAoClicar(
        child: GestureDetector(
          onTap: carregando ? null : onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              height: 46,
              transform: Matrix4.translationValues(0, emHover && !carregando ? -1 : 0, 0),
              decoration: BoxDecoration(
                color: carregando
                    ? cores.accent.withValues(alpha: 0.6)
                    : cores.accent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: cores.accent.withValues(alpha: emHover ? 0.5 : 0.35),
                    blurRadius: emHover ? 26 : 22,
                    offset: const Offset(0, 6),
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: Center(
                child: carregando
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cores.onAccent,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, size: 18, color: cores.onAccent),
                          const SizedBox(width: 6),
                          Text(
                            'Rodar predicao',
                            style: GoogleFonts.ibmPlexSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: cores.onAccent,
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
              duration: const Duration(milliseconds: 150),
              height: 42,
              decoration: BoxDecoration(
                border: Border.all(color: emHover ? cores.text2 : cores.line2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  texto,
                  style: GoogleFonts.ibmPlexSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
  final List<InputField> campos;
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
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: cores.panel2,
        border: Border.all(color: aberto ? cores.line2 : cores.line),
        borderRadius: BorderRadius.circular(11),
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
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: emHover ? cores.panel3 : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                  child: Row(
                    children: [
                      // Chip com o número do grupo — preenche accent quando aberto
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: aberto ? cores.accent : Colors.transparent,
                          border: Border.all(
                            color: aberto ? cores.accent : cores.line2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '0$numero',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 11,
                            color: aberto ? cores.onAccent : cores.text3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          titulo,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cores.text,
                          ),
                        ),
                      ),
                      Text(
                        '${campos.length} campos',
                        style: GoogleFonts.ibmPlexMono(fontSize: 11, color: cores.text3),
                      ),
                      const SizedBox(width: 10),
                      // Chevron animado
                      AnimatedRotation(
                        turns: aberto ? 0.25 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(Icons.chevron_right, size: 18, color: cores.text2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Corpo expandível (~300ms como no mockup)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOut,
            crossFadeState: aberto ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
              child: Column(
                children: [
                  for (final campo in campos)
                    _CampoInput(
                      campo: campo,
                      controlador: controladores[campo.chave]!,
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

class _CampoInput extends StatelessWidget {
  final InputField campo;
  final TextEditingController controlador;

  const _CampoInput({required this.campo, required this.controlador});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label: nome + símbolo em mono
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campo.rotulo,
                  style: GoogleFonts.ibmPlexSans(fontSize: 13, color: cores.text),
                ),
                Text(
                  campo.simbolo,
                  style: GoogleFonts.ibmPlexMono(fontSize: 11, color: cores.text3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Input numérico right-aligned, mono, foco com borda accent
          SizedBox(
            width: 96,
            child: TextFormField(
              controller: controlador,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              textAlign: TextAlign.right,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cores.text,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          // Unidade
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                campo.unidade,
                style: GoogleFonts.ibmPlexMono(fontSize: 11, color: cores.text3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Valores padrão para os 22 inputs
const Map<String, String> valoresPadrao = {
  'L': '0.5',
  'Nz': '50',
  'eps': '0.4',
  'rho_B': '500.0',
  'u': '0.01',
  'D_ax': '1e-5',
  'kL': '0.05',
  'qmax': '10.0',
  'b': '0.1',
  'n': '1.0',
  'lam_z': '0.1',
  'rho_g': '1.2',
  'cp_g': '1000.0',
  'cp_s': '800.0',
  'D_col': '0.05',
  'h_w': '10.0',
  'T_wall': '298.0',
  'dH': '-20000.0',
  'dt': '1.0',
  't_end': '100.0',
  'C_in': '0.01',
  'T_in': '298.0',
};
