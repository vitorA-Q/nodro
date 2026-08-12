import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/ui/painters/star_battle_painter.dart';

/// Decision D11 as an executable rule.
///
/// "Colour is reinforcement, the border is the information" is easy to write
/// and easy to erode — someone adds one saturated tint to make a region pop and
/// the board quietly becomes unreadable in greyscale. These tests make that
/// erosion fail the build instead of shipping.
///
/// The core assertion is counter-intuitive on purpose: the region tints must be
/// nearly IDENTICAL in greyscale. If they differed, greyscale viewers would see
/// a pattern that encodes nothing, and colour would have become load-bearing.
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
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  test('region tints are indistinguishable in greyscale', () {
    final values =
        StarBattlePainter.regionTints.map(luminance).toList()..sort();
    final spread = values.last - values.first;

    expect(spread, lessThan(0.06),
        reason: 'the region tints differ by $spread in greyscale luminance. '
            'They must stay nearly identical: if a tint were visibly darker, a '
            'greyscale or colour-blind viewer would read a pattern into it, '
            'and colour would have become load-bearing instead of the border.');
  });

  test('the region border is the highest-contrast element on the board', () {
    for (final tint in StarBattlePainter.regionTints) {
      expect(contrast(StarBattlePainter.ink, tint), greaterThan(10.0),
          reason: 'the region border must stand out sharply against every '
              'tint — it is the only thing carrying region identity');
    }
    expect(contrast(StarBattlePainter.ink, StarBattlePainter.paper),
        greaterThan(10.0));
  });

  test('star and cross are separable by weight, not only by shape', () {
    // The star is drawn in ink and filled; the cross in grey and thin. A player
    // glancing at the board should tell them apart from the tone alone, before
    // resolving either shape.
    final starOnPaper = contrast(StarBattlePainter.ink, StarBattlePainter.paper);
    final crossOnPaper =
        contrast(StarBattlePainter.markGrey, StarBattlePainter.paper);

    expect(crossOnPaper, greaterThan(2.0),
        reason: 'the cross must still be clearly visible');
    expect(starOnPaper, greaterThan(crossOnPaper * 2.5),
        reason: 'the star must read as substantially heavier than the cross '
            '($starOnPaper vs $crossOnPaper), so the two never blur together '
            'at a glance or on a small screen');
  });

  test('the solved colour is distinguishable from the normal ink in greyscale',
      () {
    // Victory feedback must not rely on green alone.
    final delta = (luminance(StarBattlePainter.success) -
            luminance(StarBattlePainter.ink))
        .abs();
    expect(delta, greaterThan(0.02),
        reason: 'the solved state changes ink to green; in greyscale that '
            'difference must still be perceptible, otherwise a colour-blind '
            'player gets no victory signal from the board itself');
  });
}
