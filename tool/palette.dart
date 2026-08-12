// Derives the region palettes. Run with: dart run tool/palette.dart
//
// The constraint is unusual and cannot be satisfied by eye: ten hues that look
// strongly different in colour but are INDISTINGUISHABLE in greyscale. That
// means holding WCAG relative luminance constant while pushing saturation as
// far as it will go — so for each hue this binary-searches the HSL lightness
// that lands on the target luminance.
//
// Output goes into lib/ui/theme/nodro_theme.dart. The greyscale test in
// test/ui/accessibility_test.dart is what keeps it honest afterwards.

import 'dart:io';
import 'dart:math' as math;

/// WCAG relative luminance for 8-bit sRGB channels.
double luminance(int r, int g, int b) {
  double channel(int value) {
    final v = value / 255.0;
    return v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
}

List<int> hslToRgb(double h, double s, double l) {
  final c = (1 - (2 * l - 1).abs()) * s;
  final hp = h / 60.0;
  final x = c * (1 - ((hp % 2) - 1).abs());
  double r1 = 0;
  double g1 = 0;
  double b1 = 0;
  if (hp < 1) {
    r1 = c;
    g1 = x;
  } else if (hp < 2) {
    r1 = x;
    g1 = c;
  } else if (hp < 3) {
    g1 = c;
    b1 = x;
  } else if (hp < 4) {
    g1 = x;
    b1 = c;
  } else if (hp < 5) {
    r1 = x;
    b1 = c;
  } else {
    r1 = c;
    b1 = x;
  }
  final m = l - c / 2;
  return <int>[
    ((r1 + m) * 255).round().clamp(0, 255),
    ((g1 + m) * 255).round().clamp(0, 255),
    ((b1 + m) * 255).round().clamp(0, 255),
  ];
}

/// Finds the HSL lightness whose resulting colour hits [targetLuminance].
List<int> atLuminance(double hue, double saturation, double targetLuminance) {
  var low = 0.0;
  var high = 1.0;
  var best = hslToRgb(hue, saturation, 0.5);
  for (var i = 0; i < 60; i++) {
    final mid = (low + high) / 2;
    final rgb = hslToRgb(hue, saturation, mid);
    final lum = luminance(rgb[0], rgb[1], rgb[2]);
    best = rgb;
    if (lum < targetLuminance) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return best;
}

String hex(List<int> rgb) =>
    '0xFF${rgb[0].toRadixString(16).padLeft(2, '0').toUpperCase()}'
    '${rgb[1].toRadixString(16).padLeft(2, '0').toUpperCase()}'
    '${rgb[2].toRadixString(16).padLeft(2, '0').toUpperCase()}';

void emit(String label, double targetLuminance, double saturation) {
  stdout.writeln('// $label — target relative luminance $targetLuminance, '
      'saturation $saturation');
  final lums = <double>[];
  for (var i = 0; i < 10; i++) {
    // Hues spread unevenly on purpose: the eye separates blues and greens less
    // readily than reds and yellows, so the cool half gets wider spacing.
    const hues = <double>[8, 32, 52, 96, 152, 186, 212, 248, 284, 322];
    final rgb = atLuminance(hues[i], saturation, targetLuminance);
    lums.add(luminance(rgb[0], rgb[1], rgb[2]));
    stdout.writeln('  Color(${hex(rgb)}),  // hue ${hues[i].toInt()}');
  }
  lums.sort();
  stdout.writeln('// greyscale spread: '
      '${(lums.last - lums.first).toStringAsFixed(5)}');
  stdout.writeln('');
}

void main() {
  // Light mode: tints sit just below the paper so the board reads as ruled
  // sheets, not as blocks of colour.
  emit('LIGHT region tints', 0.72, 0.62);
  // Dark mode: same idea inverted, sitting above the ground.
  emit('DARK region tints', 0.055, 0.55);
}
