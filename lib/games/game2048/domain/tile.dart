import 'package:meta/meta.dart';

/// 棋盘上的一个方块。
///
/// [id] 在方块的整个生命周期内保持稳定，UI 依据它做位移动画；
/// 合并时结果方块沿用参与合并的旧 id，因此动画不会跳变。
@immutable
class Tile {
  const Tile({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
  });

  final int id;
  final int value;
  final int row;
  final int col;

  Tile copyWith({int? value, int? row, int? col}) => Tile(
    id: id,
    value: value ?? this.value,
    row: row ?? this.row,
    col: col ?? this.col,
  );

  @override
  String toString() => 'Tile(id: $id, value: $value, row: $row, col: $col)';
}
