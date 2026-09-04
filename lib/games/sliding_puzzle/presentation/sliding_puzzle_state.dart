import 'package:meta/meta.dart';

import '../domain/puzzle.dart';

@immutable
class SlidingPuzzleState {
  const SlidingPuzzleState({
    required this.puzzle,
    required this.moves,
    required this.solved,
    required this.bestMoves,
  });

  final Puzzle puzzle;
  final int moves;
  final bool solved;

  /// 历史最少步数，0 表示尚无记录。
  ///
  /// 放在 state 里而非独立 Provider：SettingsStore 是可变对象且不通知
  /// Riverpod，用 Provider 包装它会导致赢下一局后界面不刷新。
  final int bestMoves;
}
