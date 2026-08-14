/// The icon, defined once.
///
/// Every icon file this project ships — the Play listing tile, the two PWA
/// families, the Android adaptive layers, the favicon and the social card — is
/// rendered from the geometry in this file. There is no drawing tool in the
/// loop and no hand-edited PNG anywhere in the repository, so the assets cannot
/// drift apart from each other or from the tests that check them.
///
/// ## The design, and why it is this and not something else
///
/// A survey of 306 logic-puzzle icons on Google Play (measured, not guessed)
/// found the category is 36% light and 81% cluttered — but only **4%** is both
/// light AND calm. That empty quadrant is where a premium, cerebral puzzle
/// belongs, and warm paper (#FAF7F1) is unoccupied in a field whose largest
/// chromatic bloc is blue and cyan at 19% combined.
///
/// The mark is ONE ink star plus ONE region seam. A bare star is a bad app
/// symbol — it is a generic ratings glyph, and the Play Store renders literal
/// rating stars beside your icon on the same screen. The seam is the escape:
/// it says the star lives inside an irregular region, which is the actual
/// mechanic of Star Battle and the thing no other star means. The four
/// competing Star Battle apps draw a full-bleed multicolour region grid at
/// ~35% edge density; that reads as clutter at thumbnail size and as a clone
/// at any size, so this icon states the region with a single stroke instead.
///
/// The star is deliberately FAT: inner radius exactly half the outer, against
/// the conventional 0.38–0.42. Two reasons. It reads as a printed typographic
/// glyph rather than a UI rating star, and — measured by downsampling — it is
/// the only proportion whose five points stay distinguishable at 16 pixels.
///
/// ## Detail is shed as the canvas shrinks, on purpose
///
/// One drawing cannot serve 512px and 16px. At 16px a 16-pixel canvas holds
/// 256 pixels in total and NOTHING linear survives: a 30px stroke on a 512
/// canvas becomes 0.9px and turns to grey mush. So the seam exists at 512, at
/// 192 and on the Android background, and the favicon drops it entirely and
/// grows the star to carry the tile alone. Measured stroke survival:
/// >=4% of canvas width survives 48px, >=6% survives 32px, nothing survives 16.
///
/// ## The one weakness, stated plainly
///
/// Paper against a pure white store background is 1.07:1 — the tile edge
/// dissolves. That is real. It is also the lesser evil: the mark itself sits
/// at 16.6:1 so it stays perfectly legible, Play draws its own drop shadow
/// which restores the edge where it matters most, and the alternative — an ink
/// ground — measures **1.10:1 against Chrome's dark tab strip**, which would
/// make the favicon invisible on a primary surface for a web-first product.
/// Paper sits at 15.06:1 there. Given the launch order, paper wins.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

// ---------------------------------------------------------------------------
// Palette
// ---------------------------------------------------------------------------

/// Warm paper. The ground of every icon, and the brand's whole position.
const int kPaper = 0xFFFAF7F1;

/// Ink. The star and the seam. 16.61:1 against paper.
const int kInk = 0xFF141821;

/// The region tint. 1.25:1 against paper — a whisper, not a block. Anything
/// lighter disappears under the Play Store's thumbnail compression; anything
/// heavier turns the icon into the two-tone clutter the category is full of.
const int kTint = 0xFFE7DECB;

/// Amber is FORBIDDEN on the paper ground: measured 2.02:1, far too weak to
/// carry a mark. It only works on ink (8.24:1). Declared here so the rule
/// travels with the palette rather than living in someone's memory.
const int kAccentOnInkOnly = 0xFFE8A33D;

// ---------------------------------------------------------------------------
// Geometry
// ---------------------------------------------------------------------------

/// The star's inner/outer radius ratio.
///
/// NOT the conventional 0.382. See the library doc: the fat proportion is both
/// the differentiator and the only version that survives 16px.
const double kInnerRatio = 0.50;

