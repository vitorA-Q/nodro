// Builds the indexable static site. Run with:
//   dart run tool/generate_seo.dart --out public
//
// ## Why this exists
//
// Flutter Web renders into a WebGL canvas. The resulting DOM has no text nodes,
// no headings and no crawlable links, so a search engine extracts nothing from
// it and the page ranks for nothing. Organic discovery is this project's entire
// distribution strategy, which makes that not a detail but the difference
// between having players and not.
//
// The standard answer, and the one taken here: hand-written semantic HTML for
// everything a crawler should read, with the Flutter app mounted at /play/.
//
// ## Why the diagrams are generated
//
// Every SVG on the technique pages is produced by driving the REAL human solver
// until that technique actually fires. A hand-drawn diagram can quietly stop
// matching the game; a generated one cannot.

import 'dart:convert';
import 'dart:io';

import 'package:nodro/engine/core/deduction.dart';
import 'package:nodro/engine/puzzles/star_battle/board.dart';
import 'package:nodro/engine/puzzles/star_battle/human_solver.dart';
import 'package:nodro/engine/puzzles/star_battle/model.dart';
import 'package:nodro/engine/puzzles/star_battle/serializer.dart';

const String siteUrl = 'https://vitora-q.github.io/nodro';

/// Mirrors the light palette in lib/ui/theme/nodro_theme.dart. Duplicated on
/// purpose: this script must not import Flutter, and the palette is data.
const List<String> regionTints = <String>[
  '#F4D6D2', '#F0DAC0', '#E8DF9E', '#BFE9A3', '#A8EACB',
  '#B0E6ED', '#CCDEF3', '#DDDAF6', '#ECD4F5', '#F5D4E9',
];
const String ink = '#141821';
const String paper = '#FAF7F1';
const String accent = '#1D5FBF';
const String markGrey = '#9AA1AE';

class Lang {
  const Lang(this.code, this.dir, this.techniquesSegment);
  final String code;

  /// Path prefix. English is at the root; Portuguese lives under /pt.
  final String dir;
  final String techniquesSegment;

  bool get isDefault => code == 'en';
}

const Lang en = Lang('en', '', 'techniques');
const Lang pt = Lang('pt', 'pt', 'tecnicas');
const List<Lang> languages = <Lang>[en, pt];

late final Map<String, dynamic> arbEn;
late final Map<String, dynamic> arbPt;

Map<String, dynamic> arbFor(Lang lang) => lang.code == 'pt' ? arbPt : arbEn;

String tr(Lang lang, String key) {
  final value = arbFor(lang)[key] ?? arbEn[key];
  return value is String ? value : key;
}

