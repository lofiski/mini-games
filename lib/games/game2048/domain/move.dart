import 'package:meta/meta.dart';

import 'board.dart';
import 'tile.dart';

enum SwipeDirection { up, down, left, right }

@immutable
class MoveOutcome {
  const MoveOutcome({
    required this.board,
    required this.absorbed,
    required this.mergedIds,
    required this.gainedScore,
    required this.mergeCount,
    required this.moved,
  });

  /// 移动并合并后的棋盘，尚未生成新方块。
  final Board2048 board;

  /// 被吞并的旧方块，位置已更新到目标格。
  /// UI 把它们画在合并结果之下，滑动动画因此不会出现方块凭空消失。
  final List<Tile> absorbed;

  /// [board] 中由合并产生的方块 id，UI 据此播放放大回弹。
  final Set<int> mergedIds;

  final int gainedScore;
  final int mergeCount;
  final bool moved;
}

/// 沿 [direction] 执行一次移动。
///
/// 关键规则：单次移动中，已经参与过合并的方块不得再次参与合并。
/// 实现方式是合并后把游标直接前进两格（`i += 2`）。
MoveOutcome applyMove(Board2048 board, SwipeDirection direction) {
  final size = board.size;
  final result = <Tile>[];
  final absorbed = <Tile>[];
  final mergedIds = <int>{};
  var gainedScore = 0;
  var mergeCount = 0;
  var moved = false;

  final horizontal =
      direction == SwipeDirection.left || direction == SwipeDirection.right;
  final towardStart =
      direction == SwipeDirection.left || direction == SwipeDirection.up;

  for (var line = 0; line < size; line++) {
    // 沿移动方向收集本行/列的方块：最先抵达目标边的排在最前。
    final lineTiles = <Tile>[];
    for (var step = 0; step < size; step++) {
      final index = towardStart ? step : size - 1 - step;
      final tile = horizontal
          ? board.tileAt(line, index)
          : board.tileAt(index, line);
      if (tile != null) lineTiles.add(tile);
    }

    var cursor = 0;
    var i = 0;
    while (i < lineTiles.length) {
      final current = lineTiles[i];
      final canMerge =
          i + 1 < lineTiles.length && lineTiles[i + 1].value == current.value;

      final targetIndex = towardStart ? cursor : size - 1 - cursor;
      final targetRow = horizontal ? line : targetIndex;
      final targetCol = horizontal ? targetIndex : line;

      if (canMerge) {
        final partner = lineTiles[i + 1];
        final mergedValue = current.value * 2;
        result.add(
          Tile(
            id: current.id,
            value: mergedValue,
            row: targetRow,
            col: targetCol,
          ),
        );
        absorbed.add(partner.copyWith(row: targetRow, col: targetCol));
        mergedIds.add(current.id);
        gainedScore += mergedValue;
        mergeCount++;
        moved = true;
        i += 2; // 已合并的方块本次不再参与合并
      } else {
        result.add(current.copyWith(row: targetRow, col: targetCol));
        if (current.row != targetRow || current.col != targetCol) moved = true;
        i += 1;
      }
      cursor++;
    }
  }

  if (!moved) {
    return MoveOutcome(
      board: board,
      absorbed: const <Tile>[],
      mergedIds: const <int>{},
      gainedScore: 0,
      mergeCount: 0,
      moved: false,
    );
  }

  return MoveOutcome(
    board: Board2048(size: size, tiles: result),
    absorbed: absorbed,
    mergedIds: mergedIds,
    gainedScore: gainedScore,
    mergeCount: mergeCount,
    moved: true,
  );
}

/// 是否还存在任何可行的移动。四个方向都试一遍。
bool canMoveAnyDirection(Board2048 board) {
  for (final direction in SwipeDirection.values) {
    if (applyMove(board, direction).moved) return true;
  }
  return false;
}
