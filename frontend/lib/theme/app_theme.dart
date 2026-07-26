// app_theme.dart — ThemeData claro e escuro
import 'package:flutter/material.dart';
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
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cores.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cores.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cores.line2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cores.line2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cores.accent, width: 1.5),
        ),
      ),
      // Snackbar flutuante com o visual dos painéis
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cores.panel2,
        contentTextStyle: TextStyle(fontFamily: 'IBMPlexSans', color: cores.text, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: cores.line2),
        ),
      ),
    );

ThemeData temaClaro() => _tema(AppColors.claro, Brightness.light);

ThemeData temaEscuro() => _tema(AppColors.escuro, Brightness.dark);