/// Standalone prose for each technique.
///
/// NOT the in-app hint text. Those messages are written around live board
/// coordinates, and stripping the placeholders turns them into "every cell of
/// region … lies in this … …" — filler, and unreadable to both a person and a
/// crawler. A page that exists to be read needs sentences written to be read.
const Map<String, Map<String, String>> techniqueProse =
    <String, Map<String, String>>{
  'sbAdjacencyElimination': <String, String>{
    'en': 'The moment a star is placed, all eight cells around it are ruled '
        'out — the four orthogonal neighbours and the four diagonal ones. This '
        'is the single most productive elimination in Star Battle, and it is '
        'the reason experienced players mark neighbours immediately rather '
        'than looking for the next star.',
    'pt': 'No instante em que uma estrela é colocada, as oito células ao redor '
        'estão eliminadas — as quatro ortogonais e as quatro diagonais. É a '
        'eliminação mais produtiva do Star Battle, e é por isso que jogador '
        'experiente marca as vizinhas na hora em vez de procurar a próxima '
        'estrela.',
  },
  'sbUnitCompletionElimination': <String, String>{
    'en': 'A row, column or region that already holds all of its stars can '
        'hold no more, so every undecided cell in it is empty. On a one-star '
        'board this fires with the first star; on a two-star board only with '
        'the second. Getting that distinction wrong is the most common mistake '
        'when moving up from small boards.',
    'pt': 'Uma linha, coluna ou região que já tem todas as estrelas dela não '
        'comporta mais nenhuma, então toda célula indecisa ali está vazia. Num '
        'tabuleiro de uma estrela isso dispara na primeira; num de duas, só na '
        'segunda. Errar essa distinção é o engano mais comum de quem sobe de '
        'tabuleiros pequenos.',
  },
  'sbUnitForcedFill': <String, String>{
    'en': 'When the number of cells still open in a unit is exactly the number '
        'of stars it still needs, every one of those cells is a star. There is '
        'no choice left to make. This is usually the deduction that finishes a '
        'puzzle, and it is worth checking after every elimination.',
    'pt': 'Quando o número de células ainda abertas numa unidade é exatamente '
        'o número de estrelas que ela ainda precisa, todas elas são estrelas. '
        'Não sobrou escolha. Costuma ser a dedução que fecha o puzzle, e vale '
        'conferir depois de cada eliminação.',
  },
  'sbSharedNeighbourElimination': <String, String>{
    'en': 'If a unit still needs a star and only two or three cells can take '
        'it, then one of those cells certainly holds one. Any cell touching '
        'all of them is therefore impossible, whichever candidate turns out to '
        'be the star. It is a deduction made without knowing the answer, which '
        'is what makes it feel clever.',
    'pt': 'Se uma unidade ainda precisa de estrela e só duas ou três células '
        'podem recebê-la, então uma delas certamente tem uma. Qualquer célula '
        'que encoste em todas elas é impossível, seja qual for a candidata '
        'certa. É uma dedução feita sem saber a resposta — e é isso que a '
        'torna elegante.',
  },
  'sbRegionLineConfinement': <String, String>{
    'en': 'When every remaining cell of a region sits in one row or column, '
        'that region must place its stars there. Those stars consume the '
        'line\'s quota, so the rest of the line — the part outside the region '
        '— is empty. This is the first technique that makes Star Battle feel '
        'like more than crossing out neighbours.',
    'pt': 'Quando toda célula restante de uma região está numa mesma linha ou '
        'coluna, aquela região tem que pôr as estrelas dela ali. Essas '
        'estrelas consomem a cota da linha, então o resto dela — a parte fora '
        'da região — fica vazio. É a primeira técnica que faz o Star Battle '
        'parecer mais do que riscar vizinhas.',
  },
  'sbLineRegionConfinement': <String, String>{
    'en': 'The mirror image of the previous one. If every remaining cell of a '
        'row or column lies inside a single region, that line\'s stars come '
        'out of the region\'s quota — so the region\'s cells elsewhere on the '
        'board are empty. Looking for both directions doubles how often the '
        'idea pays off.',
    'pt': 'O espelho da anterior. Se toda célula restante de uma linha ou '
        'coluna está dentro de uma única região, as estrelas daquela linha '
        'saem da cota da região — então as células daquela região em outros '
        'pontos do tabuleiro ficam vazias. Procurar nos dois sentidos dobra a '
        'utilidade da ideia.',
  },
  'sbCrowdingExclusion': <String, String>{
    'en': 'A unit needing two or more stars cannot use a cell that touches '
        'every other candidate: taking it would black out all the others and '
        'leave nowhere for the remaining stars. The classic shape is the '
        'centre of a three-by-three cluster.',
    'pt': 'Uma unidade que precisa de duas ou mais estrelas não pode usar uma '
        'célula que encosta em todas as outras candidatas: escolhê-la apagaria '
        'todas as demais e não sobraria lugar para as estrelas restantes. A '
        'forma clássica é o centro de um bloco três por três.',
  },
  'sbForwardElimination': <String, String>{
    'en': 'Suppose a star went in a particular cell, and follow only the '
        'forced consequences: the neighbours it blocks and the units it '
        'closes. If some row, column or region can then no longer reach its '
        'own quota, the supposition was impossible and the cell is empty. This '
        'is a proof by contradiction of a single step — never a guess, and '
        'never a search.',
    'pt': 'Suponha uma estrela numa célula e siga só as consequências '
        'forçadas: as vizinhas que ela bloqueia e as unidades que ela fecha. '
        'Se alguma linha, coluna ou região não alcançar mais a própria cota, a '
        'suposição era impossível e a célula está vazia. É uma prova por '
        'contradição de um passo só — nunca um chute, nunca uma busca.',
  },
  'sbRegionsWithinLines': <String, String>{
    'en': 'Take a set of regions whose remaining cells all sit inside the same '
        'number of rows. Those regions supply exactly as many stars as those '
        'rows demand, so the two sets of stars must be the same stars — and '
        'every other cell in those rows is empty. A counting argument that '
        'needs no knowledge of where any individual star goes.',
    'pt': 'Pegue um conjunto de regiões cujas células restantes caibam todas '
        'no mesmo número de linhas. Essas regiões fornecem exatamente as '
        'estrelas que aquelas linhas pedem, então os dois conjuntos de '
        'estrelas são os mesmos — e toda outra célula daquelas linhas está '
        'vazia. Um argumento de contagem que não precisa saber onde nenhuma '
        'estrela específica vai.',
  },
};

String prose(Lang lang, String techniqueId) =>
    techniqueProse[techniqueId]?[lang.code] ??
    techniqueProse[techniqueId]?['en'] ??
    tr(lang, 'techName_$techniqueId');

