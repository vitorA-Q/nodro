import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import '../../tool/icon_spec.dart';

/// The icon, checked the way the puzzles are: by property, on the real output.
///
/// An icon is the one asset that cannot be reviewed at the size it is used.
/// Every failure the competitive survey turned up — a mark too small on a big
/// field, a ground that collapses into its surroundings, a safe zone violated,
/// a stroke that dissolves — is invisible on a 512px canvas in an editor and
/// obvious in a launcher. So these tests read the shipped bytes back and
/// measure them.
void main() {
  Raster load(String path) {
    final file = File(path);
    expect(file.existsSync(), isTrue, reason: '$path is missing — run '
        'dart run tool/generate_icons.dart');
    return decodePng(file.readAsBytesSync());
  }

  group('the files exist and are what they claim to be', () {
    const expected = <String, int>{
      'web/icons/Icon-192.png': 192,
      'web/icons/Icon-512.png': 512,
      'web/icons/Icon-maskable-192.png': 192,
      'web/icons/Icon-maskable-512.png': 512,
      'web/icons/apple-touch-icon.png': 180,
      'web/favicon.png': 32,
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
      'store/play-listing-icon-512.png': 512,
    };

    for (final entry in expected.entries) {
      test('${entry.key} is ${entry.value}px square', () {
        final raster = load(entry.key);
        expect(raster.width, entry.value);
        expect(raster.height, entry.value);
      });
    }
  });

  test('every shipped PNG still matches the spec that generated it', () {
    // The point of this one is that there is no hand-editing step. If someone
    // opens an icon in an image editor and nudges it, the geometry in
    // icon_spec.dart stops describing what ships, and every other test in this
    // file starts measuring a drawing nobody can regenerate.
    const cases = <String, (IconComposition, int)>{
      'web/icons/Icon-512.png': (anyComposition, 512),
      'web/icons/Icon-192.png': (anyComposition, 192),
      'web/icons/Icon-maskable-512.png': (maskableComposition, 512),
      'web/icons/Icon-maskable-192.png': (maskableComposition, 192),
      'web/favicon.png': (faviconComposition, 32),
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png':
          (anyComposition, 192),
    };

    for (final entry in cases.entries) {
      final shipped = load(entry.key);
      final fresh = renderComposition(entry.value.$1, entry.value.$2);
      expect(shipped.pixels, orderedEquals(fresh.pixels),
          reason: '${entry.key} is not what tool/icon_spec.dart draws');
    }
  });

  group('safe zones', () {
    test('PROP-ICON-1 no maskable star vertex leaves the safe circle', () {
      // A maskable icon guarantees only the inner 80% — a circle of radius 40%
      // of the width. Anything outside it can be cut by a launcher, and a star
      // with a point sliced off stops being a star.
      const size = 512.0;
      const safeRadius = 0.4 * size;
      final vertices = starPolygon(
        cx: maskableComposition.starCx * size,
        cy: maskableComposition.starCy * size,
        r: maskableComposition.starR * size,
      );

      for (var i = 0; i < vertices.length; i += 2) {
        final dx = vertices[i] - size / 2;
        final dy = vertices[i + 1] - size / 2;
        final distance = math.sqrt(dx * dx + dy * dy);
        expect(distance, lessThan(safeRadius),
            reason: 'vertex ${i ~/ 2} sits ${distance.toStringAsFixed(1)}px '
                'from centre, past the $safeRadius safe radius');
      }
    });

    test('PROP-ICON-2 the adaptive star fits the 66dp guaranteed circle', () {
      // Android reserves 18dp on every side for masking and parallax, leaving a
      // 66dp circle that is always visible. The star's BOUNDING circle has to
      // fit, not just its centre — an offset star is the usual way this breaks.
      const canvas = 108.0;
      final cx = adaptiveForeground.starCx * canvas;
      final cy = adaptiveForeground.starCy * canvas;
      final r = adaptiveForeground.starR * canvas;
      final offset = math.sqrt(math.pow(cx - 54, 2) + math.pow(cy - 54, 2));

      expect(offset + r, lessThanOrEqualTo(33.0),
          reason: 'the star reaches ${(offset + r).toStringAsFixed(2)}dp from '
              'centre; the guaranteed circle is 33dp');
      expect(r * 2, inInclusiveRange(48.0, 66.0),
          reason: 'Android asks for a logo between 48dp and 66dp across');
    });

    test('PROP-ICON-3 the adaptive seam never touches the adaptive star', () {
      // The two layers slide against each other for parallax, so a gap that is
      // only just big enough at rest closes in motion.
      const canvas = 108.0;
      final star = starPolygon(
        cx: adaptiveForeground.starCx * canvas,
        cy: adaptiveForeground.starCy * canvas,
        r: adaptiveForeground.starR * canvas,
      );
      final half = adaptiveBackgroundSeam.stroke * canvas / 2;
      final seamRight = adaptiveBackgroundSeam.cornerX * canvas + half;
      final seamTop = adaptiveBackgroundSeam.cornerY * canvas - half;

      var closest = double.infinity;
      for (var i = 0; i < star.length; i += 2) {
        closest = math.min(closest,
            _distanceToSeam(star[i], star[i + 1], seamRight, seamTop));
      }
      expect(closest, greaterThan(5.0),
          reason: 'only ${closest.toStringAsFixed(2)}dp of clearance; a '
              'parallax shift would close that');
    });

    test('PROP-ICON-4 the Play tile keeps its star inside the padding box', () {
      // Play rounds the corners by 30% and draws its own shadow. Elements are
      // meant to stay within 15–18% of the edges or the mask eats them.
      const size = 512.0;
      const padding = 0.15 * size;
      final vertices = starPolygon(
        cx: anyComposition.starCx * size,
        cy: anyComposition.starCy * size,
        r: anyComposition.starR * size,
      );
      for (var i = 0; i < vertices.length; i += 2) {
        expect(vertices[i], inInclusiveRange(padding, size - padding));
        expect(vertices[i + 1], inInclusiveRange(padding, size - padding));
      }
    });
  });

  group('legibility', () {
    test('PROP-ICON-5 maskable icons are fully opaque', () {
      // Required by the maskable spec, and a transparent maskable icon shows
      // whatever the launcher paints behind it, which is not a design.
      for (final path in <String>[
        'web/icons/Icon-maskable-192.png',
        'web/icons/Icon-maskable-512.png',
      ]) {
        final raster = load(path);
        for (var i = 3; i < raster.pixels.length; i += 4) {
          expect(raster.pixels[i], 255, reason: '$path has a see-through pixel');
        }
      }
    });

    test('PROP-ICON-6 the mark carries enough ink to be seen', () {
      // The measured failure in this category is a tiny element on a big flat
      // field: one competitor is 94% navy with a star covering about 1% of the
      // tile, and it reads as a blank square in search results.
      for (final path in <String>[
        'web/icons/Icon-512.png',
        'web/icons/Icon-maskable-512.png',
        'web/favicon.png',
      ]) {
        final coverage = _inkCoverage(load(path));
        expect(coverage, greaterThan(0.10),
            reason: '$path is only ${(coverage * 100).toStringAsFixed(1)}% '
                'ink — that reads as an empty tile at thumbnail size');
      }
    });

    test('PROP-ICON-7 ground and mark never collapse into each other', () {
      // The other measured failure: near-black on near-black, invisible in a
      // search result. Checked as real contrast between the lightest and
      // darkest pixels actually present in the file.
      for (final path in <String>[
        'web/icons/Icon-512.png',
        'web/icons/Icon-maskable-512.png',
        'web/favicon.png',
        'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
      ]) {
        expect(_internalContrast(load(path)), greaterThan(7.0),
            reason: '$path has too little internal contrast to read small');
      }
    });

    test('PROP-ICON-8 paper survives a dark browser tab strip', () {
      // This is the trade the whole palette turns on. Paper against Chrome's
      // dark tab strip is fine; an ink ground would have been 1.10:1, which is
      // invisible — and the browser tab is a primary surface for a product
      // that launches on the web before it launches on a store.
      const chromeDarkTabStrip = 0xFF202124;
      expect(_contrast(kPaper, chromeDarkTabStrip), greaterThan(10.0));
      expect(_contrast(kInk, chromeDarkTabStrip), lessThan(2.0),
          reason: 'stated so the reason paper won is recorded, not remembered');
      expect(_contrast(kInk, kPaper), greaterThan(15.0));
    });

    test('PROP-ICON-9 amber is never strong enough to be the mark on paper',
        () {
      // Written down as a test because "use the accent colour" is the most
      // natural-sounding wrong idea available here.
      expect(_contrast(kAccentOnInkOnly, kPaper), lessThan(3.0));
      expect(_contrast(kAccentOnInkOnly, kInk), greaterThan(7.0));
    });

    test('PROP-ICON-10 the 16px favicon still reads as a star', () {
      // 16px is 256 pixels in total, and this test was calibrated by measuring
      // variants rather than by guessing thresholds:
      //
      //   shipped, inner ratio 0.50    29.7% ink   legs split
      //   classic, inner ratio 0.382   23.4% ink   legs split
      //   thin,    inner ratio 0.30    15.6% ink   legs split
      //   same star at 60% size        11.7% ink   legs split
      //   same star at 42% size         5.5% ink   legs split
      //
      // Worth stating plainly: the structural checks below — widest row above
      // centre, ink splitting into two legs beneath it — pass for EVERY one of
      // those, including the 3px speck. They are necessary, not sufficient, and
      // on their own they would be a test that cannot fail.
      //
      // Ink coverage is the measure that actually discriminates. The band
      // rejects the conventional star proportion and every undersized version,
      // which is the whole design decision this file exists to protect.
      final raster = renderComposition(favicon16Composition, 16);

      var widestRow = -1;
      var widest = -1;
      final runsPerRow = <int>[];
      for (var y = 0; y < 16; y++) {
        var ink = 0;
        var runs = 0;
        var wasInk = false;
        for (var x = 0; x < 16; x++) {
          final isInk = _isInk(raster.pixelAt(x, y));
          if (isInk) {
            ink++;
            if (!wasInk) {
              runs++;
            }
          }
          wasInk = isInk;
        }
        runsPerRow.add(runs);
        if (ink > widest) {
          widest = ink;
          widestRow = y;
        }
      }

      expect(widestRow, lessThan(8),
          reason: 'the widest row should be the arms, above the middle');
      expect(runsPerRow.sublist(widestRow + 1).any((runs) => runs >= 2), isTrue,
          reason: 'no row below the arms splits into two legs, so the notch '
              'between them has closed and the star has become a blob');
      expect(_inkCoverage(raster), inInclusiveRange(0.25, 0.42),
          reason: 'below 0.25 the star is either too small or too thin to '
              'hold five points at this size; above 0.42 it has swollen into '
              'a pentagon');
    });
  });

  group('wiring', () {
    test('PROP-ICON-11 no icon declares both purposes at once', () {
      // Combining the two purposes in one file makes the icon render about 20%
      // smaller than its neighbours in every non-masking context.
      //
      // Parsed rather than grepped: the first version of this test searched the
      // raw text and failed on the comment that explains the rule.
      final icons = _manifestIcons();
      for (final icon in icons) {
        final purpose = (icon['purpose'] as String?)?.split(' ') ?? const [];
        expect(purpose.length, lessThan(2),
            reason: '${icon['src']} declares ${icon['purpose']}');
      }
      expect(icons.where((i) => i['purpose'] == 'maskable'), isNotEmpty);
      expect(icons.where((i) => i['purpose'] == null), isNotEmpty);
    });

    test('PROP-ICON-12 the manifest points at files that exist', () {
      for (final icon in _manifestIcons()) {
        final src = icon['src'] as String;
        expect(File('web/$src').existsSync(), isTrue,
            reason: 'the manifest lists web/$src, which is not there');
      }
    });

    test('PROP-ICON-13 the adaptive icon references drawables that exist', () {
      const dir = 'android/app/src/main/res';
      final xml =
          File('$dir/mipmap-anydpi-v26/ic_launcher.xml').readAsStringSync();
      for (final match
          in RegExp(r'@drawable/(\w+)').allMatches(xml)) {
        expect(File('$dir/drawable/${match.group(1)}.xml').existsSync(), isTrue,
            reason: 'the adaptive icon names ${match.group(1)}, which is not '
                'in res/drawable');
      }
      expect(xml, contains('<monochrome'),
          reason: 'without it, themed icons on Android 13+ fall back to a '
              'shrunken copy of the full icon');
    });
  });
}

