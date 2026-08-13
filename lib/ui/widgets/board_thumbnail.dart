import 'package:flutter/material.dart';

import '../../engine/puzzles/star_battle/model.dart';
import '../game/play_grid.dart';
import '../painters/star_battle_painter.dart';
import '../theme/nodro_theme.dart';

/// A small picture of a puzzle's region layout.
///
/// Uses the real board painter with an empty grid rather than a second drawing
/// routine, so a thumbnail can never drift out of step with the board it
/// promises to show.
class BoardThumbnail extends StatelessWidget {
  const BoardThumbnail({
    super.key,
    required this.puzzle,
    required this.side,
  });

  final StarBattlePuzzle puzzle;
  final double side;

  @override
  Widget build(BuildContext context) {
    final palette = NodroPalette.of(context);
    return SizedBox(
      width: side,
      height: side,
      child: CustomPaint(
        painter: StarBattlePainter(
          grid: PlayGrid.empty(puzzle, AutoMarkLevel.off),
          palette: palette,
          blocked: const <int>{},
          conflicts: const <int>{},
          placeProgress: 1,
          placedCell: null,
          conflictProgress: 0,
          winProgress: 0,
        ),
      ),
    );
  }
}