void main(List<String> args) {
  final outIndex = args.indexOf('--out');
  final outDir = Directory(
      outIndex >= 0 && outIndex + 1 < args.length ? args[outIndex + 1] : 'public');

  arbEn = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  arbPt = jsonDecode(File('lib/l10n/app_pt.arb').readAsStringSync())
      as Map<String, dynamic>;

  if (outDir.existsSync()) {
    outDir.deleteSync(recursive: true);
  }
  outDir.createSync(recursive: true);

  final diagrams = _buildDiagrams();
  stdout.writeln('diagrams generated: ${diagrams.length} of '
      '${StarBattleHumanSolver.orderedTechniques.length}');

  final urls = <String>[];

  for (final lang in languages) {
    _write(outDir, _path(lang, ''), _homePage(lang));
    urls.add(_url(lang, ''));

    _write(outDir, _path(lang, 'star-battle'), _rulesPage(lang));
    urls.add(_url(lang, 'star-battle'));

    _write(outDir, _path(lang, 'star-battle/${lang.techniquesSegment}'),
        _techniqueIndexPage(lang, diagrams));
    urls.add(_url(lang, 'star-battle/${lang.techniquesSegment}'));

    for (final technique in StarBattleHumanSolver.orderedTechniques) {
      final slug = _slug(technique.id);
      final path = 'star-battle/${lang.techniquesSegment}/$slug';
      _write(outDir, _path(lang, path),
          _techniquePage(lang, technique.id, diagrams[technique.id]));
      urls.add(_url(lang, path));
    }
  }

  _writeRaw(outDir, 'sitemap.xml', _sitemap(urls));
  _writeRaw(outDir, 'robots.txt',
      'User-agent: *\nAllow: /\n\nSitemap: $siteUrl/sitemap.xml\n');
  _copyBrandAssets(outDir);

  stdout.writeln('pages written: ${urls.length}');
  stdout.writeln('output: ${outDir.path}');
}

// ----------------------------------------------------------------- diagrams

class Diagram {
  const Diagram(this.svg);
  final String svg;
}

/// Drives the real solver over a real bank puzzle until each technique fires,
/// and renders that exact position.
Map<String, Diagram> _buildDiagrams() {
  const serializer = StarBattleSerializer();

  // Several candidate boards, because an advanced technique simply never fires
  // on an easy puzzle — it has nothing to do there. Searching a handful of real
  // boards is still far better than drawing an example by hand, which could
  // quietly stop matching what the engine does.
  final candidates = <StarBattlePuzzle>[];
  for (final file in <String>[
    'star_battle_8x8_1.txt',
    'star_battle_6x6_1.txt',
    'star_battle_9x9_2.txt',
  ]) {
    final lines = File('assets/bank/$file').readAsLinesSync();
    for (final tier in <String>['4|', '3|', '2|']) {
      for (final line in lines.where((l) => l.startsWith(tier)).take(12)) {
        candidates
            .add(serializer.deserialize(line.substring(line.indexOf('|') + 1)));
      }
    }
  }

  final result = <String, Diagram>{};

  for (final technique in StarBattleHumanSolver.orderedTechniques) {
    for (final puzzle in candidates) {
      final solver = StarBattleHumanSolver();
      final board = StarBattleBoard(puzzle);
      var found = false;

      for (var step = 0; step < 200 && !found; step++) {
        final matches = technique.apply(board).where((deduction) => deduction
            .affectedCells
            .any((ref) => board.isUnknown(ref.toIndex(puzzle.size))));
        if (matches.isNotEmpty) {
          result[technique.id] = Diagram(_svg(puzzle, board, matches.first));
          found = true;
          break;
        }
        final next = solver.nextHint(board);
        if (next == null) {
          break;
        }
        for (final ref in next.affectedCells) {
          final index = ref.toIndex(puzzle.size);
          if (next.kind == DeductionKind.assertion) {
            board.placeStar(index);
          } else {
            board.markEmpty(index);
          }
        }
      }
      if (found) {
        break;
      }
    }
  }
  return result;
}

