import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/ui/theme/nodro_theme.dart';

/// Decision D11 as an executable rule, in BOTH themes.
///
/// "Colour is reinforcement, the border is the information" is easy to write
/// and easy to erode — someone adds one saturated tint to make a region pop and
/// the board quietly becomes unreadable in greyscale. These tests make that
/// erosion fail the build instead of shipping.
///
/// The core assertion is counter-intuitive on purpose: the region tints must be
/// nearly IDENTICAL in greyscale, even though they are strongly coloured. If
/// they differed, a greyscale or colour-blind viewer would see a pattern that
/// encodes nothing, and colour would have become load-bearing by accident.
void main() {
  /// Relative luminance, sRGB (WCAG definition).
  double luminance(Color color) {
    double channel(double component) => component <= 0.04045
        ? component / 12.92
        : math.pow((component + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// Distance from grey, 0 for a neutral tone. Used to prove the tints really
  /// are colourful — the greyscale rule must be met by equal luminance, never
  /// by draining the colour out, which is the mistake the first palette made.
  double saturation(Color color) {
    final r = color.r;
    final g = color.g;
    final b = color.b;
    final maxC = math.max(r, math.max(g, b));
    final minC = math.min(r, math.min(g, b));
    return maxC == 0 ? 0 : (maxC - minC) / maxC;
  }

  for (final entry in <String, NodroPalette>{
    'light': NodroPalette.light,
    'dark': NodroPalette.dark,
  }.entries) {
    final name = entry.key;
    final palette = entry.value;

    group(name, () {
      test('region tints are indistinguishable in greyscale', () {
        final values = palette.regionTints.map(luminance).toList()..sort();
        final spread = values.last - values.first;

        expect(spread, lessThan(0.06),
            reason: '$name tints differ by $spread in greyscale luminance. '
                'They must stay nearly identical, or a greyscale viewer reads '
                'a pattern into something that carries no meaning.');
      });

      test('region tints are genuinely colourful, not washed out', () {
        // The ceiling here is set by physics, not by taste: at the high
        // luminance a light-mode tint needs, HSV saturation cannot go far. The
        // threshold is calibrated against the palette this replaced, whose
        // tints measured around 0.04 — roughly three times greyer.
        for (final tint in palette.regionTints) {
          expect(saturation(tint), greaterThan(0.10),
              reason: 'tint $tint is nearly grey. The greyscale rule is about '
                  'equal LUMINANCE, not low saturation — draining the colour '
                  'satisfies the letter of the rule and ruins the board.');
        }
      });

      test('the region border is the highest-contrast element', () {
        for (final tint in palette.regionTints) {
          expect(contrast(palette.ink, tint), greaterThan(4.5),
              reason: 'the border must stand out against every tint — it is '
                  'the only thing carrying region identity');
        }
        expect(contrast(palette.ink, palette.paper), greaterThan(10.0));
      });

      test('star and cross are separable by weight, not only by shape', () {
        final star = contrast(palette.ink, palette.paper);
        final cross = contrast(palette.markGrey, palette.paper);

        expect(cross, greaterThan(1.8),
            reason: 'the cross must still be clearly visible');
        expect(star, greaterThan(cross * 2.0),
            reason: 'the star must read as substantially heavier than the '
                'cross ($star vs $cross), so the two never blur at a glance');
      });

      test('conflict red is distinguishable from the ink in greyscale', () {
        // A colour-blind player must still see that something is wrong.
        final delta =
            (luminance(palette.danger) - luminance(palette.ink)).abs();
        expect(delta, greaterThan(0.02),
            reason: 'conflict marking must not depend on hue alone');
      });

      test('the solved colour reads differently from the ink in greyscale', () {
        final delta =
            (luminance(palette.success) - luminance(palette.ink)).abs();
        expect(delta, greaterThan(0.02),
            reason: 'victory feedback must not depend on green alone');
      });

      test('the neighbour wash is visible but stays subtle', () {
        // It teaches the no-touching rule; it must never shout like an error.
        expect(palette.neighbourWash.a, greaterThan(0.06),
            reason: 'too faint to notice teaches nothing');
        expect(palette.neighbourWash.a, lessThan(0.30),
            reason: 'too strong and it reads as an error rather than as '
                '"this square is spoken for"');
      });
    });
  }
}
