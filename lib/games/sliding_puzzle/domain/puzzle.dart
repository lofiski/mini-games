import 'package:meta/meta.dart';

/// 数字华容道棋盘。
///
/// [tiles] 长度为 size*size，按行主序存放；0 表示空格。
@immutable
class Puzzle {
  const Puzzle({required this.size, required this.tiles});

  factory Puzzle.solved(int size) =>
      Puzzle(size: size, tiles: [for (var i = 1; i < size * size; i++) i, 0]);

  final int size;
  final List<int> tiles;

  int get blankIndex => tiles.indexOf(0);

  bool get isSolved {
    for (var i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return tiles.last == 0;
  }

  /// 与空格同行或同列的方块可点击（空格自身除外）。
  ///
  /// 允许点击整排而非仅紧邻空格的方块，操作效率显著更高。
  bool canTap(int index) => slideDistance(index) > 0;

  /// 点击该位置会带动多少个方块移动。不可点击或下标越界时为 0。
  int slideDistance(int index) {
    if (index < 0 || index >= tiles.length) return 0;
    if (tiles[index] == 0) return 0;
    final blank = blankIndex;
    final row = index ~/ size;
    final col = index % size;
    final blankRow = blank ~/ size;
    final blankCol = blank % size;
    if (row == blankRow) return (col - blankCol).abs();
    if (col == blankCol) return (row - blankRow).abs();
    return 0;
  }

  /// 把点击位置到空格之间的整排方块朝空格方向推进一格。
  Puzzle tap(int index) {
    if (!canTap(index)) return this;

    final next = List<int>.of(tiles);
    final blank = blankIndex;
    final row = index ~/ size;
    final col = index % size;
    final blankRow = blank ~/ size;
    final blankCol = blank % size;

    if (row == blankRow) {
      final step = col < blankCol ? 1 : -1;
      for (var x = blankCol; x != col; x -= step) {
        next[row * size + x] = next[row * size + (x - step)];
      }
    } else {
      final step = row < blankRow ? 1 : -1;
      for (var y = blankRow; y != row; y -= step) {
        next[y * size + col] = next[(y - step) * size + col];
      }
    }
    next[index] = 0;

    return Puzzle(size: size, tiles: next);
  }
}