String _svg(
    StarBattlePuzzle puzzle, StarBattleBoard board, Deduction deduction) {
  const cell = 44.0;
  final size = puzzle.size;
  final total = cell * size;
  final evidence = deduction.highlightedCells
      .map((ref) => ref.toIndex(size))
      .toSet();
  final targets =
      deduction.affectedCells.map((ref) => ref.toIndex(size)).toSet();

  final buffer = StringBuffer()
    ..writeln('<svg xmlns="http://www.w3.org/2000/svg" '
        'viewBox="0 0 $total $total" width="$total" height="$total" '
        'role="img" aria-label="Star Battle diagram">');

  for (var row = 0; row < size; row++) {
    for (var col = 0; col < size; col++) {
      final tint = regionTints[puzzle.regionAt(row, col) % regionTints.length];
      buffer.writeln('<rect x="${col * cell}" y="${row * cell}" '
          'width="$cell" height="$cell" fill="$tint"/>');
    }
  }

  for (var i = 1; i < size; i++) {
    buffer
      ..writeln('<line x1="${i * cell}" y1="0" x2="${i * cell}" y2="$total" '
          'stroke="$ink" stroke-opacity="0.2" stroke-width="1"/>')
      ..writeln('<line x1="0" y1="${i * cell}" x2="$total" y2="${i * cell}" '
          'stroke="$ink" stroke-opacity="0.2" stroke-width="1"/>');
  }

  for (var row = 0; row < size; row++) {
    for (var col = 0; col < size; col++) {
      final region = puzzle.regionAt(row, col);
      final x = col * cell;
      final y = row * cell;
      if (col + 1 < size && puzzle.regionAt(row, col + 1) != region) {
        buffer.writeln('<line x1="${x + cell}" y1="$y" x2="${x + cell}" '
            'y2="${y + cell}" stroke="$ink" stroke-width="3.5"/>');
      }
      if (row + 1 < size && puzzle.regionAt(row + 1, col) != region) {
        buffer.writeln('<line x1="$x" y1="${y + cell}" x2="${x + cell}" '
            'y2="${y + cell}" stroke="$ink" stroke-width="3.5"/>');
      }
    }
  }
  buffer.writeln('<rect x="1.75" y="1.75" width="${total - 3.5}" '
      'height="${total - 3.5}" fill="none" stroke="$ink" stroke-width="3.5"/>');

  for (final index in evidence.union(targets)) {
    final x = (index % size) * cell;
    final y = (index ~/ size) * cell;
    final isTarget = targets.contains(index);
    buffer.writeln('<rect x="${x + 3}" y="${y + 3}" width="${cell - 6}" '
        'height="${cell - 6}" fill="$accent" '
        'fill-opacity="${isTarget ? 0.22 : 0.10}" stroke="$accent" '
        'stroke-width="${isTarget ? 3 : 1.6}"/>');
  }

  for (var index = 0; index < size * size; index++) {
    final x = (index % size) * cell + cell / 2;
    final y = (index ~/ size) * cell + cell / 2;
    switch (board.stateAt(index)) {
      case CellState.star:
        buffer.writeln('<polygon points="${_starPoints(x, y, cell * 0.32)}" '
            'fill="$ink"/>');
      case CellState.empty:
        final r = cell * 0.17;
        buffer
          ..writeln('<line x1="${x - r}" y1="${y - r}" x2="${x + r}" '
              'y2="${y + r}" stroke="$markGrey" stroke-width="2.4" '
              'stroke-linecap="round"/>')
          ..writeln('<line x1="${x + r}" y1="${y - r}" x2="${x - r}" '
              'y2="${y + r}" stroke="$markGrey" stroke-width="2.4" '
              'stroke-linecap="round"/>');
      case CellState.unknown:
        break;
    }
  }

  buffer.writeln('</svg>');
  return buffer.toString();
}

String _starPoints(double cx, double cy, double radius) {
  final points = <String>[];
  const count = 5;
  final inner = radius * 0.42;
  for (var i = 0; i < count * 2; i++) {
    final r = i.isEven ? radius : inner;
    final angle = -1.5707963 + i * 3.1415926 / count;
    final x = cx + r * _cos(angle);
    final y = cy + r * _sin(angle);
    points.add('${x.toStringAsFixed(2)},${y.toStringAsFixed(2)}');
  }
  return points.join(' ');
}

double _cos(double a) {
  // Small local implementations so this script needs no dart:math import
  // beyond what it already uses; accuracy here only affects a decoration.
  var sum = 1.0;
  var term = 1.0;
  for (var n = 1; n <= 12; n++) {
    term *= -a * a / ((2 * n - 1) * (2 * n));
    sum += term;
  }
  return sum;
}

double _sin(double a) {
  var sum = a;
  var term = a;
  for (var n = 1; n <= 12; n++) {
    term *= -a * a / ((2 * n) * (2 * n + 1));
    sum += term;
  }
  return sum;
}

// -------------------------------------------------------------------- pages

String _slug(String techniqueId) {
  final withoutPrefix = techniqueId.startsWith('sb')
      ? techniqueId.substring(2)
      : techniqueId;
  final buffer = StringBuffer();
  for (var i = 0; i < withoutPrefix.length; i++) {
    final char = withoutPrefix[i];
    final lower = char.toLowerCase();
    if (char != lower && i > 0) {
      buffer.write('-');
    }
    buffer.write(lower);
  }
  return buffer.toString();
}

String _path(Lang lang, String path) {
  final parts = <String>[
    if (lang.dir.isNotEmpty) lang.dir,
    if (path.isNotEmpty) path,
  ];
  return parts.isEmpty ? 'index.html' : '${parts.join('/')}/index.html';
}

String _url(Lang lang, String path) {
  final parts = <String>[
    if (lang.dir.isNotEmpty) lang.dir,
    if (path.isNotEmpty) path,
  ];
  return parts.isEmpty ? '$siteUrl/' : '$siteUrl/${parts.join('/')}/';
}

