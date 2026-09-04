import 'dart:math';

import 'package:meta/meta.dart';

/// 网格中的一个色块。[id] 在整个生命周期内稳定，UI 依据它做下落动画。
@immutable
class MatchCell {
  const MatchCell({required this.id, required this.color});

  final int id;
  final int color;
}

/// 消消乐网格。
///
/// [cells] 按行主序存放，索引为 `row * columns + col`；
/// `row == 0` 是顶部，重力方向为 row 增大的方向；null 表示空位。
@immutable
class MatchGrid {
  const MatchGrid({
    required this.columns,
    required this.rows,
    required this.cells,
  });

  final int columns;
  final int rows;
  final List<MatchCell?> cells;

  int indexOf(int row, int col) => row * columns + col;

  MatchCell? at(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= columns) return null;
    return cells[indexOf(row, col)];
  }
}

/// 生成一个填满的随机网格。若开局即为死局则重新生成。
MatchGrid randomGrid({
  required int columns,
  required int rows,
  required int colorCount,
  required Random random,
}) {
  var nextId = 1;
  while (true) {
    final cells = <MatchCell?>[
      for (var i = 0; i < columns * rows; i++)
        MatchCell(id: nextId++, color: random.nextInt(colorCount)),
    ];
    final grid = MatchGrid(columns: columns, rows: rows, cells: cells);
    if (hasMoves(grid)) return grid;
  }
}

/// 从 (row, col) 出发的 4-邻接同色连通块，返回扁平索引集合。
/// 点击空位或越界坐标时返回空列表。
List<int> findGroup(MatchGrid grid, int row, int col) {
  final origin = grid.at(row, col);
  if (origin == null) return const <int>[];

  final color = origin.color;
  final visited = <int>{};
  final stack = <int>[grid.indexOf(row, col)];

  while (stack.isNotEmpty) {
    final index = stack.removeLast();
    if (!visited.add(index)) continue;
    final r = index ~/ grid.columns;
    final c = index % grid.columns;
    for (final (nr, nc) in <(int, int)>[
      (r - 1, c),
      (r + 1, c),
      (r, c - 1),
      (r, c + 1),
    ]) {
      final neighbour = grid.at(nr, nc);
      if (neighbour != null && neighbour.color == color) {
        final neighbourIndex = grid.indexOf(nr, nc);
        if (!visited.contains(neighbourIndex)) stack.add(neighbourIndex);
      }
    }
  }

  return visited.toList(growable: false);
}

/// 消除 n 块的得分。n 越大收益越陡，鼓励攒大块。
int scoreFor(int count) => count * (count - 1);

/// 是否还存在任何大小不小于 2 的同色连通块。
bool hasMoves(MatchGrid grid) {
  for (var r = 0; r < grid.rows; r++) {
    for (var c = 0; c < grid.columns; c++) {
      final cell = grid.at(r, c);
      if (cell == null) continue;
      final right = grid.at(r, c + 1);
      if (right != null && right.color == cell.color) return true;
      final below = grid.at(r + 1, c);
      if (below != null && below.color == cell.color) return true;
    }
  }
  return false;
}
