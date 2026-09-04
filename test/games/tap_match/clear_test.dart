import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/games/tap_match/domain/clear.dart';
import 'package:mini_games/games/tap_match/domain/match_grid.dart';

import 'match_grid_test.dart' show colorsOf, gridOf;

void main() {
  test('单个色块不可消除，网格保持不变', () {
    final grid = gridOf([
      [0, 1],
      [1, 1],
    ]);

    final outcome = clearAt(grid, 0, 0);

    expect(outcome.valid, isFalse);
    expect(outcome.gainedScore, 0);
    expect(colorsOf(outcome.grid), colorsOf(grid));
  });

  test('两块及以上可消除并计分', () {
    final grid = gridOf([
      [0, 0],
      [1, 2],
    ]);

    final outcome = clearAt(grid, 0, 0);

    expect(outcome.valid, isTrue);
    expect(outcome.clearedIndices, hasLength(2));
    expect(outcome.gainedScore, 2);
  });

  test('消除后上方色块下落填补', () {
    final grid = gridOf([
      [2, 9],
      [0, 9],
      [0, 9],
    ]);

    final outcome = clearAt(grid, 1, 0);

    // 第 0 列原本自上而下是 2、0、0，消掉两个 0 后 2 落到底部
    expect(colorsOf(outcome.grid).map((r) => r[0]).toList(), [-1, -1, 2]);
  });

  test('整列被清空后右侧列向左压缩', () {
    final grid = gridOf([
      [0, 1, 2],
      [0, 1, 2],
    ]);

    final outcome = clearAt(grid, 0, 0);

    // 第 0 列清空，原第 1、2 列左移
    expect(colorsOf(outcome.grid), [
      [1, 2, -1],
      [1, 2, -1],
    ]);
  });

  test('点击空格不产生任何变化', () {
    final grid = gridOf([
      [-1, 1],
      [1, 1],
    ]);

    final outcome = clearAt(grid, 0, 0);

    expect(outcome.valid, isFalse);
    expect(colorsOf(outcome.grid), colorsOf(grid));
  });

  test('消除不会丢失未参与消除的色块身份', () {
    final grid = gridOf([
      [0, 5],
      [0, 6],
    ]);
    final survivorIds = grid.cells
        .whereType<MatchCell>()
        .where((c) => c.color != 0)
        .map((c) => c.id)
        .toSet();

    final outcome = clearAt(grid, 0, 0);

    final remainingIds = outcome.grid.cells
        .whereType<MatchCell>()
        .map((c) => c.id)
        .toSet();
    expect(remainingIds, survivorIds);
  });

  test('下落保持同列色块的上下相对顺序', () {
    final grid = gridOf([
      [7, 9],
      [8, 9],
      [0, 9],
      [0, 9],
    ]);

    final outcome = clearAt(grid, 2, 0);

    // 消掉底部两个 0 后，7 在上、8 在下的相对顺序不变
    expect(colorsOf(outcome.grid).map((r) => r[0]).toList(), [-1, -1, 7, 8]);
  });
}