/// The icon files live in `web/` because that is where the Flutter build wants
/// them; the static site needs them at the site ROOT, because a browser asking
/// for /favicon.ico never reads any HTML first and a social scraper resolves
/// og:image against the domain. Copying rather than duplicating keeps
/// tool/generate_icons.dart the only thing that ever writes an icon.
void _copyBrandAssets(Directory root) {
  const files = <String>[
    'favicon.ico',
    'favicon.png',
    'favicon.svg',
    'og.png',
    'icons/Icon-192.png',
    'icons/Icon-512.png',
    'icons/apple-touch-icon.png',
  ];
  for (final name in files) {
    final source = File('web/$name');
    if (!source.existsSync()) {
      throw StateError('web/$name is missing — run '
          'dart run tool/generate_icons.dart before generating the site');
    }
    final target = File('${root.path}/$name');
    target.parent.createSync(recursive: true);
    target.writeAsBytesSync(source.readAsBytesSync());
  }
  stdout.writeln('brand assets copied: ${files.length}');
}

void _write(Directory root, String relative, String html) {
  final file = File('${root.path}/$relative');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(html);
}

void _writeRaw(Directory root, String relative, String content) =>
    _write(root, relative, content);

String _shell(
  Lang lang, {
  required String title,
  required String description,
  required String canonical,
  required String altPath,
  required String body,
  String structuredData = '',
}) {
  final other = lang.isDefault ? pt : en;
  return '''<!doctype html>
<html lang="${lang.code}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title</title>
<meta name="description" content="$description">
<link rel="canonical" href="$canonical">
<link rel="alternate" hreflang="${lang.code}" href="$canonical">
<link rel="alternate" hreflang="${other.code}" href="$altPath">
<link rel="alternate" hreflang="x-default" href="$siteUrl/">
<meta property="og:type" content="website">
<meta property="og:title" content="$title">
<meta property="og:description" content="$description">
<meta property="og:url" content="$canonical">
<meta property="og:image" content="$siteUrl/og.png">
<meta name="twitter:card" content="summary_large_image">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<link rel="icon" type="image/svg+xml" href="$siteUrl/favicon.svg">
<link rel="icon" type="image/png" sizes="32x32" href="$siteUrl/favicon.png">
<link rel="alternate icon" href="$siteUrl/favicon.ico">
<link rel="apple-touch-icon" href="$siteUrl/icons/apple-touch-icon.png">
$structuredData
<style>
:root{--paper:$paper;--ink:$ink;--soft:#6B7180;--accent:$accent}
*{box-sizing:border-box}
body{margin:0;background:var(--paper);color:var(--ink);
 font:16px/1.65 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
main{max-width:720px;margin:0 auto;padding:32px 20px 72px}
h1{font-size:2rem;line-height:1.2;margin:0 0 .4em}
h2{font-size:1.3rem;margin:2em 0 .5em}
h3{font-size:1.05rem;margin:1.6em 0 .3em}
p,li{color:#2A303C}
a{color:var(--accent)}
nav{font-size:.9rem;padding:14px 20px;border-bottom:1px solid #D8D3C8}
nav a{margin-right:14px}
ul{padding-left:1.2em}
svg{max-width:100%;height:auto;display:block;margin:18px auto}
.cta{display:block;text-align:center;background:var(--ink);color:var(--paper);
 text-decoration:none;font-weight:700;padding:16px;border-radius:12px;margin:36px 0}
.card{border:1px solid #D8D3C8;border-radius:12px;padding:16px;margin:12px 0}
footer{border-top:1px solid #D8D3C8;padding:20px;text-align:center;
 font-size:.85rem;color:var(--soft)}
</style>
</head>
<body>
<nav>
<a href="${_url(lang, '')}">Nodro</a>
<a href="${_url(lang, 'star-battle')}">Star Battle</a>
<a href="${_url(lang, 'star-battle/${lang.techniquesSegment}')}">${lang.code == 'pt' ? 'Técnicas' : 'Techniques'}</a>
<a href="$altPath">${lang.code == 'pt' ? 'English' : 'Português'}</a>
</nav>
<main>
$body
<a class="cta" href="$siteUrl/play/">${lang.code == 'pt' ? 'Jogar agora' : 'Play now'}</a>
</main>
<footer>Nodro · ${lang.code == 'pt' ? 'Puzzles lógicos com solução única provada' : 'Logic puzzles with provably unique solutions'}</footer>
</body>
</html>
''';
}