List<Map<String, dynamic>> _manifestIcons() {
  final manifest =
      jsonDecode(File('web/manifest.json').readAsStringSync()) as Map;
  return (manifest['icons'] as List).cast<Map<String, dynamic>>();
}

/// Distance from a point to the L-shaped seam, which is two rectangles: one
/// spanning the left edge to [seamRight] below [seamTop], and one running from
/// [seamTop] to the bottom edge.
double _distanceToSeam(
    double x, double y, double seamRight, double seamTop) {
  if (y >= seamTop && x <= seamRight) {
    return 0;
  }
  final dx = math.max(0.0, x - seamRight);
  final dy = math.max(0.0, seamTop - y);
  return math.sqrt(dx * dx + dy * dy);
}

bool _isInk(int argb) => _luminance(argb) < 0.25;

double _inkCoverage(Raster raster) {
  var ink = 0;
  for (var y = 0; y < raster.height; y++) {
    for (var x = 0; x < raster.width; x++) {
      if (_isInk(raster.pixelAt(x, y))) {
        ink++;
      }
    }
  }
  return ink / (raster.width * raster.height);
}

double _internalContrast(Raster raster) {
  var lightest = 0.0;
  var darkest = 1.0;
  for (var y = 0; y < raster.height; y++) {
    for (var x = 0; x < raster.width; x++) {
      final l = _luminance(raster.pixelAt(x, y));
      lightest = math.max(lightest, l);
      darkest = math.min(darkest, l);
    }
  }
  return (lightest + 0.05) / (darkest + 0.05);
}

double _contrast(int a, int b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

double _luminance(int argb) {
  double channel(int shift) {
    final v = ((argb >> shift) & 0xFF) / 255.0;
    return v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
}
