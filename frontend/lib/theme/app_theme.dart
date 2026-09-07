// app_theme.dart — ThemeData claro e escuro
import 'package:flutter/material.dart';
import 'app_sizes.dart';
import 'colors.dart';

// Tipografia do mockup (fontes locais, declaradas no pubspec.yaml):
//   Archivo (700-900)       → títulos e valores de destaque
//   IBMPlexSans (400-600)   → texto de UI e botões
//   IBMPlexMono             → números, unidades e labels técnicos (usada
//                             direto nos widgets, via fontFamily)
TextTheme _textTheme(AppColors cores) => ThemeData.light().textTheme
    .apply(fontFamily: 'IBMPlexSans')
    .copyWith(
      bodyLarge: TextStyle(fontFamily: 'IBMPlexSans', color: cores.text),
      bodyMedium: TextStyle(fontFamily: 'IBMPlexSans', color: cores.text),
      bodySmall: TextStyle(fontFamily: 'IBMPlexSans', color: cores.text2),
      titleLarge: TextStyle(
        fontFamily: 'Archivo',
        color: cores.text,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Archivo',
        color: cores.text,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      labelLarge: TextStyle(
        fontFamily: 'IBMPlexSans',
        color: cores.text,
        fontWeight: FontWeight.w600,
      ),
    );

/// Cor da marca (ícone e rótulo) dos botões do Material, seguindo a mesma
/// linguagem que o resto do app já usa: o desenho acende em âmbar quando
/// responde ao clique, em vez de ganhar um véu por baixo.
///
/// Acende em `accentForte`, não em `accent`: aqui o âmbar é *texto*, e no tema
/// claro o âmbar de sinal sobre branco fica ilegível.
WidgetStateProperty<Color?> _marcaInterativa(AppColors cores) =>
    WidgetStateProperty.resolveWith((estados) {
      if (estados.contains(WidgetState.disabled)) return cores.text3;
      if (estados.contains(WidgetState.pressed) ||
          estados.contains(WidgetState.hovered) ||
          estados.contains(WidgetState.focused)) {
        return cores.accentForte;
      }
      return cores.text2;
    });

// Monta o ThemeData a partir de uma paleta (evita duplicar claro/escuro)
ThemeData _tema(AppColors cores, Brightness brilho) => ThemeData(
  brightness: brilho,
  scaffoldBackgroundColor: cores.bg,
  extensions: [cores],
  colorScheme: ColorScheme.fromSeed(
    seedColor: cores.accent,
    brightness: brilho,
    primary: cores.accent,
    onPrimary: cores.onAccent,
    surface: cores.panel,
    onSurface: cores.text,
    // Sem isto o Material usa o vermelho padrão dele, e os erros de
    // login/cadastro sairiam numa cor diferente da dos campos do painel.
    error: cores.erro,
  ),
  textTheme: _textTheme(cores),
  dividerColor: cores.line,
  // O sistema desenha o próprio hover. Do Material sobravam duas camadas:
  //  1. ripple e highlight do InkWell — removidos aqui;
  //  2. o `overlayColor` do M3, um retângulo preenchido atrás do botão. No
  //     TextButton ele é `primary` a 8% (âmbar), mas 8% de âmbar sobre um
  //     fundo quase preto vira um oliva escuro que se lê como cinza sujo; no
  //     IconButton é `onSurfaceVariant` a 8%, aí cinza de verdade.
  // Os dois temas abaixo trocam esse véu pelo gesto que o app já usa: o
  // próprio ícone/rótulo acende em âmbar.
  //
  // O que NÃO se mexe aqui é o `hoverColor` do ThemeData. Ele já foi zerado
  // uma vez, apostando que era ele o disco cinza atrás dos ícones da topbar —
  // não era (é o `IconButtonTheme` que a própria `AppBar` embrulha em volta das
  // `actions`, resolvido no botão em `topbar.dart`). O único efeito que sobrava
  // era global e indesejado: apagava o realce de hover de todo `InkWell` do
  // app, inclusive o dos itens de FAQ da landing.
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      iconColor: _marcaInterativa(cores),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: _marcaInterativa(cores),
      iconColor: _marcaInterativa(cores),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'IBMPlexSans',
          fontSize: Tipo.corpo,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: cores.bg,
    foregroundColor: cores.text,
    elevation: 0,
    // A topbar tem uma cor só, sempre. Por padrão o M3 tinge a `AppBar` quando
    // qualquer rolagem passa por baixo dela — e como o `surfaceTint` sai da
    // `primary`, que aqui é o âmbar, rolar o painel de parâmetros lavava o topo
    // de oliva (`#0E1013` virava `#1E1E1A`). Some com o degrau de elevação e
    // com o tinte: o fio de 1px embaixo já separa a barra do conteúdo.
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    color: cores.panel,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Raio.painel),
      side: BorderSide(color: cores.line, width: Borda.fina),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: cores.panel,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Raio.campo),
      borderSide: BorderSide(color: cores.line2, width: Borda.fina),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Raio.campo),
      borderSide: BorderSide(color: cores.line2, width: Borda.fina),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Raio.campo),
      borderSide: BorderSide(color: cores.accent, width: Borda.foco),
    ),
    // Validação com `errorText` (login/cadastro) usa o mesmo vermelho e a
    // mesma geometria que o painel de parâmetros desenha à mão.
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Raio.campo),
      borderSide: BorderSide(color: cores.erro, width: Borda.foco),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Raio.campo),
      borderSide: BorderSide(color: cores.erro, width: Borda.foco),
    ),
    errorStyle: TextStyle(
      fontFamily: 'IBMPlexSans',
      fontSize: Tipo.label,
      color: cores.erro,
    ),
    labelStyle: TextStyle(
      fontFamily: 'IBMPlexSans',
      fontSize: Tipo.corpo,
      color: cores.text2,
    ),
    // Símbolo dentro do campo. É a regra do Mono nos Dados, então mora aqui:
    // todo campo com prefixo herda, nenhum redeclara. (Sem `suffixStyle`: a
    // unidade dos parâmetros saiu de dentro da caixa e virou coluna própria.)
    prefixStyle: TextStyle(
      fontFamily: 'IBMPlexMono',
      fontSize: Tipo.label,
      color: cores.text3,
    ),
  ),
  // Snackbar flutuante com o visual dos painéis
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: cores.panel2,
    contentTextStyle: TextStyle(
      fontFamily: 'IBMPlexSans',
      color: cores.text,
      fontSize: Tipo.corpo,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Raio.controle),
      side: BorderSide(color: cores.line2, width: Borda.fina),
    ),
  ),
);

ThemeData temaClaro() => _tema(AppColors.claro, Brightness.light);

ThemeData temaEscuro() => _tema(AppColors.escuro, Brightness.dark);