String _homePage(Lang lang) {
  final isPt = lang.code == 'pt';
  final body = isPt
      ? '''
<h1>Nodro — puzzles lógicos com solução única provada</h1>
<p>Nodro é uma coleção de puzzles lógicos da família Nikoli. Começamos pelo
<a href="${_url(lang, 'star-battle')}">Star Battle</a>, e cada puzzle tem
<strong>exatamente uma solução</strong> — não porque confiamos no gerador, mas
porque um verificador independente conta as soluções de todos eles antes de
chegarem até você.</p>

<h2>Três coisas que quase nenhum app de puzzle faz</h2>
<h3>Unicidade provada</h3>
<p>Todo puzzle passa por um solucionador exaustivo que conta as soluções e
descarta qualquer um com duas. Você nunca vai travar num puzzle impossível nem
descobrir que existiam duas respostas.</p>

<h3>Dificuldade honesta</h3>
<p>A dificuldade não é a quantidade de pistas nem o tempo de máquina. É a
técnica de dedução mais avançada que o puzzle <em>exige</em>, medida por um
solucionador que raciocina como uma pessoa e nunca chuta. Um puzzle só recebe o
rótulo mais difícil se ele resolve com aquele nível de técnica <em>e falha</em>
com o nível abaixo.</p>

<h3>Dicas que ensinam</h3>
<p>Peça uma dica e ela não entrega a resposta: ela nomeia a técnica, destaca as
células envolvidas e explica por que a dedução é válida. Em três toques, e você
pode parar no primeiro.</p>

<h2>Nenhum puzzle precisa de chute</h2>
<p>Cada puzzle publicado foi resolvido por um solucionador que só usa
<a href="${_url(lang, 'star-battle/${lang.techniquesSegment}')}">técnicas
nomeadas</a>. Se um puzzle não pudesse ser resolvido por raciocínio, ele não
seria publicado.</p>
'''
      : '''
<h1>Nodro — logic puzzles with provably unique solutions</h1>
<p>Nodro is a collection of Nikoli-family logic puzzles. It starts with
<a href="${_url(lang, 'star-battle')}">Star Battle</a>, and every puzzle has
<strong>exactly one solution</strong> — not because we trust the generator, but
because an independent verifier counts the solutions of every single one before
it reaches you.</p>

<h2>Three things almost no puzzle app does</h2>
<h3>Proven uniqueness</h3>
<p>Every puzzle passes through an exhaustive solver that counts solutions and
discards any with two. You will never get stuck on an impossible board or
discover afterwards that there were two answers.</p>

<h3>Honest difficulty</h3>
<p>Difficulty here is not a clue count or a machine timing. It is the most
advanced deduction the puzzle <em>requires</em>, measured by a solver that
reasons the way a person does and never guesses. A puzzle only earns the
hardest label if it solves with that level of technique <em>and fails</em> one
level below.</p>

<h3>Hints that teach</h3>
<p>Ask for a hint and it does not hand over the answer: it names the technique,
highlights the cells involved and explains why the deduction is valid. In three
taps, and you can stop at the first.</p>

<h2>No puzzle here needs a guess</h2>
<p>Every published puzzle was solved by a solver that uses only
<a href="${_url(lang, 'star-battle/${lang.techniquesSegment}')}">named
techniques</a>. If a puzzle could not be solved by reasoning, it was not
published.</p>
''';

  const structured = '''
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"Game","name":"Nodro",
"genre":"Logic puzzle","url":"$siteUrl/",
"description":"Nikoli-family logic puzzles with provably unique solutions.",
"applicationCategory":"Game","operatingSystem":"Web browser"}
</script>''';

  return _shell(
    lang,
    title: isPt
        ? 'Nodro — puzzles lógicos com solução única provada'
        : 'Nodro — logic puzzles with provably unique solutions',
    description: isPt
        ? 'Star Battle e outros puzzles lógicos Nikoli. Cada puzzle tem exatamente uma solução, provada por um verificador independente. Dicas que ensinam a técnica em vez de dar a resposta.'
        : 'Star Battle and other Nikoli logic puzzles. Every puzzle has exactly one solution, proven by an independent verifier. Hints that teach the technique instead of giving the answer.',
    canonical: _url(lang, ''),
    altPath: _url(lang.isDefault ? pt : en, ''),
    body: body,
    structuredData: structured,
  );
}