/// A five-pointed star as a flat list of x,y pairs, first point straight up.
///
/// Ten vertices alternating outer and inner radius. The overall shape is
/// 1.902r wide and 1.809r tall, so the bounding box is NOT square — anything
/// that centres the star optically has to account for that.
List<double> starPolygon({
  required double cx,
  required double cy,
  required double r,
  double innerRatio = kInnerRatio,
}) {
  final points = <double>[];
  for (var i = 0; i < 10; i++) {
    final radius = i.isEven ? r : r * innerRatio;
    final angle = (-90 + i * 36) * math.pi / 180.0;
    points.add(cx + radius * math.cos(angle));
    points.add(cy + radius * math.sin(angle));
  }
  return points;
}

/// A region boundary: an L that enters from the left edge, turns, and leaves
/// through the bottom edge.
///
/// It bleeds off two edges deliberately. A seam that stopped inside the tile
/// would read as a decorative tick; one that runs off the edges reads as part
/// of a larger board that continues beyond the icon, which is what a region
/// boundary actually is.
class SeamSpec {
  const SeamSpec({
    required this.cornerX,
    required this.cornerY,
    required this.stroke,
  });

  /// All values are fractions of the canvas width, so one spec renders at
  /// every size without a second set of numbers to keep in sync.
  final double cornerX;
  final double cornerY;
  final double stroke;
}

/// One complete composition, in canvas fractions.
class IconComposition {
  const IconComposition({
    required this.starCx,
    required this.starCy,
    required this.starR,
    this.seam,
  });

  final double starCx;
  final double starCy;
  final double starR;

  /// Null for the favicon and for the Android foreground layer, which carry
  /// the star alone.
  final SeamSpec? seam;
}

/// The Play listing tile, the PWA `purpose:"any"` icons, and apple-touch.
///
/// Star bounding diameter is 58.6% of the canvas, which sits inside the 15–18%
/// internal padding Play expects and clear of the 30% corner radius Play
/// applies for itself. Do NOT pre-round the corners or bake in a shadow here:
/// Play adds both, and doubling them looks amateurish.
/// The star's horizontal placement is not a taste decision. A star is 1.902r
/// wide, so at r=150 on a 512 canvas its centre can only sit between x=220 and
/// x=292 without breaking out of Play's 15% padding box. It sits at the right
/// end of that window so the region has room to be a REGION rather than a
/// corner sticker — an earlier, smaller block read as a photo-corner and said
/// nothing about the puzzle.
const IconComposition anyComposition = IconComposition(
  starCx: 288 / 512,
  starCy: 228 / 512,
  starR: 150 / 512,
  seam: SeamSpec(cornerX: 222 / 512, cornerY: 400 / 512, stroke: 32 / 512),
);

/// The PWA `purpose:"maskable"` icons.
///
/// Same drawing, bigger star, because the safe zone is different: maskable
/// guarantees only the inner 80% (a circle of radius 40% of the width), and an
/// icon drawn for the Android safe zone instead would render about 20% too
/// small next to its neighbours. Every star vertex here is inside r=205 on a
/// 512 canvas, which `test/assets/icon_test.dart` checks rather than trusts.
const IconComposition maskableComposition = IconComposition(
  starCx: 276 / 512,
  starCy: 244 / 512,
  starR: 178 / 512,
  seam: SeamSpec(cornerX: 210 / 512, cornerY: 426 / 512, stroke: 36 / 512),
);

