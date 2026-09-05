// inferencia_test.dart — o porte em Dart tem que bater com a lib Python.
//
// Os números de referência saíram de `reference/exemplo_inferencia.py` e
// `features_22.py` rodados sobre os valores padrão da tela, convertidos pras
// unidades do contrato. Se algum destes testes cair, o porte divergiu da
// referência canônica — conferir, nesta ordem: ordem das 31 colunas (Dt é o
// ÚLTIMO global), enriquece-antes-loga-depois, e nenhum z-score em lugar nenhum.
//
// A cascata com os `.onnx` não roda aqui (precisa de navegador); o que este
// arquivo tranca é toda a matemática que **não** está dentro do modelo.
import 'package:flutter_test/flutter_test.dart';

import 'package:nnadsorption_app/inferencia/contrato.dart';
import 'package:nnadsorption_app/inferencia/features.dart';
import 'package:nnadsorption_app/inferencia/grade_tau.dart';
import 'package:nnadsorption_app/inferencia/isoterma.dart';
import 'package:nnadsorption_app/models/param_defs.dart';

/// X(31) que o Python usou, na ordem do contrato.
const _x31Python = <double>[
  8.0,
  -0.02,
  0.1,
  1500.0,
  1.0,
  0.0,
  0.1,
  25000.0,
  29.0,
  8.0,
  -0.02,
  0.1,
  1500.0,
  1.0,
  0.0,
  0.1,
  25000.0,
  37.0,
  0.4,
  650.0,
  1000.0,
  0.01,
  298.0,
  1000000.0,
  0.5,
  50.0,
  0.4,
  0.002,
  0.00001,
  0.035,
  0.5,
];

/// X(47) depois de enriquecer e logar, como o Python entrega à rede.
const _x47Python = <double>[
  8.0,
  -0.02,
  -2.3025850929940455,
  1500.0,
  1.0,
  0.0,
  -2.3025850929940455,
  25000.0,
  29.0,
  8.0,
  -0.02,
  -2.3025850929940455,
  1500.0,
  1.0,
  0.0,
  -2.3025850929940455,
  25000.0,
  37.0,
  0.4,
  650.0,
  1000.0,
  0.01,
  298.0,
  1000000.0,
  0.5,
  50.0,
  0.4,
  0.002,
  0.00001,
  0.035,
  0.5,
  2.995732307434082,
  1.6094379425048828,
  1.6094379425048828,
  6.214608192443848,
  5.307329177856445,
  5.307329177856445,
  3.4477546215057373,
  3.4477546215057373,
  0.0,
  0.0,
  0.03846153989434242,
  0.03846153989434242,
  0.0,
  0.6931471824645996,
  0.5965517163276672,
  3.0657637119293213,
];

const _tstPython = 339.9645945610332;
const _tbPython = 201.02674865722656;
const _tsPython = 500.4059753417969;
const _tfPython = 679.9291891220664;

/// Grade τ que o Python monta para esses tb/ts.
const _tauPython = <double>[
  0.0,
  0.02456583595371085,
  0.0491316719074217,
  0.07369750786113255,
  0.0982633438148434,
  0.12282917976855426,
  0.1473950157222651,
  0.17196085167597597,
  0.1965266876296868,
  0.22109252358339765,
  0.24565835953710852,
  0.2526627798182249,
  0.2596672000993413,
  0.26667162038045766,
  0.2736760406615741,
  0.28068046094269045,
  0.28768488122380687,
  0.29468930150492323,
  0.30169372178603965,
  0.308698142067156,
  0.31570256234827243,
  0.3227069826293888,
  0.32971140291050516,
  0.3367158231916216,
  0.343720243472738,
  0.35072466375385436,
  0.3577290840349707,
  0.36473350431608714,
  0.37173792459720356,
  0.3787423448783199,
  0.3857467651594363,
  0.3927511854405527,
  0.3997556057216691,
  0.4067600260027855,
  0.41376444628390185,
  0.4207688665650182,
  0.42777328684613464,
  0.43477770712725106,
  0.4417821274083674,
  0.4487865476894838,
  0.4557909679706002,
  0.4627953882517166,
  0.469799808532833,
  0.47680422881394935,
  0.48380864909506577,
  0.4908130693761822,
  0.49781748965729855,
  0.5048219099384149,
  0.5118263302195314,
  0.5188307505006478,
  0.5258351707817641,
  0.5328395910628805,
  0.5398440113439968,
  0.5468484316251132,
  0.5538528519062297,
  0.560857272187346,
  0.5678616924684625,
  0.5748661127495789,
  0.5818705330306952,
  0.5888749533118116,
  0.595879373592928,
  0.6028837938740443,
  0.6098882141551607,
  0.6168926344362772,
  0.6238970547173935,
  0.63090147499851,
  0.6379058952796264,
  0.6449103155607427,
  0.6519147358418591,
  0.6589191561229755,
  0.6659235764040918,
  0.6729279966852083,
  0.6799324169663247,
  0.6869368372474411,
  0.6939412575285575,
  0.7009456778096739,
  0.7079500980907902,
  0.7149545183719066,
  0.721958938653023,
  0.7289633589341393,
  0.749169390254493,
  0.7623710012937303,
  0.7755726123329674,
  0.7887742233722046,
  0.8019758344114418,
  0.815177445450679,
  0.8283790564899163,
  0.8415806675291535,
  0.8547822785683907,
  0.867983889607628,
  0.8811855006468651,
  0.8943871116861023,
  0.9075887227253395,
  0.9207903337645768,
  0.933991944803814,
  0.9471935558430511,
  0.9603951668822883,
  0.9735967779215255,
  0.9867983889607628,
  1.0,
];

