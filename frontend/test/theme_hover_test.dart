// theme_hover_test.dart — o hover dos botões do Material tem que falar a
// mesma língua do resto do app: a marca acende em âmbar, nada de véu por trás.
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
        expect(estilo.iconColor!.resolve({WidgetState.hovered}), cores.accent);
        expect(estilo.iconColor!.resolve({WidgetState.pressed}), cores.accent);
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
          cores.accent,
        );
        expect(estilo.iconColor!.resolve({WidgetState.hovered}), cores.accent);
      });

      test('o ripple do Material continua desligado', () {
        expect(tema.splashFactory, NoSplash.splashFactory);
        expect(tema.highlightColor, Colors.transparent);
      });
    });
  }
}
