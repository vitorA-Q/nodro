import 'package:flutter/material.dart';

/// The visual system, in one place.
///
/// ## The rule that shapes everything
///
/// **The border carries the information. Colour only reinforces it.** The ten
/// region tints below are strongly saturated and obviously different to a
/// colour-seeing eye, yet they are near-identical in greyscale luminance —
/// derived by `tool/palette.dart`, which holds WCAG relative luminance constant
/// per hue and pushes saturation as far as that constraint allows. Measured
/// spread: 0.0099 light, 0.0010 dark, against a 0.06 ceiling enforced by
/// `test/ui/accessibility_test.dart`.
///
/// The first version of this palette satisfied the greyscale rule by draining
/// saturation. That was a mistake — it is luminance that has to be equal, not
/// intensity, and the board looked washed out for no reason.
///
/// ## Red is reserved
///
/// [danger] appears **only** on a rule conflict, nowhere else in the app. That
/// exclusivity is what lets it be noticed instantly without ever competing for
/// attention.
class NodroPalette {
  const NodroPalette({
    required this.paper,
    required this.ink,
    required this.inkSoft,
    required this.hairline,
    required this.markGrey,
    required this.success,
    required this.danger,
    required this.neighbourWash,
    required this.regionTints,
  });

  /// The board ground. Warm rather than pure white: a logic puzzle should read
  /// as a well-printed sheet of paper, not as a lit screen.
  final Color paper;

  /// Region borders, stars, primary text.
  final Color ink;

  /// Secondary text. The board is the hero; everything else recedes.
  final Color inkSoft;

  /// Cell edges inside a region.
  final Color hairline;

  /// The cross mark. Deliberately much lighter than [ink] so a star and a cross
  /// differ in weight, not only in shape.
  final Color markGrey;

  final Color success;

  /// Conflict only. Never decorative.
  final Color danger;

  /// The wash laid over the eight cells around a placed star.
  ///
  /// This is the single most valuable element on the board: it teaches the
  /// no-touching rule without a word of text. It reads as texture — "occupied"
  /// — not as an error, which is why it is a neutral shade and not [danger].
  final Color neighbourWash;

  final List<Color> regionTints;

  static const NodroPalette light = NodroPalette(
    paper: Color(0xFFFAF7F1),
    ink: Color(0xFF141821),
    inkSoft: Color(0xFF6B7180),
    hairline: Color(0x33141821),
    markGrey: Color(0xFF9AA1AE),
    success: Color(0xFF15795A),
    danger: Color(0xFFC2352B),
    neighbourWash: Color(0x1A141821),
    regionTints: <Color>[
      Color(0xFFF4D6D2),
      Color(0xFFF0DAC0),
      Color(0xFFE8DF9E),
      Color(0xFFBFE9A3),
      Color(0xFFA8EACB),
      Color(0xFFB0E6ED),
      Color(0xFFCCDEF3),
      Color(0xFFDDDAF6),
      Color(0xFFECD4F5),
      Color(0xFFF5D4E9),
    ],
  );

  static const NodroPalette dark = NodroPalette(
    paper: Color(0xFF12151B),
    ink: Color(0xFFE8ECF3),
    inkSoft: Color(0xFF8A93A3),
    hairline: Color(0x33E8ECF3),
    markGrey: Color(0xFF6E7787),
    success: Color(0xFF4FD1A0),
    danger: Color(0xFFFF6B5E),
    neighbourWash: Color(0x1FE8ECF3),
    regionTints: <Color>[
      Color(0xFF722C21),
      Color(0xFF5A3C1A),
      Color(0xFF4A4315),
      Color(0xFF2B4A16),
      Color(0xFF164B32),
      Color(0xFF17494F),
      Color(0xFF20436D),
      Color(0xFF3D2EA0),
      Color(0xFF65247C),
      Color(0xFF742255),
    ],
  );

  static NodroPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Atkinson Hyperlegible, bundled locally — no network at runtime (R3).
///
/// Chosen because its design thesis is this project's thesis: it was drawn by
/// the Braille Institute so that similar glyphs cannot be confused with one
/// another. Licence: SIL Open Font License 1.1, Copyright 2020 Braille
/// Institute of America, Inc. The licence text ships at `assets/fonts/OFL.txt`.
const String nodroFontFamily = 'AtkinsonHyperlegible';

ThemeData buildNodroTheme(Brightness brightness) {
  final palette =
      brightness == Brightness.dark ? NodroPalette.dark : NodroPalette.light;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: nodroFontFamily,
    scaffoldBackgroundColor: palette.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.success,
      brightness: brightness,
      surface: palette.paper,
    ),
  );
}
