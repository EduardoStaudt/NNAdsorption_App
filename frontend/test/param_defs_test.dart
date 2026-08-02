// param_defs_test.dart — trava a estrutura dos parâmetros de entrada.
import 'package:flutter_test/flutter_test.dart';
import 'package:nnadsorption_app/models/param_defs.dart';

void main() {
  test('sao 28 chaves: 8 por componente x 2 + 12 fixos', () {
    expect(kPerComponentFields.length, 8);
    expect(kPackingFields.length + kOperationFields.length, 12);
    expect(chavesAtivas().length, kNumComponentes * 8 + 12);
    expect(chavesAtivas().length, 28);
  });

  test('nao ha chave repetida', () {
    final chaves = chavesAtivas();
    expect(chaves.toSet().length, chaves.length);
  });

  test('campo por componente vira chave indexada; campo fixo nao', () {
    expect(chavesAtivas(), contains('qm_ref_1'));
    expect(chavesAtivas(), contains('qm_ref_2'));
    expect(chavesAtivas(), contains('eps'));
  });

  test('todo valor padrao cai dentro do intervalo do seu ParamDef', () {
    final defs = defsPorChave();
    valoresPadrao().forEach((chave, valor) {
      final def = defs[chave]!;
      expect(valor, greaterThanOrEqualTo(def.min), reason: chave);
      expect(valor, lessThanOrEqualTo(def.max), reason: chave);
    });
  });

  test('padroes cobrem exatamente as chaves ativas', () {
    expect(valoresPadrao().keys.toSet(), chavesAtivas().toSet());
  });

  test('intervalo de todo campo eh min < max', () {
    for (final def in [
      ...kPerComponentFields,
      ...kPackingFields,
      ...kOperationFields,
    ]) {
      expect(def.min, lessThan(def.max), reason: def.baseKey);
    }
  });

  test('valor dentro do intervalo nao gera erro', () {
    const def = ParamDef('qm_ref', 'Carga', 'qm,ref', 'mol/kg', 1.0, 15.0);
    expect(erroDoCampo(def, '8'), isNull);
    expect(erroDoCampo(def, '1'), isNull); // limite inferior inclusivo
    expect(erroDoCampo(def, '15'), isNull); // limite superior inclusivo
    expect(erroDoCampo(def, '8,5'), isNull); // virgula decimal
  });

  test('fora do intervalo, vazio e nao-numero geram erro', () {
    const def = ParamDef('qm_ref', 'Carga', 'qm,ref', 'mol/kg', 1.0, 15.0);
    expect(erroDoCampo(def, '0.9'), contains('1 a 15'));
    expect(erroDoCampo(def, '15.1'), contains('1 a 15'));
    expect(erroDoCampo(def, ''), 'Informe um valor');
    expect(erroDoCampo(def, 'abc'), 'Nao e um numero');
  });

  test('limites minusculos saem em notacao cientifica na mensagem', () {
    const def = ParamDef('Dm', 'Difusividade', 'D_m', 'm²/s', 5e-6, 3e-5);
    expect(intervaloLegivel(def), '5e-6 a 3e-5');
  });

  test('numero inteiro nao carrega .0', () {
    expect(formatarNumero(3200.0), '3200');
    expect(formatarNumero(0.5), '0.5');
    expect(formatarNumero(-0.1), '-0.1');
    expect(formatarNumero(0), '0');
  });

  test('texto padrao usa o mesmo formato da mensagem e volta a ser numero', () {
    final textos = textosPadrao();
    expect(textos['rho_b'], '650'); // e nao '650.0'
    expect(textos['Dm'], '1e-5');
    // Tudo que entra no campo tem que ser relido sem erro
    final defs = defsPorChave();
    textos.forEach((chave, texto) {
      expect(erroDoCampo(defs[chave]!, texto), isNull, reason: chave);
    });
  });

  test('campoValido concorda com erroDoCampo', () {
    const def = ParamDef('qm_ref', 'Carga', 'qm,ref', 'mol/kg', 1.0, 15.0);
    for (final texto in ['8', '0.9', '', 'abc', '15']) {
      expect(campoValido(def, texto), erroDoCampo(def, texto) == null,
          reason: texto);
    }
  });

  test('componentes 1 e 2 tem papel nomeado; alem disso eh generico', () {
    expect(nomeComponente(1), 'Comp 1 · Carregador');
    expect(nomeComponente(2), 'Comp 2 · Forte');
    expect(nomeComponente(3), 'Comp 3');
  });
}
