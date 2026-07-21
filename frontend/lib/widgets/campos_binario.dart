// campos_binario.dart — estrutura de dados dos 28 inputs do modelo binário.
// Só a estrutura (blocos + campos), sem widget visual: a tela ainda não existe.
// Reaproveita a classe InputField já definida em parameters_panel.dart.
import 'parameters_panel.dart' show InputField;

// Bloco de campos: mesmo formato de _grupos em parameters_panel.dart.
typedef GrupoBinario = ({String titulo, List<InputField> campos});

// Os 8 campos de isoterma/cinética existem por componente (sufixo _1 e _2);
// gerados aqui para não duplicar a lista dos dois componentes.
List<InputField> _isotermaCinetica(int comp) => [
      InputField('qm_ref_$comp', 'Carga de saturação (298K)', 'qm_ref_$comp', 'mol/kg'),
      InputField('k2_$comp', 'Inclinação carga-temperatura', 'k2_$comp', 'mol/kg/K'),
      InputField('Bref_$comp', 'Afinidade (298K)', 'Bref_$comp', 'atm^-n'),
      InputField('k4_$comp', 'Fator exponencial da afinidade', 'k4_$comp', 'K'),
      InputField('nref_$comp', 'Heterogeneidade (298K)', 'nref_$comp', ''),
      InputField('k6_$comp', 'Inclinação da heterogeneidade', 'k6_$comp', 'K'),
      InputField('kL_$comp', 'Coeficiente LDF', 'kL_$comp', 's^-1'),
      InputField('dH_$comp', 'Calor de adsorção', 'dH_$comp', 'kJ/mol'),
    ];

// Os 4 blocos com os 28 campos do modelo binário.
final List<GrupoBinario> gruposBinario = [
  (
    titulo: 'Isoterma / Cinética',
    campos: [
      ..._isotermaCinetica(1),
      ..._isotermaCinetica(2),
    ],
  ),
  (
    titulo: 'Leito',
    campos: [
      InputField('eps_b', 'Porosidade do leito', 'eps_b', ''),
      InputField('rho_b', 'Massa específica aparente', 'rho_b', 'kg/m³'),
      InputField('cp_s', 'Capacidade calorífica do sólido', 'cp_s', 'J/kg/K'),
    ],
  ),
  (
    titulo: 'Operação / Geometria',
    campos: [
      InputField('vs', 'Velocidade superficial', 'vs', 'm/s'),
      InputField('T_in', 'Temperatura de alimentação', 'T_in', 'K'),
      InputField('P', 'Pressão', 'P', 'MPa'),
      InputField('L', 'Comprimento do leito', 'L', 'm'),
      InputField('hw', 'Coef. de troca com a parede', 'hw', 'W/m²/K'),
      InputField('lambda_ax', 'Condutividade axial', 'lambda_ax', 'W/m/K'),
      InputField('dp', 'Diâmetro de partícula', 'dp', 'mm'),
      InputField('Dm', 'Difusividade molecular', 'Dm', 'm²/s'),
    ],
  ),
  (
    titulo: 'Composição',
    campos: [
      InputField('y0', 'Fração do carreador na alimentação', 'y0', ''),
    ],
  ),
];
