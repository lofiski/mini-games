import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_providers.dart';
import '../../../core/audio/sfx.dart';
import '../../../core/haptics/haptics.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/clear.dart';
import '../domain/match_grid.dart';
import '../tap_match_definition.dart';
import 'tap_match_state.dart';

const int kMatchColumns = 10;
const int kMatchRows = 14;
const int kMatchColors = 5;

class TapMatchNotifier extends Notifier<TapMatchState> {
  TapMatchNotifier({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  TapMatchState build() => _newGame();

  TapMatchState _newGame() => TapMatchState(
    grid: randomGrid(
      columns: kMatchColumns,
      rows: kMatchRows,
      colorCount: kMatchColors,
      random: _random,
    ),
    score: 0,
    over: false,
  );

  void tapCell(int row, int col) {
    if (state.over) return;

    final audio = ref.read(audioServiceProvider);
    final outcome = clearAt(state.grid, row, col);

    if (!outcome.valid) {
      audio.play(Sfx.invalid, volume: kVolumeNegative);
      return;
    }

    // 起始音高由本次消除的块数决定：消 2 块是基准音，消一大片直接起高音。
    // 这是三款游戏里最能体现「越猛越爽」的一处。
    final comboIndex = outcome.clearedIndices.length - 2;
    audio.play(Sfx.pop, comboIndex: comboIndex, volume: kVolumeReward);
    Haptics.light();

    final score = state.score + outcome.gainedScore;
    final over = !hasMoves(outcome.grid);

    if (over) {
      audio.play(Sfx.gameOver, volume: kVolumeUi);
    }

    ref.read(highScoreProvider(kTapMatchId).notifier).submit(score);

    state = TapMatchState(grid: outcome.grid, score: score, over: over);
  }

  void restart() {
    state = _newGame();
  }

  @visibleForTesting
  void debugSetGrid(MatchGrid grid) {
    state = TapMatchState(grid: grid, score: 0, over: false);
  }
}

final tapMatchProvider = NotifierProvider<TapMatchNotifier, TapMatchState>(
  TapMatchNotifier.new,
);
