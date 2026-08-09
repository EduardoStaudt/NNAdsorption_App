// theme_hover_test.dart — o hover dos botões do Material tem que falar a
// mesma língua do resto do app: a marca acende em âmbar, nada de véu por trás.
//
// A marca acende em `accentForte`, não em `accent`: no tema claro o âmbar de
// sinal sobre branco dá ~1.7:1 e o ícone some justo quando o cursor chega.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nnadsorption_app/theme/app_theme.dart';
import 'package:nnadsorption_app/theme/colors.dart';

void main() {
  for (final (nome, tema, cores) in [
    ('escuro', temaEscuro(), AppColors.escuro),
    ('claro', temaClaro(), AppColors.claro),
  ]) {
    group('tema $nome', () {
      test('IconButton: sem véu, ícone âmbar no hover', () {
        final estilo = tema.iconButtonTheme.style!;

        expect(
          estilo.overlayColor!.resolve({WidgetState.hovered}),
          Colors.transparent,
        );
        expect(estilo.iconColor!.resolve({}), cores.text2);
        expect(
          estilo.iconColor!.resolve({WidgetState.hovered}),
          cores.accentForte,
        );
        expect(
          estilo.iconColor!.resolve({WidgetState.pressed}),
          cores.accentForte,
        );
        expect(estilo.iconColor!.resolve({WidgetState.disabled}), cores.text3);
      });

      test('TextButton: sem véu, rótulo e ícone âmbar no hover', () {
        final estilo = tema.textButtonTheme.style!;

        expect(
          estilo.overlayColor!.resolve({WidgetState.hovered}),
          Colors.transparent,
        );
        expect(estilo.foregroundColor!.resolve({}), cores.text2);
        expect(
          estilo.foregroundColor!.resolve({WidgetState.hovered}),
          cores.accentForte,
        );
        expect(
          estilo.iconColor!.resolve({WidgetState.hovered}),
          cores.accentForte,
        );
      });

      test('o ripple do Material continua desligado', () {
        expect(tema.splashFactory, NoSplash.splashFactory);
        expect(tema.highlightColor, Colors.transparent);
        // Mas o `hoverColor` fica de pé: zerá-lo não tirava véu de botão nenhum
        // (quem faz isso é o `overlayColor`) e apagava o hover de todo `InkWell`
        // do app — os itens de FAQ da landing perderam o realce por causa disso.
        expect(tema.hoverColor, isNot(Colors.transparent));
      });
    });
  }
}
