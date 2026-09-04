import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_providers.dart';
import '../../../core/audio/sfx.dart';
import '../../../core/haptics/haptics.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/board.dart';
import '../domain/move.dart';
import '../domain/tile.dart';
import '../game2048_definition.dart';
import 'game2048_state.dart';

const int kBoardSize = 4;
const int kWinValue = 2048;

class Game2048Notifier extends Notifier<Game2048State> {
  Game2048Notifier({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  Game2048State build() => _newGame();

  Game2048State _newGame() {
    var board = Board2048.empty(kBoardSize);
    var nextId = 1;
    for (var i = 0; i < 2; i++) {
      final spawned = _spawn(board, nextId);
      board = spawned.$1;
      nextId = spawned.$2;
    }
    return Game2048State(
      board: board,
      absorbed: const <Tile>[],
      mergedIds: const <int>{},
      score: 0,
      nextTileId: nextId,
      status: Game2048Status.playing,
    );
  }

  /// 在随机空格生成一个方块，返回新棋盘与下一个可用 id。
  (Board2048, int) _spawn(Board2048 board, int nextId) {
    final empties = board.emptyIndices;
    if (empties.isEmpty) return (board, nextId);
    final index = empties[_random.nextInt(empties.length)];
    final value = _random.nextDouble() < 0.9 ? 2 : 4;
    return (
      board.withTile(
        Tile(
          id: nextId,
          value: value,
          row: index ~/ board.size,
          col: index % board.size,
        ),
      ),
      nextId + 1,
    );
  }

  void swipe(SwipeDirection direction) {
    if (state.status == Game2048Status.over) return;

    final audio = ref.read(audioServiceProvider);
    final outcome = applyMove(state.board, direction);

    if (!outcome.moved) {
      audio.play(Sfx.invalid, volume: kVolumeNegative);
      return;
    }

    // 本次滑动内第 k 次合并逐级升调。同帧限流只会播放音高最高的那一次，
    // 因此多次合并听感是「一次更高的音」而不是一堆噪音。
    for (var k = 0; k < outcome.mergeCount; k++) {
      audio.play(Sfx.merge, comboIndex: k, volume: kVolumeReward);
    }
    if (outcome.mergeCount > 0) Haptics.light();

    final spawned = _spawn(outcome.board, state.nextTileId);
    final board = spawned.$1;
    final score = state.score + outcome.gainedScore;

    var status = state.status;
    if (status == Game2048Status.playing && board.maxValue >= kWinValue) {
      status = Game2048Status.won;
      audio.play(Sfx.win, volume: kVolumeWin);
      Haptics.medium();
    }
    if (!canMoveAnyDirection(board)) {
      status = Game2048Status.over;
      audio.play(Sfx.gameOver, volume: kVolumeUi);
    }

    ref.read(highScoreProvider(kGame2048Id).notifier).submit(score);

    state = Game2048State(
      board: board,
      absorbed: outcome.absorbed,
      mergedIds: outcome.mergedIds,
      score: score,
      nextTileId: spawned.$2,
      status: status,
    );
  }

  void restart() {
    state = _newGame();
  }

  @visibleForTesting
  void debugSetBoard(Board2048 board) {
    state = state.copyWith(
      board: board,
      absorbed: const <Tile>[],
      mergedIds: const <int>{},
      score: 0,
      nextTileId: 1000,
      status: Game2048Status.playing,
    );
  }
}

final game2048Provider = NotifierProvider<Game2048Notifier, Game2048State>(
  Game2048Notifier.new,
);
