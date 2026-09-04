import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/games/game2048/domain/board.dart';
import 'package:mini_games/games/game2048/domain/move.dart';
import 'package:mini_games/games/game2048/domain/tile.dart';

/// 从二维数值构造棋盘，0 表示空格。id 按顺序分配。
Board2048 boardOf(List<List<int>> rows) {
  final tiles = <Tile>[];
  var id = 1;
  for (var r = 0; r < rows.length; r++) {
    for (var c = 0; c < rows[r].length; c++) {
      if (rows[r][c] != 0) {
        tiles.add(Tile(id: id++, value: rows[r][c], row: r, col: c));
      }
    }
  }
  return Board2048(size: rows.length, tiles: tiles);
}

/// 把棋盘还原为二维数值，便于断言。
List<List<int>> valuesOf(Board2048 board) {
  final grid = List.generate(
    board.size,
    (_) => List<int>.filled(board.size, 0),
    growable: false,
  );
  for (final tile in board.tiles) {
    grid[tile.row][tile.col] = tile.value;
  }
  return grid;
}

void main() {
  test('相同数字向左合并为两倍', () {
    final outcome = applyMove(
      boardOf([
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.left,
    );

    expect(valuesOf(outcome.board)[0], [4, 0, 0, 0]);
    expect(outcome.gainedScore, 4);
    expect(outcome.mergeCount, 1);
    expect(outcome.moved, isTrue);
  });

  test('单次移动中已合并的方块不再二次合并', () {
    final outcome = applyMove(
      boardOf([
        [2, 2, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.left,
    );

    expect(valuesOf(outcome.board)[0], [4, 4, 0, 0]);
    expect(outcome.mergeCount, 2);
    expect(outcome.gainedScore, 8);
  });

  test('相邻不同值只滑动不合并', () {
    final outcome = applyMove(
      boardOf([
        [4, 4, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.left,
    );

    expect(valuesOf(outcome.board)[0], [8, 4, 0, 0]);
    expect(outcome.gainedScore, 12);
  });

  test('跨越空格也能合并', () {
    final outcome = applyMove(
      boardOf([
        [2, 0, 0, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.left,
    );

    expect(valuesOf(outcome.board)[0], [4, 0, 0, 0]);
  });

  test('向右合并时靠右的一对优先', () {
    final outcome = applyMove(
      boardOf([
        [2, 2, 2, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.right,
    );

    expect(valuesOf(outcome.board)[0], [0, 0, 2, 4]);
  });

  test('向上合并按列处理', () {
    final outcome = applyMove(
      boardOf([
        [2, 0, 0, 0],
        [2, 0, 0, 0],
        [4, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.up,
    );

    expect(valuesOf(outcome.board).map((r) => r[0]).toList(), [4, 4, 0, 0]);
  });

  test('向下合并按列处理', () {
    final outcome = applyMove(
      boardOf([
        [4, 0, 0, 0],
        [2, 0, 0, 0],
        [2, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.down,
    );

    expect(valuesOf(outcome.board).map((r) => r[0]).toList(), [0, 0, 4, 4]);
  });

  test('无法移动时 moved 为 false 且棋盘不变', () {
    final board = boardOf([
      [2, 4, 2, 4],
      [4, 2, 4, 2],
      [2, 4, 2, 4],
      [4, 2, 4, 2],
    ]);

    final outcome = applyMove(board, SwipeDirection.left);

    expect(outcome.moved, isFalse);
    expect(valuesOf(outcome.board), valuesOf(board));
    expect(outcome.gainedScore, 0);
  });

  test('合并后的方块沿用参与合并的旧 id，保证动画连续', () {
    final board = boardOf([
      [2, 2, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    final oldIds = board.tiles.map((t) => t.id).toSet();

    final outcome = applyMove(board, SwipeDirection.left);

    expect(oldIds.contains(outcome.board.tiles.single.id), isTrue);
    expect(outcome.mergedIds, {outcome.board.tiles.single.id});
  });

  test('被吞并的方块出现在 absorbed 中且已移动到目标格', () {
    final outcome = applyMove(
      boardOf([
        [2, 0, 0, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.left,
    );

    expect(outcome.absorbed, hasLength(1));
    expect(outcome.absorbed.single.col, 0);
    expect(outcome.absorbed.single.value, 2);
  });

  test('没有方块凭空消失：结果加被吞并数等于原方块数', () {
    final board = boardOf([
      [2, 2, 4, 4],
      [8, 8, 2, 2],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);

    final outcome = applyMove(board, SwipeDirection.left);

    expect(
      outcome.board.tiles.length + outcome.absorbed.length,
      board.tiles.length,
    );
  });
}
