import 'package:flutter/material.dart';

import 'transitions.dart';

/// Gymco — Volt edition. Dark only: electric lime on near-black, pill
/// buttons with a lime-to-mint glow, a serif italic accent in titles.
abstract final class Volt {
  static const bg = Color(0xFF0A0B09);
  static const card = Color(0xFF15171A);
  static const card2 = Color(0xFF1F2226);
  static const sheet = Color(0xFF111315);
  static const line = Color(0xFF2A2E33);
  static const line2 = Color(0xFF3A3F45);

  static const t1 = Color(0xFFF5F7F0);
  static const t2 = Color(0xFFC9CEC4);
  static const t3 = Color(0xFF8D948A);
  static const t4 = Color(0xFF5F665C);

  static const brand = Color(0xFFC6F432);
  static const brandInk = Color(0xFFD9FF5C);
  static const brandWash = Color(0xFF1A230D);
  static const brandEdge = Color(0xFF4D6B12);

  static const ok = Color(0xFF7CF0B0);
  static const okWash = Color(0xFF11301F);
  static const warn = Color(0xFFFFD23F);
  static const warnWash = Color(0xFF2E2508);
  static const warnEdge = Color(0xFF6B5410);

  static const blue = Color(0xFF4CC9F0);
  static const orange = Color(0xFFFF9F43);
  static const violet = Color(0xFFC084FC);

  /// Text on lime.
  static const ink = Color(0xFF0A0B09);

  static const glow = LinearGradient(
    begin: Alignment(-0.8, -0.6),
    end: Alignment(0.8, 0.6),
    colors: [Color(0xFFE4FF6A), Color(0xFFB6F02A), Color(0xFF5EE4A0)],
    stops: [0, 0.45, 1],
  );

  /// Macro colours: protein, carbs, fat.
  static const protein = blue;
  static const carbs = orange;
  static const fat = violet;

  static const rCard = 24.0;
  static const rRow = 18.0;
  static const rSheet = 30.0;

  /// Serif italic accent used for one word in titles.
  /// Instrument Serif has no Arabic letters; Arabic falls back to the bold
  /// sans in lime.
  static TextStyle accent(double size) => TextStyle(
    fontFamily: 'InstrumentSerif',
    fontFamilyFallback: const ['IBMPlexSansArabic'],
    fontSize: size * 1.14,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: brand,
    height: 1,
  );

  static ThemeData theme(Locale locale) {
    // Urbanist has no Arabic glyphs; Arabic falls back to IBM Plex Sans Arabic.
    final family = locale.languageCode == 'ar' ? 'IBMPlexSansArabic' : 'Urbanist';
    // Material's type scale has its own letter spacing and line heights; the
    // prototype has no letter spacing and one line height, so only size,
    // weight and colour are kept from it.
    TextStyle? flat(TextStyle? s) => s == null
        ? null
        : TextStyle(
            fontSize: s.fontSize,
            fontWeight: s.fontWeight,
            color: s.color,
            textBaseline: s.textBaseline,
            letterSpacing: 0,
            // The prototype's device frame: line-height 1.45 for everything.
            height: 1.45,
          );
    // MaterialApp merges this geometry back under the text theme, so it is
    // flattened too, for every script.
    final g = Typography.englishLike2021;
    final geometry = TextTheme(
      displayLarge: flat(g.displayLarge),
      displayMedium: flat(g.displayMedium),
      displaySmall: flat(g.displaySmall),
      headlineLarge: flat(g.headlineLarge),
      headlineMedium: flat(g.headlineMedium),
      headlineSmall: flat(g.headlineSmall),
      titleLarge: flat(g.titleLarge),
      titleMedium: flat(g.titleMedium),
      titleSmall: flat(g.titleSmall),
      bodyLarge: flat(g.bodyLarge),
      bodyMedium: flat(g.bodyMedium),
      bodySmall: flat(g.bodySmall),
      labelLarge: flat(g.labelLarge),
      labelMedium: flat(g.labelMedium),
      labelSmall: flat(g.labelSmall),
    );
    final m = ThemeData(brightness: Brightness.dark).textTheme;
    final base = TextTheme(
      displayLarge: flat(m.displayLarge),
      displayMedium: flat(m.displayMedium),
      displaySmall: flat(m.displaySmall),
      headlineLarge: flat(m.headlineLarge),
      headlineMedium: flat(m.headlineMedium),
      headlineSmall: flat(m.headlineSmall),
      titleLarge: flat(m.titleLarge),
      titleMedium: flat(m.titleMedium),
      titleSmall: flat(m.titleSmall),
      bodyLarge: flat(m.bodyLarge),
      bodyMedium: flat(m.bodyMedium),
      bodySmall: flat(m.bodySmall),
      labelLarge: flat(m.labelLarge),
      labelMedium: flat(m.labelMedium),
      labelSmall: flat(m.labelSmall),
    ).apply(fontFamily: family, fontFamilyFallback: const ['IBMPlexSansArabic', 'Urbanist']);
    final text = base
        .apply(bodyColor: t1, displayColor: t1)
        .copyWith(
          headlineMedium: base.headlineMedium?.copyWith(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: t1,
          ),
          titleLarge: base.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: t1),
          titleMedium: base.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: t1),
          bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, color: t2),
          bodySmall: base.bodySmall?.copyWith(fontSize: 12.5, color: t3),
          labelSmall: base.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: brandInk,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      typography: Typography.material2021(englishLike: geometry, dense: geometry, tall: geometry),
      fontFamily: family,
      fontFamilyFallback: const ['IBMPlexSansArabic', 'Urbanist'],
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: brand,
        onPrimary: ink,
        secondary: ok,
        surface: card,
        onSurface: t1,
        surfaceContainerHighest: card2,
        outline: line2,
        outlineVariant: line,
        error: warn,
      ),
      textTheme: text,
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rCard)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card2,
        hintStyle: const TextStyle(color: t3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: Colors.transparent,
        side: const BorderSide(color: line, width: 1.5),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(fontFamily: family, color: t2, fontWeight: FontWeight.w600),
        secondaryLabelStyle: TextStyle(fontFamily: family, color: brand, fontWeight: FontWeight.w600),
        showCheckmark: false,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: VoltPageTransitions(),
          TargetPlatform.iOS: VoltPageTransitions(),
          TargetPlatform.linux: VoltPageTransitions(),
          TargetPlatform.macOS: VoltPageTransitions(),
          TargetPlatform.windows: VoltPageTransitions(),
        },
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(rSheet))),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: card2,
        contentTextStyle: TextStyle(color: t1),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: line,
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
