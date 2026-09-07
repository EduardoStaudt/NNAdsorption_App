// exportar_test.dart — exportação de uma predição só: a planilha (que é a do
// lote com uma linha) e o modal que escolhe o que vai nela.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nnadsorption_app/inferencia/lote_local.dart';
import 'package:nnadsorption_app/models/resultado_binario.dart';
import 'package:nnadsorption_app/theme/app_theme.dart';
import 'package:nnadsorption_app/widgets/dialogo_exportar.dart';
import 'package:nnadsorption_app/widgets/ui_comum.dart';

Future<void> _abrir(WidgetTester tester, {String nome = 'leito curto'}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(900, 800);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: temaEscuro(),
      home: Scaffold(
        body: DialogoExportar(
          nome: nome,
          resultado: ResultadoBinario.exemplo(),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// O aviso do CSV e o rótulo do botão são o que a tela promete; achar o
/// primeiro é o mesmo que dizer "as curvas não vão nesse arquivo".
final _avisoCsv = find.textContaining('CSV exporta só escalares');

void main() {
  group('planilha de uma predição', () {
    test('o CSV sai com cabeçalho e uma linha só', () {
      final bytes = loteParaCsv(
        loteDeUm('exp', ResultadoBinario.exemplo()),
        todosOsEscalares,
      );
      final linhas = utf8.decode(bytes).trim().split('\n');

      expect(linhas.length, 2);
      expect(
        linhas.first.trim(),
        'nome,tbreak,tsat,TF,tst,pi_max,severidade,avisos',
      );
      expect(linhas[1], startsWith('exp,'));
    });

    test('o XLSX sai como zip, com e sem a aba de resumo', () {
      final lote = loteDeUm('exp', ResultadoBinario.exemplo());
      final comTudo = loteParaXlsx(lote, todosOsEscalares, comCurvas: true);
      final soCurvas = loteParaXlsx(
        lote,
        todosOsEscalares,
        comCurvas: true,
        comResumo: false,
      );

      // 'PK': todo .xlsx é um zip
      expect(comTudo.take(2), [0x50, 0x4B]);
      expect(soCurvas.take(2), [0x50, 0x4B]);
      // Sem a aba de resumo o arquivo tem que ser menor
      expect(soCurvas.length, lessThan(comTudo.length));
    });
  });

  group('modal de exportar', () {
    testWidgets('abre em escalares e XLSX, sem aviso', (tester) async {
      await _abrir(tester);

      expect(find.text('Escalares'), findsOneWidget);
      expect(find.text('Curvas completas'), findsOneWidget);
      expect(_avisoCsv, findsNothing);
      // O nome do arquivo que vai sair aparece no rodapé
      expect(find.text('leito_curto_resultado.xlsx'), findsOneWidget);
    });

    testWidgets('curvas em CSV avisam que ficam de fora', (tester) async {
      await _abrir(tester);
      await tester.tap(find.text('Curvas completas'));
      await tester.pump();
      expect(_avisoCsv, findsNothing);

      await tester.tap(find.text('CSV'));
      await tester.pump();

      expect(_avisoCsv, findsOneWidget);
      expect(find.text('leito_curto_resultado.csv'), findsOneWidget);
    });

    testWidgets('sem conteúdo marcado o baixar trava', (tester) async {
      await _abrir(tester);
      await tester.tap(find.text('Escalares'));
      await tester.pump();

      final botao = tester.widget<BotaoPrimario>(find.byType(BotaoPrimario));
      expect(botao.texto, 'Baixar');
      expect(botao.onTap, isNull);
      expect(find.text('Escolha ao menos um conteúdo'), findsOneWidget);
    });

    testWidgets('sem nome o arquivo leva a data', (tester) async {
      await _abrir(tester, nome: '   ');

      expect(find.textContaining('predicao_'), findsOneWidget);
      expect(find.textContaining('_resultado.xlsx'), findsOneWidget);
    });
  });
}
