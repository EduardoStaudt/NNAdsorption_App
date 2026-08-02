// app_theme.dart — ThemeData claro e escuro
import 'package:flutter/material.dart';
import 'app_sizes.dart';
import 'colors.dart';

// Tipografia do mockup (fontes locais, declaradas no pubspec.yaml):
//   Archivo (700-900)       → títulos e valores de destaque
//   IBMPlexSans (400-600)   → texto de UI e botões
//   IBMPlexMono             → números, unidades e labels técnicos (usada
//                             direto nos widgets, via fontFamily)
TextTheme _textTheme(AppColors cores) =>
    ThemeData.light().textTheme.apply(fontFamily: 'IBMPlexSans').copyWith(
          bodyLarge: TextStyle(fontFamily: 'IBMPlexSans', color: cores.text),
          bodyMedium: TextStyle(fontFamily: 'IBMPlexSans', color: cores.text),
          bodySmall: TextStyle(fontFamily: 'IBMPlexSans', color: cores.text2),
          titleLarge: TextStyle(
              fontFamily: 'Archivo',
              color: cores.text,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5),
          titleMedium: TextStyle(
              fontFamily: 'Archivo',
              color: cores.text,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2),
          labelLarge: TextStyle(
              fontFamily: 'IBMPlexSans',
              color: cores.text,
              fontWeight: FontWeight.w600),
        );

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
      appBarTheme: AppBarTheme(
        backgroundColor: cores.bg,
        foregroundColor: cores.text,
        elevation: 0,
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