/// The Android adaptive FOREGROUND layer, on the 108dp canvas.
///
/// The star alone, 53dp across, and pushed up and right off centre. The seam is
/// deliberately NOT here: launchers shift the two layers independently for
/// parallax and pulse, so any composition whose meaning depends on the layers
/// staying in register will visibly break.
///
/// The offset is what makes the icon work on a Pixel. A centred 108dp
/// composition puts the seam in a corner that a circular mask cuts away
/// entirely, leaving a bare star on the most common launcher shape there is.
/// Moving the star up and right frees the lower-left INSIDE the circle for the
/// region to live in. The offset is bounded: the star's bounding circle must
/// stay within the 66dp guaranteed-safe circle, which at r=26.5dp allows a
/// centre displacement of at most 9dp. This one uses 8.49dp, and
/// `test/assets/icon_test.dart` re-derives the bound rather than trusting it.
///
/// The star is 48dp — the small end of the platform's 48–66dp band, chosen
/// rather than accepted. A bigger star fills the 72dp viewport so completely
/// that the seam has nowhere to be except a corner the circle cuts off, and a
/// rendered check showed exactly that: a black nub at the edge that read as a
/// blemish rather than a boundary. Here the star does not have to carry the
/// icon alone, so trading 5dp of star for a legible region is the better deal.
const IconComposition adaptiveForeground = IconComposition(
  starCx: 60 / 108,
  starCy: 48 / 108,
  starR: 24 / 108,
);

/// The Android adaptive BACKGROUND layer, on the 108dp canvas.
///
/// Paper, tint and seam. The outer 18dp on each side is cropped away by every
/// launcher, so the corner sits well inside the 72dp viewport — and inside the
/// inscribed circle a round mask leaves, which is the whole reason the star
/// above is off centre.
const SeamSpec adaptiveBackgroundSeam =
    SeamSpec(cornerX: 38 / 108, cornerY: 78 / 108, stroke: 7 / 108);

/// The favicon at 32px and 48px: star only, 72.7% of the canvas.
const IconComposition faviconComposition = IconComposition(
  starCx: 0.5,
  starCy: 0.4824,
  starR: 186 / 512,
);

/// The favicon at 16px, drawn at native size rather than downscaled.
///
/// 256 pixels in total. The star grows to 12.9px tall and 13.6px wide because
/// anything smaller measured as mush, and it sits fractionally above true
/// centre because a star's visual mass is below its point.
const IconComposition favicon16Composition = IconComposition(
  starCx: 0.5,
  starCy: 0.475,
  starR: 7.1 / 16,
);

// ---------------------------------------------------------------------------
// Rasteriser
// ---------------------------------------------------------------------------

/// A straight RGBA byte buffer with antialiased fills.
///
/// Written by hand rather than pulled from a package (rule X6): the whole icon
/// is polygons and axis-aligned rectangles, the entire drawing surface needed
/// is three methods, and a dependency here would have to be trusted by the
/// tests that verify the output.
class Raster {
  Raster(this.width, this.height, {int background = 0x00000000})
      : pixels = Uint8List(width * height * 4) {
    fillAll(background);
  }

  final int width;
  final int height;
  final Uint8List pixels;

  /// Sub-samples per axis. Coverage is estimated by point sampling, so this is
  /// the antialiasing quality: 8 means 64 samples per pixel.
  int get _samples => width <= 64 ? 16 : 6;

  void fillAll(int argb) {
    final a = (argb >> 24) & 0xFF;
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    for (var i = 0; i < pixels.length; i += 4) {
      pixels[i] = r;
      pixels[i + 1] = g;
      pixels[i + 2] = b;
      pixels[i + 3] = a;
    }
  }

  /// Source-over blend of [argb] at [coverage] into one pixel.
  void _blend(int x, int y, int argb, double coverage) {
    if (coverage <= 0 || x < 0 || y < 0 || x >= width || y >= height) {
      return;
    }
    final alpha = ((argb >> 24) & 0xFF) / 255.0 * coverage.clamp(0.0, 1.0);
    if (alpha <= 0) {
      return;
    }
    final i = (y * width + x) * 4;
    final sr = (argb >> 16) & 0xFF;
    final sg = (argb >> 8) & 0xFF;
    final sb = argb & 0xFF;
    final da = pixels[i + 3] / 255.0;
    final outA = alpha + da * (1 - alpha);
    if (outA <= 0) {
      return;
    }
    pixels[i] = ((sr * alpha + pixels[i] * da * (1 - alpha)) / outA).round();
    pixels[i + 1] =
        ((sg * alpha + pixels[i + 1] * da * (1 - alpha)) / outA).round();
    pixels[i + 2] =
        ((sb * alpha + pixels[i + 2] * da * (1 - alpha)) / outA).round();
    pixels[i + 3] = (outA * 255).round();
  }

