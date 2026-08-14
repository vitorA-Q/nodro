/// Writes every icon file the project ships, from the geometry in
/// [icon_spec.dart]. Run it after changing anything there:
///
///     dart run tool/generate_icons.dart
///
/// Nothing here is hand-edited afterwards. `test/assets/icon_test.dart` reads
/// the files back and checks the properties that actually decide whether an
/// icon works — safe zones, opacity, ink mass, contrast — so a change that
/// looks fine on a 512px canvas and breaks the favicon fails the suite instead
/// of shipping.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'icon_spec.dart';

void main() {
  _write('web/icons/Icon-192.png',
      encodePng(renderComposition(anyComposition, 192)));
  _write('web/icons/Icon-512.png',
      encodePng(renderComposition(anyComposition, 512)));
  _write('web/icons/Icon-maskable-192.png',
      encodePng(renderComposition(maskableComposition, 192)));
  _write('web/icons/Icon-maskable-512.png',
      encodePng(renderComposition(maskableComposition, 512)));

  // iOS never masks past the corners and shows the icon opaque, so the plain
  // composition is right; 180 is the largest size any current iPhone asks for.
  _write('web/icons/apple-touch-icon.png',
      encodePng(renderComposition(anyComposition, 180)));

  // The favicon drops the seam. See the note in icon_spec.dart: at these sizes
  // a stroke is mush, so the star grows and carries the tile alone.
  _write('web/favicon.png',
      encodePng(renderComposition(faviconComposition, 32)));
  _write(
      'web/favicon.ico',
      encodeIco(<Raster>[
        renderComposition(favicon16Composition, 16),
        renderComposition(faviconComposition, 32),
        renderComposition(faviconComposition, 48),
      ]));
  _writeText('web/favicon.svg', _faviconSvg());

  _write('web/og.png', encodePng(_socialCard()));

  // Android below API 26 has no adaptive icons and takes a flat bitmap.
  const densities = <String, int>{
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };
  for (final entry in densities.entries) {
    _write('android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
        encodePng(renderComposition(anyComposition, entry.value)));
  }

  // API 26 and up: two independent layers plus a monochrome silhouette for
  // themed icons. Vectors, so there is exactly one file per layer.
  _writeText('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      _adaptiveIconXml());
  _writeText('android/app/src/main/res/drawable/ic_launcher_background.xml',
      _adaptiveBackgroundXml());
  _writeText('android/app/src/main/res/drawable/ic_launcher_foreground.xml',
      _adaptiveLayerXml(kInk));
  _writeText('android/app/src/main/res/drawable/ic_launcher_monochrome.xml',
      _adaptiveLayerXml(0xFF000000));

  // The Play Console upload. Same drawing as the PWA icon, kept as its own
  // file so it is obvious which one to attach to the listing.
  _write('store/play-listing-icon-512.png',
      encodePng(renderComposition(anyComposition, 512)));

  stdout.writeln('icons written');
}

void _write(String path, Uint8List bytes) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
  stdout.writeln('  $path  ${bytes.length} bytes');
}

void _writeText(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
  stdout.writeln('  $path');
}

// ---------------------------------------------------------------------------
// Vector files
// ---------------------------------------------------------------------------

String _faviconSvg() {
  const size = 32.0;
  final path = starPathData(
    cx: faviconComposition.starCx * size,
    cy: faviconComposition.starCy * size,
    r: faviconComposition.starR * size,
  );
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">'
      '<rect width="32" height="32" fill="#FAF7F1"/>'
      '<path d="$path" fill="#141821"/>'
      '</svg>\n';
}

String _adaptiveIconXml() => '''<?xml version="1.0" encoding="utf-8"?>
<!--
  The seam lives in the BACKGROUND and the star in the FOREGROUND, never mixed.
  Launchers shift the two layers against each other for parallax, so a mark
  split across both would visibly come apart in motion.
-->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
''';

String _adaptiveBackgroundXml() => '''<?xml version="1.0" encoding="utf-8"?>
<!--
  Expected to be cropped. Under a circular mask the seam falls outside the
  visible circle entirely and the icon becomes the star on paper, which is the
  same graceful degradation the 16px favicon makes on purpose.
-->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#FAF7F1"
        android:pathData="M0,0 H108 V108 H0 Z"/>
    <path
        android:fillColor="#E7DECB"
        android:pathData="${regionPathData(adaptiveBackgroundSeam, 108)}"/>
    <path
        android:fillColor="#141821"
        android:pathData="${seamPathData(adaptiveBackgroundSeam, 108)}"/>
</vector>
''';