String _rulesPage(Lang lang) {
  final isPt = lang.code == 'pt';
  final body = isPt
      ? '''
<h1>Star Battle: regras e como jogar</h1>
<p>Star Battle é um puzzle lógico criado no Japão e publicado pela revista
Nikoli. Ele também é conhecido como <strong>Two Not Touch</strong>,
<strong>Queens</strong>, <strong>Starstruck</strong>,
<strong>Sternenschlacht</strong>, <strong>Doppelstern</strong> e
<strong>Estrella</strong>.</p>

<h2>As regras, em três linhas</h2>
<ul>
<li>Coloque um número fixo de estrelas em <strong>cada linha</strong>.</li>
<li>O mesmo número em <strong>cada coluna</strong> e em <strong>cada região</strong>
(as áreas delimitadas por bordas grossas).</li>
<li><strong>Estrelas nunca se tocam</strong> — nem na diagonal.</li>
</ul>
<p>Um tabuleiro 6×6 ou 8×8 costuma pedir uma estrela por linha; um 9×9 ou 10×10
costuma pedir duas. É só isso. Não há aritmética, não há números para somar.</p>

<h2>Como se começa de verdade</h2>
<p>O erro de quem começa é procurar onde a estrela <em>vai</em>. O caminho é o
contrário: procure onde ela <strong>não pode</strong> ir. Cada eliminação
aperta o tabuleiro, e em algum momento sobra uma única casa possível.</p>

<h3>Passo 1 — marque as vizinhas</h3>
<p>Colocou uma estrela? As oito células ao redor estão eliminadas na hora,
inclusive as diagonais. Essa é a regra que mais elimina casas no jogo inteiro.</p>

<h3>Passo 2 — feche a linha, a coluna e a região</h3>
<p>Quando uma linha já tem todas as estrelas dela, o resto da linha inteira está
eliminado. Atenção: num tabuleiro de duas estrelas, isso só acontece na
<strong>segunda</strong> estrela, não na primeira. Essa é a confusão mais comum
de quem vem de tabuleiros de uma estrela.</p>

<h3>Passo 3 — procure regiões espremidas</h3>
<p>Se todas as casas livres de uma região estiverem na mesma linha, então a
estrela daquela região está naquela linha — e o resto da linha, fora da região,
pode ser eliminado. Essa é a primeira técnica que faz o jogo parecer inteligente.</p>

<h2>Todas as técnicas</h2>
<p>Existem nove deduções nomeadas que resolvem qualquer puzzle daqui, sem
nenhum chute. Cada uma está explicada com diagrama na
<a href="${_url(lang, 'star-battle/${lang.techniquesSegment}')}">página de
técnicas</a>.</p>

<h2>Por que os puzzles daqui são diferentes</h2>
<p>Muitos apps de Star Battle geram puzzles sem verificar se existe exatamente
uma resposta. O resultado é o que se lê nas avaliações: níveis difíceis que
parecem ilógicos, e dicas que pedem para o jogador supor algo. Aqui, todo puzzle
foi resolvido por um solucionador que só usa técnicas nomeadas antes de ser
publicado. Se ele precisasse de chute, não estaria aqui.</p>
'''
      : '''
<h1>Star Battle: rules and how to play</h1>
<p>Star Battle is a logic puzzle from Japan, published by Nikoli. It also goes
by <strong>Two Not Touch</strong>, <strong>Queens</strong>,
<strong>Starstruck</strong>, <strong>Sternenschlacht</strong>,
<strong>Doppelstern</strong> and <strong>Estrella</strong>.</p>

<h2>The rules, in three lines</h2>
<ul>
<li>Place a fixed number of stars in <strong>every row</strong>.</li>
<li>The same number in <strong>every column</strong> and in
<strong>every region</strong> — the areas marked by thick borders.</li>
<li><strong>Stars never touch</strong> — not even diagonally.</li>
</ul>
<p>A 6×6 or 8×8 board usually asks for one star per line; a 9×9 or 10×10 usually
asks for two. That is all of it. No arithmetic, no numbers to add up.</p>

<h2>How you actually start</h2>
<p>The beginner's mistake is hunting for where a star <em>goes</em>. The way in
is the opposite: find where it <strong>cannot</strong> go. Each elimination
tightens the board, and eventually one square is the only one left.</p>

<h3>Step 1 — cross out the neighbours</h3>
<p>Placed a star? The eight cells around it are eliminated immediately,
diagonals included. This rule removes more squares than any other in the game.</p>

<h3>Step 2 — close the row, column and region</h3>
<p>Once a row holds all of its stars, the rest of that row is eliminated. Watch
out: on a two-star board that happens on the <strong>second</strong> star, not
the first. That is the most common confusion for anyone arriving from one-star
boards.</p>

<h3>Step 3 — look for squeezed regions</h3>
<p>If every free cell of a region sits in the same row, then that region's star
is in that row — and the rest of the row, outside the region, can be eliminated.
This is the first technique that makes the game feel clever.</p>

<h2>Every technique</h2>
<p>Nine named deductions solve any puzzle here, with no guessing at all. Each is
explained with a diagram on the
<a href="${_url(lang, 'star-battle/${lang.techniquesSegment}')}">techniques
page</a>.</p>

<h2>Why these puzzles are different</h2>
<p>Many Star Battle apps generate puzzles without checking that exactly one
answer exists. The result is what the reviews say: hard levels that feel
illogical, and hints that ask the player to assume something. Here every puzzle
was solved by a solver using only named techniques before it was published. If
it needed a guess, it is not here.</p>
''';

  return _shell(
    lang,
    title: isPt
        ? 'Star Battle: regras, como jogar e todas as técnicas | Nodro'
        : 'Star Battle: rules, how to play and every technique | Nodro',
    description: isPt
        ? 'As regras do Star Battle explicadas do zero, com as técnicas de dedução passo a passo. Também conhecido como Two Not Touch, Queens e Sternenschlacht.'
        : 'Star Battle rules explained from scratch, with every deduction technique step by step. Also known as Two Not Touch, Queens and Sternenschlacht.',
    canonical: _url(lang, 'star-battle'),
    altPath: _url(lang.isDefault ? pt : en, 'star-battle'),
    body: body,
  );
}