  /// Axis-aligned rectangle with EXACT coverage.
  ///
  /// Analytic rather than sampled because every seam in the icon is a pair of
  /// rectangles, and a sampled edge on a straight line is visibly ragged at
  /// the sizes where the seam still exists.
  void fillRect(double x0, double y0, double x1, double y1, int argb) {
    final left = math.max(0, x0.floor());
    final right = math.min(width, x1.ceil());
    final top = math.max(0, y0.floor());
    final bottom = math.min(height, y1.ceil());
    for (var y = top; y < bottom; y++) {
      final dy = math.min(y + 1.0, y1) - math.max(y.toDouble(), y0);
      if (dy <= 0) {
        continue;
      }
      for (var x = left; x < right; x++) {
        final dx = math.min(x + 1.0, x1) - math.max(x.toDouble(), x0);
        if (dx <= 0) {
          continue;
        }
        _blend(x, y, argb, dx * dy);
      }
    }
  }

  /// Any shape at all, described by a point-inside predicate.
  ///
  /// Rings, half-rings and polygons all reduce to this, which keeps the
  /// wordmark on the social card from needing a font renderer.
  void fillShape(
    double x0,
    double y0,
    double x1,
    double y1,
    int argb,
    bool Function(double x, double y) inside,
  ) {
    final s = _samples;
    final step = 1.0 / s;
    final left = math.max(0, x0.floor());
    final right = math.min(width, x1.ceil());
    final top = math.max(0, y0.floor());
    final bottom = math.min(height, y1.ceil());
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        var hits = 0;
        for (var sy = 0; sy < s; sy++) {
          final py = y + (sy + 0.5) * step;
          for (var sx = 0; sx < s; sx++) {
            if (inside(x + (sx + 0.5) * step, py)) {
              hits++;
            }
          }
        }
        if (hits > 0) {
          _blend(x, y, argb, hits / (s * s));
        }
      }
    }
  }

  void fillPolygon(List<double> points, int argb) {
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (var i = 0; i < points.length; i += 2) {
      minX = math.min(minX, points[i]);
      maxX = math.max(maxX, points[i]);
      minY = math.min(minY, points[i + 1]);
      maxY = math.max(maxY, points[i + 1]);
    }
    fillShape(minX, minY, maxX, maxY, argb,
        (x, y) => pointInPolygon(points, x, y));
  }

  int pixelAt(int x, int y) {
    final i = (y * width + x) * 4;
    return (pixels[i + 3] << 24) |
        (pixels[i] << 16) |
        (pixels[i + 1] << 8) |
        pixels[i + 2];
  }
}

/// Even-odd containment.
bool pointInPolygon(List<double> points, double x, double y) {
  var inside = false;
  final n = points.length ~/ 2;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    final xi = points[i * 2];
    final yi = points[i * 2 + 1];
    final xj = points[j * 2];
    final yj = points[j * 2 + 1];
    if ((yi > y) != (yj > y) &&
        x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
      inside = !inside;
    }
  }
  return inside;
}

// ---------------------------------------------------------------------------
// Drawing the compositions
// ---------------------------------------------------------------------------

