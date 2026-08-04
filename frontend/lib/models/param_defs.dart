// param_defs.dart — definição canônica dos parâmetros de entrada.
// Fonte: Tabela "Intervalos de amostragem" (artigo Computers & Chem. Eng.).
// Sistema atual: 2×1 (2 gases, 1 adsorvato). Rede = 28 parâmetros.
//
// MODULARIDADE: os 8 campos de isoterma+cinética são "por componente" — subir
// `kNumComponentes` gera os grupos e as chaves de payload deles sozinho.
//
// ATENÇÃO, o que NÃO escala sozinho: `y0` é um campo só porque com 2 gases a
// outra fração sai de y1 = 1 − y0. Com N > 2 são precisas N−1 frações
// independentes, e `kOperationFields` é uma lista fixa que não indexa por
// componente. Antes de mexer na constante, `y0` tem que virar um terceiro
// bucket ("N−1 por componente") — senão o payload sai silenciosamente
// incompleto e os testes daqui não pegam (só conferem quantidade e conjunto).

/// Nº de componentes ativos. Trava atual: 2. Não mexer sem a rede aceitar mais
/// (e sem resolver o `y0` acima).
const int kNumComponentes = 2;

/// Teto de componentes que o sistema pretende suportar. É documentação de
/// intenção, não um limite aplicado: nada além de `kNumComponentes` é gerado.
const int kMaxComponentes = 5;

class ParamDef {
  final String
  baseKey; // chave base (ex.: 'qm_ref'); vira 'qm_ref_1' por componente
  final String label; // rótulo em PT
  final String symbol; // símbolo da tabela
  final String unit; // unidade exata da coluna lateral ('–' = adimensional)
  final double min; // limite inferior do intervalo
  final double max; // limite superior do intervalo
  final bool logScale; // † amostrado log-uniformemente (relevante p/ sliders)

  const ParamDef(
    this.baseKey,
    this.label,
    this.symbol,
    this.unit,
    this.min,
    this.max, {
    this.logScale = false,
  });
}

// ─── Isoterma e cinética (POR COMPONENTE) — 8 campos ───
const List<ParamDef> kPerComponentFields = [
  ParamDef(
    'qm_ref',
    'Carga de saturação (298 K)',
    'qm,ref',
    'mol/kg',
    1.0,
    15.0,
  ),
  ParamDef('k2', 'Inclinação carga–temperatura', 'k2', 'mol/(kg·K)', -0.1, 0.0),
  ParamDef(
    'b_ref',
    'Afinidade (298 K)',
    'B_ref',
    'atm⁻ⁿ',
    1e-4,
    1.0,
    logScale: true,
  ),
  ParamDef('k4', 'Fator exponencial da afinidade', 'k4', 'K', 0.0, 3200.0),
  ParamDef('n_ref', 'Heterogeneidade (298 K)', 'n_ref', '–', 0.5, 1.5),
  ParamDef('k6', 'Inclinação da heterogeneidade', 'k6', 'K', -2200.0, 2200.0),
  ParamDef('kL', 'Coeficiente LDF', 'kL', 's⁻¹', 0.01, 1.0, logScale: true),
  ParamDef('dH', 'Calor de adsorção (−ΔH)', '−ΔH', 'kJ/mol', 5.0, 50.0),
];

// ─── Recheio (FIXO) — 3 campos ───
const List<ParamDef> kPackingFields = [
  ParamDef('eps', 'Porosidade do leito', 'εb', '–', 0.30, 0.50),
  ParamDef('rho_b', 'Massa específica aparente', 'ρb', 'kg/m³', 400.0, 900.0),
  ParamDef(
    'cp_s',
    'Capacidade calorífica do sólido',
    'Cp,s',
    'J/(kg·K)',
    800.0,
    1200.0,
  ),
];

// ─── Condições de operação e geometria (FIXO) — 9 campos ───
const List<ParamDef> kOperationFields = [
  ParamDef('vs', 'Velocidade superficial', 'vs', 'm/s', 0.001, 0.05),
  ParamDef('T_in', 'Temperatura de alimentação', 'T_in', 'K', 288.0, 323.0),
  ParamDef('P', 'Pressão', 'P', 'MPa', 0.1, 3.0),
  ParamDef('L', 'Comprimento do leito', 'L', 'm', 0.3, 1.5),
  ParamDef(
    'h_w',
    'Coef. de troca com a parede',
    'h_w',
    'W/(m²·K)',
    20.0,
    100.0,
  ),
  ParamDef('lam', 'Condutividade axial', 'λ', 'W/(m·K)', 0.1, 0.8),
  ParamDef('dp', 'Diâmetro de partícula', 'd_p', 'mm', 0.5, 5.0),
  ParamDef('Dm', 'Difusividade molecular', 'D_m', 'm²/s', 5e-6, 3e-5),
  ParamDef('y0', 'Fração do carreador na alimentação', 'y0', '–', 0.20, 0.75),
];
// Obs.: y1 (fração do componente forte) NÃO é campo — vem de y1 = 1 − y0
// (conservação de massa por construção). Só y0 é entrada.