String _techniqueIndexPage(Lang lang, Map<String, Diagram> diagrams) {
  final isPt = lang.code == 'pt';
  final buffer = StringBuffer()
    ..writeln(isPt
        ? '<h1>As nove técnicas do Star Battle</h1><p>Toda dedução que um puzzle daqui pode exigir, nomeada e explicada. Nenhuma delas é chute: cada uma vale em <em>todas</em> as soluções possíveis do tabuleiro.</p>'
        : '<h1>The nine Star Battle techniques</h1><p>Every deduction a puzzle here can demand, named and explained. None of them is a guess: each one holds in <em>every</em> possible solution of the board.</p>');

  var lastTier = 0;
  for (final technique in StarBattleHumanSolver.orderedTechniques) {
    if (technique.tier.level != lastTier) {
      lastTier = technique.tier.level;
      buffer.writeln('<h2>${isPt ? 'Tier' : 'Tier'} $lastTier</h2>');
    }
    final name = tr(lang, 'techName_${technique.id}');
    final why = prose(lang, technique.id);
    final href = _url(lang, 'star-battle/${lang.techniquesSegment}/'
        '${_slug(technique.id)}');
    buffer.writeln('<div class="card"><h3><a href="$href">$name</a></h3>'
        '<p>$why</p></div>');
  }

  return _shell(
    lang,
    title: isPt
        ? 'Todas as técnicas de Star Battle, explicadas | Nodro'
        : 'Every Star Battle technique, explained | Nodro',
    description: isPt
        ? 'As nove técnicas de dedução do Star Battle, do básico ao avançado, cada uma com diagrama.'
        : 'The nine Star Battle deduction techniques, from basic to advanced, each with a diagram.',
    canonical: _url(lang, 'star-battle/${lang.techniquesSegment}'),
    altPath: _url(lang.isDefault ? pt : en,
        'star-battle/${(lang.isDefault ? pt : en).techniquesSegment}'),
    body: buffer.toString(),
  );
}

String _techniquePage(Lang lang, String techniqueId, Diagram? diagram) {
  final isPt = lang.code == 'pt';
  final name = tr(lang, 'techName_$techniqueId');
  final why = prose(lang, techniqueId);

  final body = StringBuffer()
    ..writeln('<h1>$name</h1>')
    ..writeln('<p>$why</p>');

  if (diagram != null) {
    body
      ..writeln(isPt
          ? '<h2>Como aparece no tabuleiro</h2><p>As células com contorno são as que sustentam o raciocínio; as de contorno grosso são a conclusão. Este diagrama foi gerado pelo mesmo solucionador que roda no jogo.</p>'
          : '<h2>What it looks like on the board</h2><p>The outlined cells are the evidence; the heavily outlined ones are the conclusion. This diagram was produced by the same solver that runs in the game.</p>')
      ..writeln(diagram.svg);
  }

  body.writeln(isPt
      ? '<h2>Por que é válido</h2><p>Esta dedução não depende de o puzzle ter uma resposta só, nem de qualquer suposição sobre quem montou o tabuleiro. Ela vale em toda solução possível — por isso o jogo pode aplicá-la sem risco, e por isso nenhum puzzle daqui precisa de chute.</p>'
      : '<h2>Why it holds</h2><p>This deduction does not rely on the puzzle having a single answer, nor on any assumption about whoever built the board. It holds in every possible solution — which is why the game can apply it safely, and why no puzzle here needs a guess.</p>');

  final howTo = '''
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"HowTo",
"name":${jsonEncode(name)},
"description":${jsonEncode(why)},
"step":[{"@type":"HowToStep","name":${jsonEncode(name)},
"text":${jsonEncode(why)}}]}
</script>''';

  return _shell(
    lang,
    title: isPt
        ? '$name — técnica de Star Battle | Nodro'
        : '$name — Star Battle technique | Nodro',
    description: why.length > 155 ? '${why.substring(0, 152)}…' : why,
    canonical: _url(
        lang, 'star-battle/${lang.techniquesSegment}/${_slug(techniqueId)}'),
    altPath: _url(
        lang.isDefault ? pt : en,
        'star-battle/${(lang.isDefault ? pt : en).techniquesSegment}/'
            '${_slug(techniqueId)}'),
    body: body.toString(),
    structuredData: howTo,
  );
}

String _sitemap(List<String> urls) {
  final buffer = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
  for (final url in urls) {
    buffer.writeln('<url><loc>$url</loc></url>');
  }
  buffer
    ..writeln('<url><loc>$siteUrl/play/</loc></url>')
    ..writeln('</urlset>');
  return buffer.toString();
}
