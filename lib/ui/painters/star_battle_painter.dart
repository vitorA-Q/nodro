import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../../engine/puzzles/star_battle/board.dart';
import '../game/play_grid.dart';
import '../theme/nodro_theme.dart';

/// Draws a Star Battle board.
///
/// ## The border is the information (decision D11)
///
/// Region identity is carried by a heavy stroke; the tints are reinforcement
/// and are near-identical in greyscale on purpose. See [NodroPalette].
///
/// ## What each layer is for
///
/// 1. region tints — grouping, colour-seeing eyes only
/// 2. hairlines — the grid reads as a grid
/// 3. **neighbour wash** — the eight cells around a star are shaded to say
///    "occupied". This teaches the no-touching rule without text and is the
///    most valuable single element on the board.
/// 4. region borders — the actual information
/// 5. marks — stars heavy and dark, crosses light and thin
/// 6. conflict rings — red, and red appears nowhere else in the app
class StarBattlePainter extends CustomPainter {
  const StarBattlePainter({
    required this.grid,
    required this.palette,
    required this.blocked,
    required this.conflicts,
    required this.placeProgress,
    required this.placedCell,
    required this.conflictProgress,
    required this.winProgress,
  });

  final PlayGrid grid;
  final NodroPalette palette;

  /// Cells adjacent to a star. Passed in rather than recomputed so the screen
  /// can animate their arrival.
  final Set<int> blocked;
  final Set<int> conflicts;

  /// 0..1 for the star most recently placed. Gives it scale and overshoot so a
  /// mark never simply appears.
  final double placeProgress;
  final int? placedCell;

  /// 0..1 for conflict rings. Animates IN, then holds still — a loop would nag
  /// a player who is trying to concentrate, for as long as the mistake exists.
  final double conflictProgress;

  /// 0..1 across the victory sequence.
  final double winProgress;

  bool get _isSolved => winProgress > 0;

  @override
  void paint(Canvas canvas, Size size) {
    final n = grid.size;
    final cell = size.width / n;

    _paintRegionFills(canvas, n, cell);
    _paintNeighbourWash(canvas, n, cell);
    _paintHairlines(canvas, n, cell, size);
    _paintRegionBorders(canvas, n, cell, size);
    _paintMarks(canvas, n, cell);
    _paintConflicts(canvas, n, cell);
  }

