import 'package:meta/meta.dart';

import 'tile.dart';

@immutable
class Board2048 {
  const Board2048({required this.size, required this.tiles});

  factory Board2048.empty(int size) =>
      Board2048(size: size, tiles: const <Tile>[]);

  final int size;
  final List<Tile> tiles;

  Tile? tileAt(int row, int col) {
    for (final tile in tiles) {
      if (tile.row == row && tile.col == col) return tile;
    }
    return null;
  }

  bool get isFull => tiles.length == size * size;

  int get maxValue => tiles.isEmpty
      ? 0
      : tiles.map((t) => t.value).reduce((a, b) => a > b ? a : b);

  /// 全部空格的扁平下标（row * size + col）。
  List<int> get emptyIndices {
    final occupied = <int>{for (final t in tiles) t.row * size + t.col};
    return [
      for (var i = 0; i < size * size; i++)
        if (!occupied.contains(i)) i,
    ];
  }

  Board2048 withTile(Tile tile) =>
      Board2048(size: size, tiles: [...tiles, tile]);
}
