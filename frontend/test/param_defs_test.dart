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

  test('componentes 1 e 2 tem papel nomeado; alem disso eh generico', () {
    expect(nomeComponente(1), 'Comp 1 · Carregador');
    expect(nomeComponente(2), 'Comp 2 · Forte');
    expect(nomeComponente(3), 'Comp 3');
    expect(kNumComponentes, lessThanOrEqualTo(kMaxComponentes));
  });
}
