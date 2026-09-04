import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_providers.dart';
import '../../../core/audio/sfx.dart';
import '../../../core/haptics/haptics.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/puzzle.dart';
import '../domain/shuffle.dart';
import '../sliding_puzzle_definition.dart';
import 'sliding_puzzle_state.dart';

const int kPuzzleSize = 4;

class SlidingPuzzleNotifier extends Notifier<SlidingPuzzleState> {
  SlidingPuzzleNotifier({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  SlidingPuzzleState build() => _newGame();

  SlidingPuzzleState _newGame() => SlidingPuzzleState(
    puzzle: shufflePuzzle(size: kPuzzleSize, random: _random),
    moves: 0,
    solved: false,
    bestMoves: ref.read(settingsStoreProvider).highScore(kSlidingPuzzleId),
  );

  void tap(int index) {
    if (state.solved) return;

    final audio = ref.read(audioServiceProvider);
    final distance = state.puzzle.slideDistance(index);

    if (distance == 0) {
      audio.play(Sfx.invalid, volume: kVolumeNegative);
      return;
    }

    // 一次推动的方块越多，音高越高：整排滑动比单格移动更有分量。
    audio.play(Sfx.slide, comboIndex: distance - 1, volume: kVolumeUi);
    Haptics.selection();

    final next = state.puzzle.tap(index);
    final moves = state.moves + 1;
    final solved = next.isSolved;
    var bestMoves = state.bestMoves;

    if (solved) {
      audio.play(Sfx.win, volume: kVolumeWin);
      Haptics.medium();
      bestMoves = _recordBestMoves(moves);
    }

    state = SlidingPuzzleState(
      puzzle: next,
      moves: moves,
      solved: solved,
      bestMoves: bestMoves,
    );
  }

  /// 本游戏的「最佳」是最少步数，因此只在更小时才写入。返回写入后的记录值。
  int _recordBestMoves(int moves) {
    final store = ref.read(settingsStoreProvider);
    final best = store.highScore(kSlidingPuzzleId);
    if (best == 0 || moves < best) {
      unawaited(store.setHighScore(kSlidingPuzzleId, moves));
      return moves;
    }
    return best;
  }

  void restart() {
    state = _newGame();
  }

  @visibleForTesting
  void debugSetPuzzle(Puzzle puzzle) {
    state = SlidingPuzzleState(
      puzzle: puzzle,
      moves: 0,
      solved: false,
      bestMoves: ref.read(settingsStoreProvider).highScore(kSlidingPuzzleId),
    );
  }
}

final slidingPuzzleProvider =
    NotifierProvider<SlidingPuzzleNotifier, SlidingPuzzleState>(
      SlidingPuzzleNotifier.new,
    );