/// Draws [composition] onto a fresh square raster of [size] pixels.
///
/// [inkColor] and [groundColor] are parameters rather than constants so the
/// same geometry produces the dark-scheme and monochrome variants without a
/// second copy of the drawing code.
Raster renderComposition(
  IconComposition composition,
  int size, {
  int groundColor = kPaper,
  int inkColor = kInk,
  int tintColor = kTint,
  bool drawGround = true,
}) {
  final raster = Raster(size, size,
      background: drawGround ? groundColor : 0x00000000);
  final seam = composition.seam;
  if (seam != null) {
    drawSeam(raster, seam, size, inkColor: inkColor, tintColor: tintColor);
  }
  raster.fillPolygon(
    starPolygon(
      cx: composition.starCx * size,
      cy: composition.starCy * size,
      r: composition.starR * size,
    ),
    inkColor,
  );
  return raster;
}

/// The tinted region and the ink boundary that encloses it.
///
/// The stroke is centred on the path and mitred, never rounded: a rounded join
/// would read as a soft UI element, and the whole visual language here is
/// well-printed paper, where an inked corner is sharp.
void drawSeam(
  Raster raster,
  SeamSpec seam,
  int size, {
  int inkColor = kInk,
  int tintColor = kTint,
}) {
  final cornerX = seam.cornerX * size;
  final cornerY = seam.cornerY * size;
  final half = seam.stroke * size / 2;

  // The tint runs to the far edge of the stroke, so no paper-coloured hairline
  // can appear between the region and its own boundary at any scale.
  raster.fillRect(0, cornerY - half, cornerX + half, size.toDouble(),
      tintColor);
  raster.fillRect(0, cornerY - half, cornerX + half, cornerY + half, inkColor);
  raster.fillRect(
      cornerX - half, cornerY - half, cornerX + half, size.toDouble(),
      inkColor);
}

// ---------------------------------------------------------------------------
// PNG
// ---------------------------------------------------------------------------

final Uint32List _crcTable = () {
  final table = Uint32List(256);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    table[n] = c;
  }
  return table;
}();

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

void _addUint32(BytesBuilder out, int value) {
  out.addByte((value >> 24) & 0xFF);
  out.addByte((value >> 16) & 0xFF);
  out.addByte((value >> 8) & 0xFF);
  out.addByte(value & 0xFF);
}

void _addChunk(BytesBuilder out, String type, List<int> data) {
  final payload = <int>[...type.codeUnits, ...data];
  _addUint32(out, data.length);
  out.add(payload);
  _addUint32(out, _crc32(payload));
}

