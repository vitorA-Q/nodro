import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/puzzles/star_battle/board.dart';
import '../../engine/puzzles/star_battle/model.dart';

/// Draws a Star Battle board.
///
/// ## Accessibility is the design, not a coat of paint (decision D11)
///
/// **The thick border carries the information. Colour is reinforcement only.**
/// Region fills are deliberately pale and close together in luminance, so the
/// board stays fully readable in greyscale: every region boundary is a heavy
/// dark stroke, every internal cell edge is a hairline. Someone who cannot
/// separate the tints loses nothing, because the tints were never load-bearing.
///
/// Visual direction: a well-printed paper puzzle. Warm off-white ground, crisp
/// high-contrast rules, no texture, no gloss, no ornament.
class StarBattlePainter extends CustomPainter {
  const StarBattlePainter({
    required this.puzzle,
    required this.cells,
    required this.isSolved,
  });

  final StarBattlePuzzle puzzle;

  /// Row-major player marks. Not the solver's board — the player may put a star
  /// anywhere, including somewhere wrong.
  final List<CellState> cells;

  final bool isSolved;

  // Paper-like palette. Fixed, not theme-derived, until dark mode arrives.
  static const Color paper = Color(0xFFFBFAF6);
  static const Color ink = Color(0xFF1E2430);
  static const Color hairline = Color(0xFFC9CDD6);
  static const Color markGrey = Color(0xFF9AA1AE);
  static const Color success = Color(0xFF1B7F5A);

  /// Ten pale tints of near-equal luminance. Near-equal is the point: if one
  /// were much darker, greyscale viewers would read it as meaningful when it is
  /// not. They exist to help the eye group cells, nothing more.
  static const List<Color> regionTints = <Color>[
    Color(0xFFEFF3FA),
    Color(0xFFF6F0F8),
    Color(0xFFEFF7F1),
    Color(0xFFFBF2EC),
    Color(0xFFF1F5EC),
    Color(0xFFF3F1FB),
    Color(0xFFFAF1F3),
    Color(0xFFECF6F7),
    Color(0xFFF8F5EA),
    Color(0xFFF2F0F0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final n = puzzle.size;
    final cell = size.width / n;

    _paintRegionFills(canvas, n, cell);
    _paintHairlines(canvas, n, cell, size);
    _paintRegionBorders(canvas, n, cell, size);
    _paintMarks(canvas, n, cell);
  }

  void _paintRegionFills(Canvas canvas, int n, double cell) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        paint.color = regionTints[puzzle.regionAt(row, col) % regionTints.length];
        canvas.drawRect(
          Rect.fromLTWH(col * cell, row * cell, cell, cell),
          paint,
        );
      }
    }
  }

  /// Hairlines mark every cell edge so the grid reads as a grid; the heavy
  /// strokes drawn afterwards are what separate the regions.
  void _paintHairlines(Canvas canvas, int n, double cell, Size size) {
    final paint = Paint()
      ..color = hairline
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < n; i++) {
      final offset = i * cell;
      canvas.drawLine(Offset(offset, 0), Offset(offset, size.height), paint);
      canvas.drawLine(Offset(0, offset), Offset(size.width, offset), paint);
    }
  }

  void _paintRegionBorders(Canvas canvas, int n, double cell, Size size) {
    // Scales with the board so the boundary stays obvious on a phone and does
    // not turn into a blob on a desktop.
    final thickness = math.max(2.5, cell * 0.09);
    final paint = Paint()
      ..color = isSolved ? success : ink
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        final region = puzzle.regionAt(row, col);
        final left = col * cell;
        final top = row * cell;

        if (col + 1 < n && puzzle.regionAt(row, col + 1) != region) {
          canvas.drawLine(
              Offset(left + cell, top), Offset(left + cell, top + cell), paint);
        }
        if (row + 1 < n && puzzle.regionAt(row + 1, col) != region) {
          canvas.drawLine(
              Offset(left, top + cell), Offset(left + cell, top + cell), paint);
        }
      }
    }

    // Outer frame, drawn last so corners stay square.
    canvas.drawRect(
      Rect.fromLTWH(
          thickness / 2, thickness / 2, size.width - thickness, size.height - thickness),
      paint,
    );
  }

  void _paintMarks(Canvas canvas, int n, double cell) {
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        final state = cells[row * n + col];
        if (state == CellState.unknown) {
          continue;
        }
        final centre = Offset(col * cell + cell / 2, row * cell + cell / 2);
        if (state == CellState.star) {
          _paintStar(canvas, centre, cell * 0.32);
        } else {
          _paintCross(canvas, centre, cell * 0.17);
        }
      }
    }
  }

  /// A solid five-pointed star. Deliberately large and filled: at a glance it
  /// must never be confusable with the cross, even on a small phone.
  void _paintStar(Canvas canvas, Offset centre, double radius) {
    final path = Path();
    const points = 5;
    final inner = radius * 0.42;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : inner;
      final angle = -math.pi / 2 + i * math.pi / points;
      final point =
          Offset(centre.dx + r * math.cos(angle), centre.dy + r * math.sin(angle));
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
        ..color = isSolved ? success : ink
        ..style = PaintingStyle.fill,
    );
  }

  /// A light, thin cross. Small and grey against the star's large solid black:
  /// the two differ in size, weight and fill, not just in shape.
  void _paintCross(Canvas canvas, Offset centre, double radius) {
    final paint = Paint()
      ..color = markGrey
      ..strokeWidth = math.max(1.6, radius * 0.26)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(centre.translate(-radius, -radius),
        centre.translate(radius, radius), paint);
    canvas.drawLine(centre.translate(radius, -radius),
        centre.translate(-radius, radius), paint);
  }

  @override
  bool shouldRepaint(StarBattlePainter oldDelegate) =>
      oldDelegate.isSolved != isSolved ||
      oldDelegate.puzzle != puzzle ||
      !_sameCells(oldDelegate.cells, cells);

  static bool _sameCells(List<CellState> a, List<CellState> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