/// Papel de cada componente na mistura, na ordem dos índices (1-based).
/// Passando disso só existe o rótulo genérico "Comp N".
const List<String> kNomesComponentes = ['Carregador', 'Gás Forte'];

/// Nome de exibição do componente `comp` (1-based). É o papel dele na mistura —
/// o índice não entra porque estes títulos vivem dentro do card "Adsorvente",
/// que já dá o contexto.
String nomeComponente(int comp) => comp <= kNomesComponentes.length
    ? kNomesComponentes[comp - 1]
    : 'Comp $comp';

/// Gera a chave final por componente: baseKey + '_' + índice (1-based).
/// Ex.: chaveComponente('qm_ref', 1) → 'qm_ref_1'
String chaveComponente(String baseKey, int comp) => '${baseKey}_$comp';

/// Ordem canônica do payload: comp1(8) … compN(8) … recheio(3) … operação(9).
/// Tudo que precisa dessa ordem — chaves, defaults, validação, UI — deriva daqui.
List<(String chave, ParamDef def)> camposAtivos() => [
  for (var c = 1; c <= kNumComponentes; c++)
    for (final f in kPerComponentFields) (chaveComponente(f.baseKey, c), f),
  for (final f in kPackingFields) (f.baseKey, f),
  for (final f in kOperationFields) (f.baseKey, f),
];

/// Quantos parâmetros a rede recebe hoje (28 com kNumComponentes = 2).
int get totalParametros =>
    kNumComponentes * kPerComponentFields.length +
    kPackingFields.length +
    kOperationFields.length;

/// Todas as chaves do payload, na ordem.
List<String> chavesAtivas() => [for (final (chave, _) in camposAtivos()) chave];

/// Definição de cada chave ativa — a UI e a validação leem daqui.
Map<String, ParamDef> defsPorChave() => {
  for (final (chave, def) in camposAtivos()) chave: def,
};

// ─── Valores padrão (PLACEHOLDER — dentro do intervalo; ajustar depois) ───
const Map<String, double> _padraoPorComponente = {
  'qm_ref': 8.0,
  'k2': -0.02,
  'b_ref': 0.1,
  'k4': 1500.0,
  'n_ref': 1.0,
  'k6': 0.0,
  'kL': 0.1,
  'dH': 25.0,
};
const Map<String, double> _padraoFixo = {
  'eps': 0.4,
  'rho_b': 650.0,
  'cp_s': 1000.0,
  'vs': 0.01,
  'T_in': 298.0,
  'P': 1.0,
  'L': 0.5,
  'h_w': 50.0,
  'lam': 0.4,
  'dp': 2.0,
  'Dm': 1e-5,
  'y0': 0.5,
};

Map<String, double> valoresPadrao() => {
  for (var c = 1; c <= kNumComponentes; c++)
    for (final e in _padraoPorComponente.entries)
      chaveComponente(e.key, c): e.value,
  ..._padraoFixo,
};

// ─── Validação ───

/// Lê o texto digitado como número. Aceita vírgula decimal (teclado pt-BR).
double? lerNumero(String texto) =>
    double.tryParse(texto.trim().replaceAll(',', '.'));

/// Número no formato mais curto que ainda se lê: sem `.0` sobrando e em
/// notação científica só quando o decimal ficaria ilegível (1e-4, 5e-6).
/// Usado tanto no valor que preenche o campo quanto na mensagem de erro — os
/// dois aparecem lado a lado, então precisam falar a mesma língua.
String formatarNumero(double v) {
  if (v == 0) return '0';
  final abs = v.abs();
  if (abs < 0.001 || abs >= 1e5) return v.toStringAsExponential(0);
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toString();
}

/// Valores padrão já como texto de input.
Map<String, String> textosPadrao() => {
  for (final e in valoresPadrao().entries) e.key: formatarNumero(e.value),
};

/// Intervalo válido do campo, pronto pra mensagem: "1 a 15".
String intervaloLegivel(ParamDef def) =>
    '${formatarNumero(def.min)} a ${formatarNumero(def.max)}';

/// Só diz se o valor serve. Usado por quem conta erros e não vai mostrar
/// mensagem nenhuma — assim ninguém monta string à toa a cada tecla.
bool campoValido(ParamDef def, String texto) {
  final valor = lerNumero(texto);
  return valor != null &&
      valor.isFinite &&
      valor >= def.min &&
      valor <= def.max;
}

/// Mensagem de erro do campo, ou null se o valor serve.
/// Diz sempre o que fazer: fora da faixa mostra a faixa válida.
String? erroDoCampo(ParamDef def, String texto) {
  if (texto.trim().isEmpty) return 'Informe um valor';
  final valor = lerNumero(texto);
  if (valor == null || !valor.isFinite) return 'Nao e um numero';
  if (valor < def.min || valor > def.max) {
    return 'Fora do intervalo (${intervaloLegivel(def)})';
  }
  return null;
}
