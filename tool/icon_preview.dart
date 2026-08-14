/// Builds `store/icon-preview.html`: the icon under every mask and against
/// every background it will actually meet.
///
///     dart run tool/icon_preview.dart
///
/// This exists because an icon judged on a white page at 512 pixels is an icon
/// judged in the one context it never appears in. The two measured failure
/// modes in the competitive survey — an element too small on a large field,
/// and a ground that collapses into its surroundings — are both invisible at
/// full size and obvious here.
library;

import 'dart:convert';
import 'dart:io';

import 'icon_spec.dart';

void main() {
  String dataUri(Raster raster) =>
      'data:image/png;base64,${base64Encode(encodePng(raster))}';

  final any512 = dataUri(renderComposition(anyComposition, 512));
  final maskable = dataUri(renderComposition(maskableComposition, 512));
  final adaptive = dataUri(_adaptiveComposite(432));
  final favicon16 = dataUri(renderComposition(favicon16Composition, 16));
  final favicon32 = dataUri(renderComposition(faviconComposition, 32));
  final favicon48 = dataUri(renderComposition(faviconComposition, 48));
  final small48 = dataUri(renderComposition(anyComposition, 48));
  final small72 = dataUri(renderComposition(anyComposition, 72));

  final html = '''<!doctype html>
<meta charset="utf-8">
<title>Nodro icon — verification sheet</title>
<style>
 body{margin:0;background:#FAF7F1;color:#141821;
  font:15px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
 main{max-width:900px;margin:0 auto;padding:32px 20px 80px}
 h1{font-size:1.5rem;margin:0 0 .2em}
 h2{font-size:1rem;margin:2.4em 0 .6em;text-transform:uppercase;
  letter-spacing:.08em;color:#6B7180}
 p{color:#2A303C;max-width:62ch}
 .row{display:flex;flex-wrap:wrap;gap:18px;align-items:flex-end}
 .cell{text-align:center;font-size:12px;color:#6B7180}
 .swatch{display:flex;align-items:center;justify-content:center;
  padding:16px;border-radius:8px;margin-bottom:6px}
 .swatch img{width:96px;height:96px;display:block}
 .mask img{width:128px;height:128px;display:block}
 .circle img{border-radius:50%}
 .squircle img{border-radius:32%}
 .rounded img{border-radius:22%}
 .play img{border-radius:30%;box-shadow:0 2px 8px rgba(0,0,0,.28)}
 .pixels img{image-rendering:pixelated;display:block}
 .tab{display:inline-flex;align-items:center;gap:8px;padding:8px 14px;
  border-radius:8px 8px 0 0;font-size:13px}
 .tab img{width:16px;height:16px;image-rendering:pixelated}
</style>
<main>
<h1>Nodro icon — verification sheet</h1>
<p>Every panel below is the real generated file, not a mock-up. Nothing here
is hand-drawn: all of it comes from <code>tool/icon_spec.dart</code>.</p>

<h2>1 · Against the backgrounds it will meet</h2>
<p>The known weakness is here: warm paper measures 1.07:1 against pure white,
so the tile edge dissolves. The mark still sits at 16.6:1, so it stays legible
— and the Play Store adds its own drop shadow, which restores the edge on the
one surface where this matters most (last panel).</p>
<div class="row">
${_swatch('#FFFFFF', 'pure white', any512)}
${_swatch('#F1F3F4', 'Play card grey', any512)}
${_swatch('#1C1C1E', 'dark UI', any512)}
${_swatch('#808080', 'mid grey', any512)}
<div class="cell"><div class="swatch play" style="background:#FFFFFF">
<img src="$any512" alt=""></div>as Play renders it</div>
</div>

<h2>2 · Under every launcher mask</h2>
<p>The maskable icon keeps its whole star inside the guaranteed safe circle, so
no mask can clip a point off it. The seam is placed to survive the circle too —
only the far corner of the tinted region is ever cut.</p>
<div class="row">
<div class="cell mask circle"><img src="$maskable" alt="">circle</div>
<div class="cell mask squircle"><img src="$maskable" alt="">squircle</div>
<div class="cell mask rounded"><img src="$maskable" alt="">rounded square</div>
<div class="cell mask"><img src="$maskable" alt="">uncropped</div>
</div>

<h2>3 · Android adaptive, both layers composited</h2>
<p>Star in the foreground layer, seam in the background layer. They are never
mixed, because launchers slide the layers against each other for parallax and
a mark split across both would come apart in motion. The star is pushed up and
right so the region still fits inside a circular mask — centred, it did not.</p>
<div class="row">
<div class="cell mask circle"><img src="$adaptive" alt="">circle</div>
<div class="cell mask squircle"><img src="$adaptive" alt="">squircle</div>
<div class="cell mask rounded"><img src="$adaptive" alt="">rounded square</div>
</div>

<h2>4 · Small sizes, magnified so the pixels are visible</h2>
<p>16&nbsp;px is 256 pixels in total and no stroke survives it, so the favicon
drops the seam and grows the star instead. The fat star — inner radius exactly
half the outer, against the usual 0.38 — is what keeps the five points apart
down here.</p>
<div class="row pixels">
<div class="cell"><img src="$favicon16" width="128" height="128" alt="">
16 px favicon</div>
<div class="cell"><img src="$favicon32" width="128" height="128" alt="">
32 px favicon</div>
<div class="cell"><img src="$favicon48" width="128" height="128" alt="">
48 px favicon</div>
<div class="cell"><img src="$small48" width="128" height="128" alt="">
48 px app icon</div>
<div class="cell"><img src="$small72" width="144" height="144" alt="">
72 px app icon</div>
</div>

<h2>5 · In a browser tab, light and dark</h2>
<p>This is the panel that decided the ground colour. Paper on the dark tab
strip is 15.06:1. An ink ground would have been 1.10:1 — invisible — and for a
product that launches on the web that would have been the worse trade.</p>
<div class="row">
<div class="tab" style="background:#DEE1E6;color:#202124">
<img src="$favicon16" alt=""> Nodro — Star Battle</div>
<div class="tab" style="background:#202124;color:#E8EAED">
<img src="$favicon16" alt=""> Nodro — Star Battle</div>
</div>
</main>
''';

  final file = File('store/icon-preview.html');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(html);
  stdout.writeln('store/icon-preview.html  ${html.length} bytes');
}

String _swatch(String background, String label, String src) =>
    '<div class="cell"><div class="swatch" style="background:$background">'
    '<img src="$src" alt=""></div>$label</div>';

/// Flattens the two adaptive layers the way a launcher does, and crops to the
/// 72dp viewport before masking.
///
/// The crop is the point: 18dp is discarded on every side, so previewing the
/// full 108dp canvas would show a composition no launcher ever displays.
Raster _adaptiveComposite(int size) {
  final full = size * 108 ~/ 72;
  final canvas = Raster(full, full, background: kPaper);
  drawSeam(canvas, adaptiveBackgroundSeam, full);
  canvas.fillPolygon(
    starPolygon(
      cx: adaptiveForeground.starCx * full,
      cy: adaptiveForeground.starCy * full,
      r: adaptiveForeground.starR * full,
    ),
    kInk,
  );

  final viewport = Raster(size, size);
  final inset = (full - size) ~/ 2;
  for (var y = 0; y < size; y++) {
    viewport.pixels.setRange(
      y * size * 4,
      (y + 1) * size * 4,
      canvas.pixels,
      ((y + inset) * full + inset) * 4,
    );
  }
  return viewport;
}
