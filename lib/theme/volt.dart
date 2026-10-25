import 'package:flutter/material.dart';

import 'transitions.dart';
import '../ui/kit/smooth.dart';

/// One set of Gymco colours. [VoltPalette.dark] is the original Volt look;
/// [VoltPalette.light] is the same system on an off-white page.
class VoltPalette {
  const VoltPalette({
    required this.brightness,
    required this.bg,
    required this.card,
    required this.card2,
    required this.sheet,
    required this.line,
    required this.line2,
    required this.t1,
    required this.t2,
    required this.t3,
    required this.t4,
    required this.brandInk,
    required this.brandWash,
    required this.brandEdge,
    required this.accent,
    required this.ok,
    required this.okWash,
    required this.warn,
    required this.warnWash,
    required this.warnEdge,
    required this.blue,
    required this.orange,
    required this.violet,
    required this.tint,
  });
  final Brightness brightness;
  final Color bg, card, card2, sheet, line, line2;
  final Color t1, t2, t3, t4;
  final Color brandInk, brandWash, brandEdge;

  /// The serif title word and other lime type: lime on dark, a deep olive
  /// on light where lime text would not read.
  final Color accent;
  final Color ok, okWash, warn, warnWash, warnEdge;
  final Color blue, orange, violet;

  /// What was "a little white" over dark surfaces: white on dark, black on light.
  final Color tint;

  static const dark = VoltPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0A0B09),
    card: Color(0xFF15171A),
    card2: Color(0xFF1F2226),
    sheet: Color(0xFF111315),
    line: Color(0xFF2A2E33),
    line2: Color(0xFF3A3F45),
    t1: Color(0xFFF5F7F0),
    t2: Color(0xFFC9CEC4),
    t3: Color(0xFF8D948A),
    t4: Color(0xFF5F665C),
    brandInk: Color(0xFFD9FF5C),
    brandWash: Color(0xFF1A230D),
    brandEdge: Color(0xFF4D6B12),
    accent: Color(0xFFC6F432),
    ok: Color(0xFF7CF0B0),
    okWash: Color(0xFF11301F),
    warn: Color(0xFFFFD23F),
    warnWash: Color(0xFF2E2508),
    warnEdge: Color(0xFF6B5410),
    blue: Color(0xFF4CC9F0),
    orange: Color(0xFFFF9F43),
    violet: Color(0xFFC084FC),
    tint: Color(0xFFFFFFFF),
  );

  static const light = VoltPalette(
    brightness: Brightness.light,
    bg: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFEEF0E8),
    sheet: Color(0xFFFFFFFF),
    line: Color(0xFFE2E5DC),
    line2: Color(0xFFCBD0C3),
    t1: Color(0xFF10120E),
    t2: Color(0xFF3B4038),
    t3: Color(0xFF6A7066),
    t4: Color(0xFF9AA095),
    brandInk: Color(0xFF4F7400),
    brandWash: Color(0xFFEAF6CC),
    brandEdge: Color(0xFFA9D64A),
    accent: Color(0xFF5F8A00),
    ok: Color(0xFF16935A),
    okWash: Color(0xFFE1F3EA),
    warn: Color(0xFFB26B00),
    warnWash: Color(0xFFFBF0D6),
    warnEdge: Color(0xFFE8C770),
    blue: Color(0xFF1C86C4),
    orange: Color(0xFFE07A1F),
    violet: Color(0xFF8B5CF6),
    tint: Color(0xFF000000),
  );
}

/// Gymco — Volt edition: electric lime, pill buttons with a lime-to-mint glow,
/// a serif italic accent in titles. Dark by default; light from Me →
/// Appearance. The app sets the palette with [use] and rebuilds everything
/// when it changes (see GymcoApp), so these read as plain colours.
abstract final class Volt {
  static VoltPalette _p = VoltPalette.dark;
  static VoltPalette get palette => _p;
  static bool get isLight => _p.brightness == Brightness.light;
  static void use(Brightness b) => _p = b == Brightness.light ? VoltPalette.light : VoltPalette.dark;

  static Color get bg => _p.bg;
  static Color get card => _p.card;
  static Color get card2 => _p.card2;
  static Color get sheet => _p.sheet;
  static Color get line => _p.line;
  static Color get line2 => _p.line2;

  /// The card outline: none on dark, where cards stand off the page by
  /// colour; a hairline on light, where cards and page are both white.
  static Border? get edge => isLight ? Border.all(color: _p.line) : null;

  /// A feature card's ground: the card colour on dark; on light a pale grey
  /// with no border, for the cards that lead a screen.
  static Color get soft => isLight ? const Color(0xFFF2F3EE) : _p.card;

  /// Text field fill: the card colour on dark, a soft grey on white.
  static Color get field => isLight ? _p.card2 : _p.card;

  static Color get t1 => _p.t1;
  static Color get t2 => _p.t2;
  static Color get t3 => _p.t3;
  static Color get t4 => _p.t4;

  /// The lime fill: buttons, rings, selected chips. The same in both modes,
  /// always with [ink] on it.
  static const brand = Color(0xFFC6F432);
  static Color get brandInk => _p.brandInk;
  static Color get brandWash => _p.brandWash;
  static Color get brandEdge => _p.brandEdge;

  /// Lime type and icons on the page (not on a lime fill).
  static Color get accentInk => _p.accent;

  /// Lime lines on the page: outlines, rings, chart strokes, bars. The fill
  /// itself on dark; a deeper green that holds up on white in light.
  static Color get lime => isLight ? const Color(0xFF7DB800) : brand;

  static Color get ok => _p.ok;
  static Color get okWash => _p.okWash;
  static Color get warn => _p.warn;
  static Color get warnWash => _p.warnWash;
  static Color get warnEdge => _p.warnEdge;

  static Color get blue => _p.blue;
  static Color get orange => _p.orange;
  static Color get violet => _p.violet;
  static Color get tint => _p.tint;

  /// Text on lime.
  static const ink = Color(0xFF0A0B09);

  static const glow = LinearGradient(
    begin: Alignment(-0.8, -0.6),
    end: Alignment(0.8, 0.6),
    colors: [Color(0xFFE4FF6A), Color(0xFFB6F02A), Color(0xFF5EE4A0)],
    stops: [0, 0.45, 1],
  );

  /// Macro colours: protein, carbs, fat.
  static Color get protein => blue;
  static Color get carbs => orange;
  static Color get fat => violet;

  static const rCard = 18.0;
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
    color: accentInk,
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
    final m = ThemeData(brightness: _p.brightness).textTheme;
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
            color: accentInk,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      typography: Typography.material2021(englishLike: geometry, dense: geometry, tall: geometry),
      fontFamily: family,
      fontFamilyFallback: const ['IBMPlexSansArabic', 'Urbanist'],
      brightness: _p.brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: brand, brightness: _p.brightness).copyWith(
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
        shape: SmoothBorder(borderRadius: BorderRadius.circular(rCard)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card2,
        hintStyle: TextStyle(color: t3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: SmoothInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: SmoothInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: Colors.transparent,
        side: BorderSide(color: line, width: 1.5),
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheet,
        shape: SmoothBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(rSheet))),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card2,
        contentTextStyle: TextStyle(color: t1),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: line,
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
