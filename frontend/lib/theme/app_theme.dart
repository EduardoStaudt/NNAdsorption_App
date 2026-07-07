// app_theme.dart — ThemeData claro e escuro
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

// Tipografia do mockup:
//   Archivo (700-900)      → títulos e valores de destaque
//   IBM Plex Sans (400-600) → texto de UI e botões
//   IBM Plex Mono           → números, unidades e labels técnicos (usada
//                             direto nos widgets via GoogleFonts.ibmPlexMono)
TextTheme _textTheme(AppColors cores) =>
    GoogleFonts.ibmPlexSansTextTheme().copyWith(
      bodyLarge: GoogleFonts.ibmPlexSans(color: cores.text),
      bodyMedium: GoogleFonts.ibmPlexSans(color: cores.text),
      bodySmall: GoogleFonts.ibmPlexSans(color: cores.text2),
      titleLarge: GoogleFonts.archivo(
          color: cores.text, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      titleMedium: GoogleFonts.archivo(
          color: cores.text, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      labelLarge: GoogleFonts.ibmPlexSans(
          color: cores.text, fontWeight: FontWeight.w600),
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
        contentTextStyle: GoogleFonts.ibmPlexSans(color: cores.text, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: cores.line2),
        ),
      ),
    );

ThemeData temaClaro() => _tema(AppColors.claro, Brightness.light);

ThemeData temaEscuro() => _tema(AppColors.escuro, Brightness.dark);
