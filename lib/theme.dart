import 'package:flutter/material.dart';

// ─── Colores (los mismos de S06; ahora con nombre y rol) ─────────────────
const kFondo = Color(0xFF0E120C); // fondo de pantalla
const kSuperficie = Color(0xFF181E14); // tarjetas, hojas, secciones
const kBorde = Color(0xFF2A3222); // líneas y contornos
const kTexto = Color(0xFFF1F4EA); // texto principal
const kMuted = Color(0xFF8F9C80); // texto secundario
const kLima = Color(0xFFC8F54E); // acento: acción principal y "lo bueno"
const kIconoFondo = Color(0xFF37491C); // fondo de iconos y selección
const kPeligro = Color(0xFFFF8A80); // errores, excesos, borrar

// ─── S17-01: tokens de diseño ────────────────────────────────────────────
// Un sistema de diseño empieza por NOMBRAR las decisiones. Si cada pantalla
// escribe su propio `EdgeInsets.all(14)` y `circular(15)`, la app se ve
// "casi igual" en todas partes, que es peor que diferente.

/// Espaciado: múltiplos de 4. Nada de 14, 22 o 28 sueltos.
abstract final class Espacio {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Radios con JERARQUÍA: lo pequeño se redondea poco, lo grande más.
abstract final class Redondeo {
  static const control = 12.0; // campos, chips, botones
  static const tarjeta = 20.0; // tarjetas y secciones
  static const hoja = 28.0; // hojas inferiores
}

/// Una sola familia (Space Grotesk, incluida en assets/fonts con su licencia
/// OFL) con números tabulares: en una app de dinero las cifras deben alinearse.
const kFuente = 'SpaceGrotesk';
const kNumerosTabulares = [FontFeature.tabularFigures()];

ThemeData buildInkashTheme() {
  const esquema = ColorScheme.dark(
    primary: kLima,
    onPrimary: kFondo,
    secondary: kLima,
    surface: kSuperficie,
    onSurface: kTexto,
    error: kPeligro,
    outline: kBorde,
  );

  // Escala tipográfica: pocos tamaños, cada uno con un rol.
  const texto = TextTheme(
    displayLarge: TextStyle(
      fontSize: 52,
      fontWeight: FontWeight.w500,
      letterSpacing: -1.5,
      height: 1.05,
      fontFeatures: kNumerosTabulares,
    ), // el saldo del Inicio
    headlineSmall: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.5,
    ), // título de pantalla
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    bodySmall: TextStyle(fontSize: 12, color: kMuted),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );

  final bordeControl = OutlineInputBorder(
    borderRadius: BorderRadius.circular(Redondeo.control),
    borderSide: const BorderSide(color: kBorde),
  );

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: esquema,
    scaffoldBackgroundColor: kFondo,
    fontFamily: kFuente,
    textTheme: texto.apply(bodyColor: kTexto, displayColor: kTexto),
    appBarTheme: const AppBarTheme(
      backgroundColor: kFondo,
      foregroundColor: kTexto,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: kFuente,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: kTexto,
      ),
    ),
    // Campos: rellenos, con borde que se vuelve lima al enfocarse.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kFondo,
      contentPadding: const EdgeInsets.all(Espacio.l),
      labelStyle: const TextStyle(color: kMuted),
      hintStyle: const TextStyle(color: kMuted),
      helperStyle: const TextStyle(color: kMuted),
      border: bordeControl,
      enabledBorder: bordeControl,
      focusedBorder: bordeControl.copyWith(
        borderSide: const BorderSide(color: kLima, width: 2),
      ),
      errorBorder: bordeControl.copyWith(
        borderSide: const BorderSide(color: kPeligro),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: kLima,
        foregroundColor: kFondo,
        disabledBackgroundColor: kBorde,
        disabledForegroundColor: kMuted,
        textStyle: const TextStyle(
          fontFamily: kFuente,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Redondeo.control),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kLima),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: kLima,
        selectedForegroundColor: kFondo,
        foregroundColor: kMuted,
        side: const BorderSide(color: kBorde),
        minimumSize: const Size(0, 48),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kSuperficie,
      selectedColor: kIconoFondo,
      side: const BorderSide(color: kBorde),
      showCheckmark: false,
      labelStyle: const TextStyle(fontFamily: kFuente, color: kTexto),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Redondeo.control),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kSuperficie,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Redondeo.hoja),
        ),
      ),
    ),
    // Etiquetas de la barra en 11: "Presupuesto" cabe sin cortarse.
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kSuperficie,
      selectedItemColor: kLima,
      unselectedItemColor: kMuted,
      selectedLabelStyle: TextStyle(
        fontFamily: kFuente,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(fontFamily: kFuente, fontSize: 11),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kLima,
      foregroundColor: kFondo,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: kMuted,
      // Título y subtítulo con jerarquía: el subtítulo es contexto.
      titleTextStyle: TextStyle(
        fontFamily: kFuente,
        fontSize: 16,
        color: kTexto,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: kFuente,
        fontSize: 13,
        color: kMuted,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: Espacio.l),
    ),
    dividerTheme: const DividerThemeData(color: kBorde, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kTexto,
      contentTextStyle: const TextStyle(fontFamily: kFuente, color: kFondo),
      actionTextColor: kIconoFondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Redondeo.control),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: kLima,
      linearTrackColor: kBorde,
    ),
    cardTheme: CardThemeData(
      color: kSuperficie,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Redondeo.tarjeta),
        side: const BorderSide(color: kBorde),
      ),
    ),
  );
}
