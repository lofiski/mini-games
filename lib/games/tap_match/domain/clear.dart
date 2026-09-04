import 'package:meta/meta.dart';

import 'match_grid.dart';

@immutable
class ClearOutcome {
  const ClearOutcome({
    required this.grid,
    required this.clearedIndices,
    required this.gainedScore,
    required this.valid,
  });

  final MatchGrid grid;

  /// 被消除的色块在消除前的扁平索引。
  final List<int> clearedIndices;

  final int gainedScore;

  /// 连通块大小不足 2 或点击空位时为 false，此时 [grid] 与输入相同。
  final bool valid;
}

/// 消除 (row, col) 所在的同色连通块，随后下落并压缩空列。
ClearOutcome clearAt(MatchGrid grid, int row, int col) {
  final group = findGroup(grid, row, col);
  if (group.length < 2) {
    return ClearOutcome(
      grid: grid,
      clearedIndices: const <int>[],
      gainedScore: 0,
      valid: false,
    );
  }

  final removed = group.toSet();
  final remaining = <MatchCell?>[
    for (var i = 0; i < grid.cells.length; i++)
      if (removed.contains(i)) null else grid.cells[i],
  ];

  final collapsed = _collapse(
    MatchGrid(columns: grid.columns, rows: grid.rows, cells: remaining),
  );

  return ClearOutcome(
    grid: collapsed,
    clearedIndices: group,
    gainedScore: scoreFor(group.length),
    valid: true,
  );
}

/// 先让每列内的色块落到底部，再把空列整体向左压缩。
MatchGrid _collapse(MatchGrid grid) {
  final columns = <List<MatchCell>>[];
  for (var c = 0; c < grid.columns; c++) {
    final column = <MatchCell>[];
    for (var r = 0; r < grid.rows; r++) {
      final cell = grid.at(r, c);
      if (cell != null) column.add(cell);
    }
    if (column.isNotEmpty) columns.add(column);
  }

  final cells = List<MatchCell?>.filled(grid.rows * grid.columns, null);
  for (var c = 0; c < columns.length; c++) {
    final column = columns[c];
    // column 是自上而下收集的，底部对齐后相对顺序保持不变
    for (var i = 0; i < column.length; i++) {
      final r = grid.rows - column.length + i;
      cells[r * grid.columns + c] = column[i];
    }
  }

  return MatchGrid(columns: grid.columns, rows: grid.rows, cells: cells);
}
