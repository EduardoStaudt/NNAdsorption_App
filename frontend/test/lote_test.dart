// lote_test.dart — colunas do contrato, prévia local do CSV e modal de lote.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nnadsorption_app/models/lote_defs.dart';
import 'package:nnadsorption_app/theme/app_theme.dart';
import 'package:nnadsorption_app/widgets/dialogo_lote.dart';
import 'package:nnadsorption_app/widgets/ui_comum.dart';

/// CSV de teste com o cabeçalho completo e `n` linhas de dados.
String _csv({int linhas = 2, List<String>? tirar}) {
  final colunas = ['nome', ...kColunasLote]
    ..removeWhere((c) => tirar?.contains(c) ?? false);
  final dados = [
    for (var i = 0; i < linhas; i++)
      [
        for (final c in colunas) c == 'nome' ? 'exp_$i' : '${i + 1}.5',
      ].join(','),
  ];
  return '${colunas.join(',')}\n${dados.join('\n')}\n';
}

/// A prévia lê bytes (não decodifica o arquivo inteiro); os testes escrevem
/// texto, então a conversão fica aqui.
PreviaLote? _previaDe(String texto) => lerPreviaCsv(utf8.encode(texto));

Future<void> _abrirModal(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: temaEscuro(),
      home: const Scaffold(body: DialogoLote()),
    ),
  );
  await tester.pump();
}

void main() {
  group('colunas do contrato', () {
    test('são 31, na ordem que a rede espera', () {
      final colunas = kColunasLote;

      expect(colunas.length, 31);
      expect(colunas.first, 'c0_qm_ref');
      expect(colunas[9], 'c1_qm_ref');
      expect(colunas.last, 'y0');
    });

    test('cada componente tem os mesmos 9 parâmetros', () {
      final colunas = kColunasLote;
      for (final p in kParamsPorComponente) {
        expect(colunas, contains('c0_$p'));
        expect(colunas, contains('c1_$p'));
      }
    });
  });

  group('prévia do CSV', () {
    test('conta as linhas de dados, sem o cabeçalho', () {
      final previa = _previaDe(_csv(linhas: 7))!;

      expect(previa.totalLinhas, 7);
      expect(previa.colunas.first, 'nome');
      expect(previa.faltando, isEmpty);
      expect(previa.valida, isTrue);
    });

    test('a amostra para em kLinhasPrevia', () {
      final previa = _previaDe(_csv(linhas: 50))!;

      expect(previa.totalLinhas, 50);
      expect(previa.amostra.length, kLinhasPrevia);
    });

    test('acusa a coluna que falta antes de subir o arquivo', () {
      final previa = _previaDe(_csv(tirar: ['c1_Cpg', 'y0']))!;

      expect(previa.faltando, ['c1_Cpg', 'y0']);
      expect(previa.valida, isFalse);
    });

    test('respeita vírgula dentro de aspas', () {
      final previa = _previaDe('nome,a,b\n"exp, um",1,2\n')!;

      expect(previa.amostra.first, ['exp, um', '1', '2']);
    });

    test('ignora linha em branco no fim do arquivo', () {
      final previa = _previaDe('${_csv(linhas: 3)}\n\n')!;

      expect(previa.totalLinhas, 3);
    });

    test('arquivo vazio não vira prévia', () {
      expect(_previaDe('   \n'), isNull);
    });
  });

  group('modal de lote', () {
    testWidgets('abre nas duas abas, com a de upload na frente', (
      tester,
    ) async {
      await _abrirModal(tester);

      expect(find.text('Predição em lote'), findsOneWidget);
      expect(find.text('Upload de arquivo'), findsOneWidget);
      expect(find.text('Varredura'), findsOneWidget);
      expect(find.textContaining('.csv ou .xlsx'), findsOneWidget);
    });

    testWidgets('a aba de varredura é um aviso, não um formulário', (
      tester,
    ) async {
      await _abrirModal(tester);
      await tester.tap(find.text('Varredura'));
      await tester.pumpAndSettle();

      expect(
        find.text('Geração por varredura em desenvolvimento'),
        findsOneWidget,
      );
      // Sem arquivo pra rodar, o rodapé de ação sai junto com a aba
      expect(find.text('Rodar lote'), findsNothing);
    });

    testWidgets('escalares vem marcado e curvas não', (tester) async {
      await _abrirModal(tester);

      expect(find.text('Escalares'), findsOneWidget);
      expect(find.text('Curvas completas'), findsOneWidget);
      // Os seis nomes só aparecem porque "Escalares" está ligado
      for (final (_, rotulo) in kEscalaresLote) {
        expect(find.text(rotulo), findsOneWidget);
      }
    });

    testWidgets('desligar escalares recolhe a lista de colunas', (
      tester,
    ) async {
      await _abrirModal(tester);
      await tester.tap(find.text('Escalares'));
      await tester.pump();

      expect(find.text('severidade'), findsNothing);
    });

    testWidgets('o formato começa em XLSX e troca no clique', (tester) async {
      await _abrirModal(tester);

      // 'CSV'/'XLSX' tambem sao os rotulos dos botoes de template, entao a
      // busca precisa dizer que e o chip.
      Finder rotuloDoChip(String rotulo) => find.descendant(
        of: find.byType(ChipAba),
        matching: find.text(rotulo),
      );
      ChipAba chip(String rotulo) => tester.widget<ChipAba>(
        find.ancestor(of: rotuloDoChip(rotulo), matching: find.byType(ChipAba)),
      );

      expect(chip('XLSX').ativo, isTrue);
      expect(chip('CSV').ativo, isFalse);

      await tester.tap(rotuloDoChip('CSV'));
      await tester.pump();

      expect(chip('CSV').ativo, isTrue);
      expect(chip('XLSX').ativo, isFalse);
    });

    testWidgets('sem arquivo o botão de rodar fica travado', (tester) async {
      await _abrirModal(tester);

      final botao = tester.widget<BotaoPrimario>(
        find.byType(BotaoPrimario).first,
      );
      expect(botao.texto, 'Rodar lote');
      expect(botao.onTap, isNull);
    });
  });
}
