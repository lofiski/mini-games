import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/games/tap_match/domain/match_grid.dart';

/// 从颜色矩阵构造网格，-1 表示空。id 按顺序分配。
MatchGrid gridOf(List<List<int>> rows) {
  final columns = rows.first.length;
  var id = 1;
  final cells = <MatchCell?>[];
  for (final row in rows) {
    for (final color in row) {
      cells.add(color < 0 ? null : MatchCell(id: id++, color: color));
    }
  }
  return MatchGrid(columns: columns, rows: rows.length, cells: cells);
}

/// 把网格还原为颜色矩阵，-1 表示空，便于断言。
List<List<int>> colorsOf(MatchGrid grid) => [
  for (var r = 0; r < grid.rows; r++)
    [for (var c = 0; c < grid.columns; c++) grid.at(r, c)?.color ?? -1],
];

void main() {
  test('孤立色块的连通块只有自己', () {
    final grid = gridOf([
      [0, 1],
      [1, 1],
    ]);

    expect(findGroup(grid, 0, 0), hasLength(1));
  });

  test('4-邻接同色连成一块', () {
    final grid = gridOf([
      [1, 1, 0],
      [1, 0, 0],
      [0, 0, 0],
    ]);

    expect(findGroup(grid, 0, 0), hasLength(3));
  });

  test('对角线不算连通', () {
    final grid = gridOf([
      [1, 0],
      [0, 1],
    ]);

    expect(findGroup(grid, 0, 0), hasLength(1));
  });

  test('空格不参与连通', () {
    final grid = gridOf([
      [1, -1, 1],
      [0, 0, 0],
      [0, 0, 0],
    ]);

    expect(findGroup(grid, 0, 0), hasLength(1));
    expect(findGroup(grid, 0, 1), isEmpty);
  });

  test('越界坐标返回空连通块', () {
    final grid = gridOf([
      [0, 0],
      [0, 0],
    ]);

    expect(findGroup(grid, -1, 0), isEmpty);
    expect(findGroup(grid, 0, 9), isEmpty);
  });

  test('计分公式为 n 乘以 n 减一', () {
    expect(scoreFor(2), 2);
    expect(scoreFor(3), 6);
    expect(scoreFor(10), 90);
  });

  test('存在可消连通块时 hasMoves 为真', () {
    expect(
      hasMoves(
        gridOf([
          [1, 1],
          [0, 2],
        ]),
      ),
      isTrue,
    );
  });

  test('无任何同色相邻时 hasMoves 为假', () {
    expect(
      hasMoves(
        gridOf([
          [0, 1],
          [1, 0],
        ]),
      ),
      isFalse,
    );
  });

  test('随机网格填满且颜色在取值范围内', () {
    final grid = randomGrid(
      columns: 10,
      rows: 14,
      colorCount: 5,
      random: Random(3),
    );

    expect(grid.cells.whereType<MatchCell>(), hasLength(140));
    for (final cell in grid.cells.whereType<MatchCell>()) {
      expect(cell.color, inInclusiveRange(0, 4));
    }
  });

  test('随机网格的色块 id 互不重复', () {
    final grid = randomGrid(
      columns: 10,
      rows: 14,
      colorCount: 5,
      random: Random(11),
    );

    final ids = grid.cells.whereType<MatchCell>().map((c) => c.id).toSet();
    expect(ids, hasLength(140));
  });

  test('随机网格开局一定有可消的块', () {
    for (var seed = 0; seed < 50; seed++) {
      final grid = randomGrid(
        columns: 10,
        rows: 14,
        colorCount: 5,
        random: Random(seed),
      );
      expect(hasMoves(grid), isTrue, reason: 'seed $seed 产生了开局死局');
    }
  });
}
