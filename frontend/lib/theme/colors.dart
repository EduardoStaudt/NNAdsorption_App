// colors.dart — paletas de cores claro e escuro (tokens do mockup)
import 'package:flutter/material.dart';

/// Todas as cores do design em um só lugar, com variante clara e escura.
/// Os widgets acessam via `context.cores` — sem `isDark ? x : y` espalhado.
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;      // fundo da página
  final Color panel;   // painel principal
  final Color panel2;  // superfície secundária (cards, chips, accordions)
  final Color panel3;  // superfície de hover
  final Color line;    // borda padrão
  final Color line2;   // borda mais forte (inputs, hover, eixos)
  final Color text;    // texto principal
  final Color text2;   // texto secundário
  final Color text3;   // texto terciário (unidades, labels pequenos)
  final Color accent;  // amarelo da identidade visual
  final Color onAccent; // texto sobre o accent (quase preto)
  final Color data1;   // série 1 dos gráficos (= accent)
  final Color data2;   // série 2 dos gráficos (azul)
  final Color data3;   // série 3 dos gráficos (laranja)

  const AppColors({
    required this.bg,
    required this.panel,
    required this.panel2,
    required this.panel3,
    required this.line,
    required this.line2,
    required this.text,
    required this.text2,
    required this.text3,
    required this.accent,
    required this.onAccent,
    required this.data1,
    required this.data2,
    required this.data3,
  });

  /// Paleta escura — valores do mockup HTML
  static const escuro = AppColors(
    bg: Color(0xFF0E1013),
    panel: Color(0xFF15181D),
    panel2: Color(0xFF1B1F27),
    panel3: Color(0xFF22272F),
    line: Color(0xFF2A2E35),
    line2: Color(0xFF343C48),
    text: Color(0xFFE8EAED),
    text2: Color(0xFF9AA1AD),
    text3: Color(0xFF646B78),
    accent: Color(0xFFE6D23C),
    onAccent: Color(0xFF10130A),
    data1: Color(0xFFE6D23C),
    data2: Color(0xFF5BC8FF),
    data3: Color(0xFFFF8E63),
  );

  /// Paleta clara — mesma estrutura com fundo/texto invertidos.
  /// Accent um pouco mais escuro pra ter contraste sobre branco.
  static const claro = AppColors(
    bg: Color(0xFFFFFFFF),
    panel: Color(0xFFF5F5F7),
    panel2: Color(0xFFECEDF0),
    panel3: Color(0xFFE2E4E9),
    line: Color(0xFFE0E0E0),
    line2: Color(0xFFC9CDD4),
    text: Color(0xFF0E1013),
    text2: Color(0xFF5B6270),
    text3: Color(0xFF8A919E),
    accent: Color(0xFFD4C014),
    onAccent: Color(0xFF10130A),
    data1: Color(0xFFB8A80E),
    data2: Color(0xFF1E7FBF),
    data3: Color(0xFFE56A38),
  );

  // ThemeExtension exige copyWith e lerp; não usamos copyWith parcial,
  // então ele só devolve a própria instância.
  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: mix(bg, other.bg),
      panel: mix(panel, other.panel),
      panel2: mix(panel2, other.panel2),
      panel3: mix(panel3, other.panel3),
      line: mix(line, other.line),
      line2: mix(line2, other.line2),
      text: mix(text, other.text),
      text2: mix(text2, other.text2),
      text3: mix(text3, other.text3),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      data1: mix(data1, other.data1),
      data2: mix(data2, other.data2),
      data3: mix(data3, other.data3),
    );
  }
}

/// Atalho pra pegar a paleta do tema atual: `context.cores.accent`
extension CoresDoTema on BuildContext {
  AppColors get cores => Theme.of(this).extension<AppColors>()!;
}