/// 8-bit RGBA, no interlacing. The only PNG this project writes.
Uint8List encodePng(Raster raster) {
  final rows = BytesBuilder();
  final stride = raster.width * 4;
  for (var y = 0; y < raster.height; y++) {
    rows.addByte(0); // Filter type 0: none.
    rows.add(Uint8List.sublistView(raster.pixels, y * stride, (y + 1) * stride));
  }

  final png = BytesBuilder();
  png.add(<int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  final ihdr = BytesBuilder();
  _addUint32(ihdr, raster.width);
  _addUint32(ihdr, raster.height);
  ihdr.add(<int>[8, 6, 0, 0, 0]);
  _addChunk(png, 'IHDR', ihdr.takeBytes());

  _addChunk(png, 'IDAT',
      ZLibCodec(level: 9).encode(rows.takeBytes()));
  _addChunk(png, 'IEND', const <int>[]);
  return png.takeBytes();
}

/// Reads back what [encodePng] wrote, so tests can assert on real pixels
/// rather than on the drawing code's own opinion of what it drew.
Raster decodePng(Uint8List bytes) {
  var offset = 8;
  var width = 0;
  var height = 0;
  final idat = BytesBuilder();
  while (offset < bytes.length) {
    final length = (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    final data = bytes.sublist(offset + 8, offset + 8 + length);
    if (type == 'IHDR') {
      width = (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
      height = (data[4] << 24) | (data[5] << 16) | (data[6] << 8) | data[7];
      if (data[8] != 8 || data[9] != 6) {
        throw StateError('only 8-bit RGBA PNG is supported, got depth '
            '${data[8]} colour type ${data[9]}');
      }
    } else if (type == 'IDAT') {
      idat.add(data);
    }
    offset += 12 + length;
  }

  final raw = Uint8List.fromList(ZLibCodec().decode(idat.takeBytes()));
  final raster = Raster(width, height);
  final stride = width * 4;
  final line = Uint8List(stride);
  final previous = Uint8List(stride);
  var pos = 0;
  for (var y = 0; y < height; y++) {
    final filter = raw[pos++];
    for (var x = 0; x < stride; x++) {
      final value = raw[pos + x];
      final left = x >= 4 ? line[x - 4] : 0;
      final up = previous[x];
      final upLeft = x >= 4 ? previous[x - 4] : 0;
      line[x] = switch (filter) {
        0 => value,
        1 => (value + left) & 0xFF,
        2 => (value + up) & 0xFF,
        3 => (value + ((left + up) >> 1)) & 0xFF,
        4 => (value + _paeth(left, up, upLeft)) & 0xFF,
        _ => throw StateError('unknown PNG filter $filter'),
      };
    }
    pos += stride;
    raster.pixels.setRange(y * stride, (y + 1) * stride, line);
    previous.setAll(0, line);
  }
  return raster;
}

int _paeth(int a, int b, int c) {
  final p = a + b - c;
  final pa = (p - a).abs();
  final pb = (p - b).abs();
  final pc = (p - c).abs();
  if (pa <= pb && pa <= pc) {
    return a;
  }
  return pb <= pc ? b : c;
}

/// An .ico wrapping PNG entries, which every browser and Windows since Vista
/// reads. Still shipped because a bare /favicon.ico request is made by clients
/// that never look at the HTML.
Uint8List encodeIco(List<Raster> images) {
  final out = BytesBuilder();
  final encoded = images.map(encodePng).toList();
  out.add(<int>[0, 0, 1, 0, images.length & 0xFF, 0]);
  var offset = 6 + 16 * images.length;
  for (var i = 0; i < images.length; i++) {
    out.addByte(images[i].width & 0xFF);
    out.addByte(images[i].height & 0xFF);
    out.add(<int>[0, 0, 1, 0, 32, 0]);
    final length = encoded[i].length;
    out.add(<int>[
      length & 0xFF,
      (length >> 8) & 0xFF,
      (length >> 16) & 0xFF,
      (length >> 24) & 0xFF,
      offset & 0xFF,
      (offset >> 8) & 0xFF,
      (offset >> 16) & 0xFF,
      (offset >> 24) & 0xFF,
    ]);
    offset += length;
  }
  for (final png in encoded) {
    out.add(png);
  }
  return out.takeBytes();
}

// ---------------------------------------------------------------------------
// Vector output
// ---------------------------------------------------------------------------

/// The star as SVG/Android path data on an arbitrary viewport.
String starPathData({
  required double cx,
  required double cy,
  required double r,
}) {
  final points = starPolygon(cx: cx, cy: cy, r: r);
  final buffer = StringBuffer();
  for (var i = 0; i < points.length; i += 2) {
    buffer.write(i == 0 ? 'M' : 'L');
    buffer.write('${_round(points[i])},${_round(points[i + 1])} ');
  }
  buffer.write('Z');
  return buffer.toString();
}

/// The seam's two rectangles and the tinted region, as path data.
String seamPathData(SeamSpec seam, double size) {
  final cx = seam.cornerX * size;
  final cy = seam.cornerY * size;
  final half = seam.stroke * size / 2;
  return 'M0,${_round(cy - half)} H${_round(cx + half)} '
      'V$size H${_round(cx - half)} V${_round(cy + half)} '
      'H0 Z';
}

String regionPathData(SeamSpec seam, double size) {
  final cx = seam.cornerX * size;
  final cy = seam.cornerY * size;
  final half = seam.stroke * size / 2;
  return 'M0,${_round(cy - half)} H${_round(cx + half)} V$size H0 Z';
}

String _round(double v) {
  final r = (v * 100).round() / 100;
  return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toString();
}