void main() {
  group('contrato', () {
    test('as 31 colunas estão na ordem da rede, com Dt no fim', () {
      expect(kColunasContrato.length, 31);
      expect(kColunasContrato[24], 'L');
      expect(kColunasContrato[25], 'hw');
      // O erro clássico: Dt logo depois de L, como a tela mostra.
      expect(kColunasContrato[28], 'Dm');
      expect(kColunasContrato[29], 'Dt');
      expect(kColunasContrato[30], 'y0');
    });

    test('LOG_X_IDX aponta pros B_ref e kL dos dois componentes', () {
      expect(kLogXIdx, [2, 11, 6, 15]);
      for (final i in kLogXIdx) {
        expect(kColunasContrato[i], anyOf(endsWith('B_ref'), endsWith('kL')));
      }
    });

    test('os padrões da tela viram o X(31) do Python', () {
      final x = montarX31(valoresPadrao());
      expect(x.length, 31);
      for (var i = 0; i < 31; i++) {
        expect(
          x[i],
          closeTo(_x31Python[i], _x31Python[i].abs() * 1e-12 + 1e-12),
          reason: 'coluna $i (${kColunasContrato[i]})',
        );
      }
    });

    test('converte kJ/mol, MPa e mm pras unidades do contrato', () {
      final x = montarX31(valoresPadrao());
      expect(x[7], 25000.0); // −ΔH: 25 kJ/mol → J/mol
      expect(x[23], 1.0e6); // P: 1 MPa → Pa
      expect(x[27], closeTo(2.0e-3, 1e-15)); // d_p: 2 mm → m
    });

    test('parâmetro fora da faixa vira aviso, não erro', () {
      final x = montarX31({...valoresPadrao(), 'L': 99.0});
      final avisos = validar(x);
      expect(avisos.length, 1);
      expect(avisos.first, contains('L = 99'));
    });

    test('os padrões da tela não geram aviso nenhum', () {
      expect(validar(montarX31(valoresPadrao())), isEmpty);
    });
  });

  group('features', () {
    test('enriquece 31 em 47', () {
      expect(xEnriquecido(_x31Python).length, 47);
      expect(kNomesFeatures.length, 16);
    });

    test('cada uma das 47 colunas bate com o Python', () {
      final x47 = xEnriquecido(_x31Python);
      for (var i = 0; i < 47; i++) {
        expect(
          x47[i],
          closeTo(_x47Python[i], _x47Python[i].abs() * 1e-9 + 1e-9),
          reason: 'coluna $i',
        );
      }
    });

    test('as colunas de log foram logadas depois do enriquecimento', () {
      final x47 = xEnriquecido(_x31Python);
      // B_ref cru é 0.1; logado dá ln(0.1)
      expect(x47[2], closeTo(-2.302585092994046, 1e-12));
      // e a feature selet_B, calculada ANTES do log, usa B_ref = 0.1 nos dois
      // componentes: razão 1 → ln(1) = 0
      expect(x47[31 + kNomesFeatures.indexOf('selet_B')], closeTo(0.0, 1e-12));
    });

    test('severidade fica em [0,1] e bate com o Python', () {
      final s = severidadeRegime(_x31Python);
      expect(s, inInclusiveRange(0.0, 1.0));
      // Tolerância de float32: a severidade que vai pro KPI é calculada em
      // double, e a que entra no vetor da rede passou pelo arredondamento de
      // float32 do `features_22.py`. São o mesmo número em precisões
      // diferentes — comparar em 1e-9 seria comparar o arredondamento.
      expect(
        s,
        closeTo(_x47Python[31 + kNomesFeatures.indexOf('severidade')], 1e-6),
      );
    });
  });

  group('isoterma', () {
    test('tst bate com a forma fechada do Python', () {
      expect(tstAncora(_x31Python), closeTo(_tstPython, 1e-9));
    });

    test('leito mais longo, âncora maior', () {
      final maisLongo = [..._x31Python]..[24] = 1.0;
      expect(tstAncora(maisLongo), greaterThan(tstAncora(_x31Python)));
    });

    test('tst nunca passa de 1800 s (o TF é capado em 3600)', () {
      final extremo = [..._x31Python]
        ..[24] =
            1.5 // L
        ..[21] = 0.001; // vs
      expect(tstAncora(extremo), closeTo(1800.0, 1e-9));
    });
  });

  group('grade τ', () {
    test('são 100 pontos, entre 0 e 1, crescentes', () {
      final tau = gradeTau(_tbPython / _tfPython, _tsPython / _tfPython);
      expect(tau.length, kPontosCurva);
      expect(tau.first, 0.0);
      expect(tau.last, closeTo(1.0, 1e-12));
      for (var i = 1; i < tau.length; i++) {
        expect(tau[i], greaterThanOrEqualTo(tau[i - 1]));
      }
    });

    test('cada ponto bate com o grid_tau do Python', () {
      final tau = gradeTau(_tbPython / _tfPython, _tsPython / _tfPython);
      for (var i = 0; i < kPontosCurva; i++) {
        expect(tau[i], closeTo(_tauPython[i], 1e-9), reason: 'ponto $i');
      }
    });

    test('o eixo em segundos é τ vezes TF', () {
      final t = montarEixoTempo(_tbPython, _tsPython, _tfPython);
      expect(t.length, kPontosCurva);
      expect(t.last, closeTo(_tfPython, 1e-9));
      expect(t[50], closeTo(_tauPython[50] * _tfPython, 1e-9));
    });
  });
}
