import 'package:meta/meta.dart';

import '../domain/board.dart';
import '../domain/tile.dart';

enum Game2048Status { playing, won, over }

@immutable
class Game2048State {
  const Game2048State({
    required this.board,
    required this.absorbed,
    required this.mergedIds,
    required this.score,
    required this.nextTileId,
    required this.status,
  });

  final Board2048 board;

  /// 上一次移动中被吞并的方块，画在合并结果之下，随下次状态更新消失。
  final List<Tile> absorbed;

  final Set<int> mergedIds;
  final int score;

  /// 下一个可用的方块 id。合并不消耗 id，只有新生成的方块才取用。
  final int nextTileId;

  final Game2048Status status;

  Game2048State copyWith({
    Board2048? board,
    List<Tile>? absorbed,
    Set<int>? mergedIds,
    int? score,
    int? nextTileId,
    Game2048Status? status,
  }) => Game2048State(
    board: board ?? this.board,
    absorbed: absorbed ?? this.absorbed,
    mergedIds: mergedIds ?? this.mergedIds,
    score: score ?? this.score,
    nextTileId: nextTileId ?? this.nextTileId,
    status: status ?? this.status,
  );
}
