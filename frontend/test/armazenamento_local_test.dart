// armazenamento_local_test.dart — histórico e presets no navegador.
// `setMockInitialValues` finge o localStorage; o resto é o serviço de verdade.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nnadsorption_app/services/armazenamento_local.dart';

Map<String, dynamic> _resultado(double cOut) => {
  'C_out_final': cOut,
  'C_out_points': [0.0, cOut],
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('histórico', () {
    test('comeca vazio e guarda o que foi salvo', () async {
      final historico = HistoricoLocal();
      expect(await historico.listar(), isEmpty);

      await historico.salvar(
        nome: 'Coluna piloto',
        inputs: {'L': 0.5},
        resultado: _resultado(0.3),
      );

      final lista = await historico.listar();
      expect(lista, hasLength(1));
      expect(lista.first.nome, 'Coluna piloto');
      expect(lista.first.inputs['L'], 0.5);
      expect(lista.first.resultado['C_out_final'], 0.3);
    });

    test('o mais novo entra no topo', () async {
      final historico = HistoricoLocal();
      await historico.salvar(
        nome: 'primeiro',
        inputs: {},
        resultado: _resultado(0.1),
      );
      await historico.salvar(
        nome: 'segundo',
        inputs: {},
        resultado: _resultado(0.2),
      );

      final lista = await historico.listar();
      expect(lista.map((e) => e.nome), ['segundo', 'primeiro']);
    });

    test('apagar tira só a entrada pedida', () async {
      final historico = HistoricoLocal();
      final a = await historico.salvar(
        nome: 'a',
        inputs: {},
        resultado: _resultado(0.1),
      );
      await historico.salvar(nome: 'b', inputs: {}, resultado: _resultado(0.2));

      await historico.apagar(a.id);

      final lista = await historico.listar();
      expect(lista.map((e) => e.nome), ['b']);
    });

    test('renomear troca o nome e mantém o resto', () async {
      final historico = HistoricoLocal();
      final entrada = await historico.salvar(
        nome: 'velho',
        inputs: {'L': 0.5},
        resultado: _resultado(0.3),
      );

      await historico.renomear(entrada.id, 'novo');

      final salva = (await historico.listar()).single;
      expect(salva.nome, 'novo');
      expect(salva.inputs['L'], 0.5);
      expect(salva.id, entrada.id);
    });

    test('para de crescer no teto e descarta o mais antigo', () async {
      final historico = HistoricoLocal();
      for (var i = 0; i <= HistoricoLocal.maximo; i++) {
        await historico.salvar(
          nome: 'run $i',
          inputs: {},
          resultado: _resultado(0),
        );
      }

      final lista = await historico.listar();
      expect(lista, hasLength(HistoricoLocal.maximo));
      // O 'run 0' foi o primeiro a entrar, então é o primeiro a sair
      expect(lista.map((e) => e.nome), isNot(contains('run 0')));
    });
  });

  group('presets', () {
    test('salva por nome e devolve os valores como texto', () async {
      final presets = PresetsLocal();
      await presets.salvar('base', {'L': '0.5', 'Dm': '1e-5'});

      final salvos = await presets.listar();
      expect(salvos.keys, ['base']);
      // Texto e não número: '1e-5' não pode voltar como '0.00001'
      expect(salvos['base']!['Dm'], '1e-5');
    });

    test('salvar de novo com o mesmo nome sobrescreve', () async {
      final presets = PresetsLocal();
      await presets.salvar('base', {'L': '0.5'});
      await presets.salvar('base', {'L': '1.2'});

      final salvos = await presets.listar();
      expect(salvos, hasLength(1));
      expect(salvos['base']!['L'], '1.2');
    });

    test('apagar remove só o preset pedido', () async {
      final presets = PresetsLocal();
      await presets.salvar('a', {'L': '0.5'});
      await presets.salvar('b', {'L': '1.0'});

      await presets.apagar('a');

      expect((await presets.listar()).keys, ['b']);
    });
  });
}