  void _paintRegionFills(Canvas canvas, int n, double cell) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        paint.color = palette
            .regionTints[grid.puzzle.regionAt(row, col) % palette.regionTints.length];
        canvas.drawRect(Rect.fromLTWH(col * cell, row * cell, cell, cell), paint);
      }
    }
  }

  /// The teaching layer. An inset wash, slightly rounded so it reads as a
  /// recess rather than as another block of colour, and neutral rather than red
  /// because "you cannot use this" is not the same message as "you made a
  /// mistake".
  void _paintNeighbourWash(Canvas canvas, int n, double cell) {
    if (blocked.isEmpty) {
      return;
    }
    final inset = cell * 0.06;
    for (final index in blocked) {
      // Cells around the star just placed fade in; the rest are already there.
      final t = index == placedCell || _neighboursOfPlaced.contains(index)
          ? Curves.easeOut.transform(placeProgress.clamp(0.0, 1.0))
          : 1.0;
      if (t <= 0) {
        continue;
      }
      final row = index ~/ n;
      final col = index % n;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(col * cell + inset, row * cell + inset,
              cell - inset * 2, cell - inset * 2),
          Radius.circular(cell * 0.12),
        ),
        Paint()
          ..color = palette.neighbourWash.withValues(
              alpha: palette.neighbourWash.a * t)
          ..style = PaintingStyle.fill,
      );
    }
  }

  Set<int> get _neighboursOfPlaced {
    final placed = placedCell;
    if (placed == null) {
      return const <int>{};
    }
    final n = grid.size;
    final row = placed ~/ n;
    final col = placed % n;
    final result = <int>{};
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final r = row + dr;
        final c = col + dc;
        if (r < 0 || r >= n || c < 0 || c >= n) {
          continue;
        }
        result.add(r * n + c);
      }
    }
    return result;
  }

  void _paintHairlines(Canvas canvas, int n, double cell, Size size) {
    final paint = Paint()
      ..color = palette.hairline
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < n; i++) {
      final offset = i * cell;
      canvas.drawLine(Offset(offset, 0), Offset(offset, size.height), paint);
      canvas.drawLine(Offset(0, offset), Offset(size.width, offset), paint);
    }
  }

  void _paintRegionBorders(Canvas canvas, int n, double cell, Size size) {
    final thickness = math.max(2.5, cell * 0.085);
    final paint = Paint()
      ..color = _isSolved
          ? Color.lerp(palette.ink, palette.success, winProgress)!
          : palette.ink
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        final region = grid.puzzle.regionAt(row, col);
        final left = col * cell;
        final top = row * cell;
        if (col + 1 < n && grid.puzzle.regionAt(row, col + 1) != region) {
          canvas.drawLine(
              Offset(left + cell, top), Offset(left + cell, top + cell), paint);
        }
        if (row + 1 < n && grid.puzzle.regionAt(row + 1, col) != region) {
          canvas.drawLine(
              Offset(left, top + cell), Offset(left + cell, top + cell), paint);
        }
      }
    }

    canvas.drawRect(
      Rect.fromLTWH(thickness / 2, thickness / 2, size.width - thickness,
          size.height - thickness),
      paint,
    );
  }

  void _paintMarks(Canvas canvas, int n, double cell) {
    final stars = grid.starIndices;
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        final index = row * n + col;
        final state = grid.stateAt(index);
        if (state == CellState.unknown) {
          continue;
        }
        final centre = Offset(col * cell + cell / 2, row * cell + cell / 2);
        if (state == CellState.star) {
          _paintStar(canvas, centre, cell, index, stars);
        } else {
          _paintCross(canvas, centre, cell * 0.17);
        }
      }
    }
  }

  void _paintStar(
      Canvas canvas, Offset centre, double cell, int index, List<int> stars) {
    var scale = 1.0;

    if (index == placedCell && placeProgress < 1) {
      // Overshoot: the mark springs past full size and settles. This is what
      // makes a tap feel answered rather than merely recorded.
      scale = Curves.easeOutBack.transform(placeProgress.clamp(0.0, 1.0));
    }

    if (_isSolved) {
      // Victory: the stars settle one after another rather than all at once.
      final order = stars.indexOf(index);
      final start = stars.isEmpty ? 0.0 : (order / stars.length) * 0.6;
      final local = ((winProgress - start) / 0.4).clamp(0.0, 1.0);
      scale = 1 + 0.18 * math.sin(local * math.pi);
    }

    final radius = cell * 0.32 * scale;
    if (radius <= 0) {
      return;
    }

    final path = Path();
    const points = 5;
    final inner = radius * 0.42;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : inner;
      final angle = -math.pi / 2 + i * math.pi / points;
      final point = Offset(
          centre.dx + r * math.cos(angle), centre.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = _isSolved
            ? Color.lerp(palette.ink, palette.success, winProgress)!
            : palette.ink
        ..style = PaintingStyle.fill,
    );
  }

  void _paintCross(Canvas canvas, Offset centre, double radius) {
    final paint = Paint()
      ..color = palette.markGrey
      ..strokeWidth = math.max(1.6, radius * 0.26)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(centre.translate(-radius, -radius),
        centre.translate(radius, radius), paint);
    canvas.drawLine(centre.translate(radius, -radius),
        centre.translate(-radius, radius), paint);
  }

  /// Rings enter and then hold still. No pulse, no breathing: a player staring
  /// at a board to think does not need something flickering at the edge of
  /// vision for however many minutes the mistake survives.
  void _paintConflicts(Canvas canvas, int n, double cell) {
    if (conflicts.isEmpty || conflictProgress <= 0) {
      return;
    }
    final t = Curves.easeOutBack.transform(conflictProgress.clamp(0.0, 1.0));
    final paint = Paint()
      ..color = palette.danger
      ..strokeWidth = math.max(2.0, cell * 0.055)
      ..style = PaintingStyle.stroke;

    for (final index in conflicts) {
      final row = index ~/ n;
      final col = index % n;
      final centre = Offset(col * cell + cell / 2, row * cell + cell / 2);
      canvas.drawCircle(centre, cell * 0.40 * t, paint);
    }
  }

  @override
  bool shouldRepaint(StarBattlePainter old) =>
      !identical(old.grid, grid) ||
      old.palette != palette ||
      old.placeProgress != placeProgress ||
      old.placedCell != placedCell ||
      old.conflictProgress != conflictProgress ||
      old.winProgress != winProgress ||
      !setEquals(old.blocked, blocked) ||
      !setEquals(old.conflicts, conflicts);
}