String _adaptiveLayerXml(int color) {
  final path = starPathData(
    cx: adaptiveForeground.starCx * 108,
    cy: adaptiveForeground.starCy * 108,
    r: adaptiveForeground.starR * 108,
  );
  final hex = '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0')
      .toUpperCase()}';
  return '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="$hex"
        android:pathData="$path"/>
</vector>
''';
}

// ---------------------------------------------------------------------------
// The social card
// ---------------------------------------------------------------------------

/// 1200x630, the size every scraper crops to.
///
/// The wordmark is drawn from geometry rather than set in a font: the card has
/// to be a PNG, this file has no text renderer, and NODRO happens to be five
/// letters that a circle, a rectangle and a diagonal can build honestly. The
/// tagline is deliberately absent — the alternative was inventing thirteen more
/// letterforms by hand, and a card with a bad alphabet is worse than one with
/// none.
Raster _socialCard() {
  final card = Raster(1200, 630, background: kPaper);

  // The icon art at large scale, seam bleeding off two edges as it does
  // everywhere else.
  const seamCornerX = 232.0;
  const seamCornerY = 472.0;
  const seamHalf = 17.0;
  card.fillRect(0, seamCornerY - seamHalf, seamCornerX + seamHalf, 630, kTint);
  card.fillRect(0, seamCornerY - seamHalf, seamCornerX + seamHalf,
      seamCornerY + seamHalf, kInk);
  card.fillRect(seamCornerX - seamHalf, seamCornerY - seamHalf,
      seamCornerX + seamHalf, 630, kInk);
  card.fillPolygon(starPolygon(cx: 250, cy: 285, r: 150), kInk);

  const capHeight = 112.0;
  const stroke = 23.0;
  const top = 229.0;
  var x = 470.0;
  for (final letter in 'NODRO'.split('')) {
    x += _drawLetter(card, letter, x, top, capHeight, stroke) + 24;
  }
  return card;
}

/// Returns the advance width of the letter it drew.
double _drawLetter(
    Raster card, String letter, double x, double y, double h, double s) {
  switch (letter) {
    case 'N':
      const width = 104.0;
      card.fillRect(x, y, x + s, y + h, kInk);
      card.fillRect(x + width - s, y, x + width, y + h, kInk);
      card.fillPolygon(<double>[
        x, y,
        x + s, y,
        x + width, y + h,
        x + width - s, y + h,
      ], kInk);
      return width;
    case 'O':
      const width = 116.0;
      _ring(card, x, y, width, h, s);
      return width;
    case 'D':
      const width = 110.0;
      _bowl(card, x, y, width, h, s);
      return width;
    case 'R':
      const width = 108.0;
      const bowlHeight = 0.58;
      _bowl(card, x, y, width * 0.94, h * bowlHeight, s);
      card.fillRect(x, y, x + s, y + h, kInk);
      card.fillPolygon(<double>[
        x + s * 0.8, y + h * bowlHeight - s * 1.25,
        x + s * 2.1, y + h * bowlHeight - s * 1.25,
        x + width, y + h,
        x + width - s * 1.1, y + h,
      ], kInk);
      return width;
    default:
      throw ArgumentError('the wordmark alphabet has no glyph for $letter');
  }
}

/// An elliptical ring: the letter O.
void _ring(Raster card, double x, double y, double w, double h, double s) {
  final cx = x + w / 2;
  final cy = y + h / 2;
  final rx = w / 2;
  final ry = h / 2;
  card.fillShape(x, y, x + w, y + h, kInk, (px, py) {
    final nx = (px - cx) / rx;
    final ny = (py - cy) / ry;
    if (nx * nx + ny * ny > 1) {
      return false;
    }
    final ix = (px - cx) / (rx - s);
    final iy = (py - cy) / (ry - s);
    return ix * ix + iy * iy > 1;
  });
}

/// A flat-left, round-right ring: the letter D, and the bowl of the R.
void _bowl(Raster card, double x, double y, double w, double h, double s) {
  final ry = h / 2;
  final cy = y + ry;
  final rx = math.min(ry * 1.05, w - s * 1.4);
  final straightTo = x + w - rx;

  bool inside(double px, double py, double inset) {
    if (py < y + inset || py > y + h - inset || px < x + inset) {
      return false;
    }
    if (px <= straightTo) {
      return true;
    }
    final nx = (px - straightTo) / (rx - inset);
    final ny = (py - cy) / (ry - inset);
    return nx * nx + ny * ny <= 1;
  }

  card.fillShape(x, y, x + w, y + h, kInk,
      (px, py) => inside(px, py, 0) && !inside(px, py, s));
}
