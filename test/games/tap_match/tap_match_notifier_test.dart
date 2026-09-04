import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/core/audio/audio_providers.dart';
import 'package:mini_games/core/audio/audio_service.dart';
import 'package:mini_games/core/audio/sfx.dart';
import 'package:mini_games/core/storage/settings_store.dart';
import 'package:mini_games/core/storage/storage_providers.dart';
import 'package:mini_games/games/tap_match/presentation/tap_match_notifier.dart';
import 'package:mini_games/games/tap_match/tap_match_definition.dart';

import 'match_grid_test.dart' show gridOf;

ProviderContainer _container(SilentAudioService audio) {
  final container = ProviderContainer(
    overrides: [
      settingsStoreProvider.overrideWithValue(InMemorySettingsStore()),
      audioServiceProvider.overrideWithValue(audio),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('开局有分数为 0 的可玩局面', () {
    final container = _container(SilentAudioService());

    final state = container.read(tapMatchProvider);

    expect(state.score, 0);
    expect(state.over, isFalse);
  });

  test('消除成功时加分并播放 pop 音效', () {
    final audio = SilentAudioService();
    final container = _container(audio);
    final notifier = container.read(tapMatchProvider.notifier)
      ..debugSetGrid(
        gridOf([
          [0, 0, 1],
          [2, 3, 4],
          [5, 6, 7],
        ]),
      );
    audio.played.clear();

    notifier.tapCell(0, 0);

    expect(container.read(tapMatchProvider).score, 2);
    expect(audio.played, contains(Sfx.pop));
  });

  test('点击单块播放 invalid 音效且不加分', () {
    final audio = SilentAudioService();
    final container = _container(audio);
    final notifier = container.read(tapMatchProvider.notifier)
      ..debugSetGrid(
        gridOf([
          [0, 1, 2],
          [3, 4, 5],
          [6, 7, 8],
        ]),
      );
    audio.played.clear();

    notifier.tapCell(0, 0);

    expect(container.read(tapMatchProvider).score, 0);
    expect(audio.played, contains(Sfx.invalid));
  });

  test('消到死局时标记结束并播放 gameOver 音效', () {
    final audio = SilentAudioService();
    final container = _container(audio);
    final notifier = container.read(tapMatchProvider.notifier)
      // 消掉这一对之后棋盘为空，不存在任何可消块
      ..debugSetGrid(
        gridOf([
          [0],
          [0],
        ]),
      );
    audio.played.clear();

    notifier.tapCell(0, 0);

    expect(container.read(tapMatchProvider).over, isTrue);
    expect(audio.played, contains(Sfx.gameOver));
  });

  test('结束后再点击不产生变化', () {
    final container = _container(SilentAudioService());
    final notifier = container.read(tapMatchProvider.notifier)
      ..debugSetGrid(
        gridOf([
          [0],
          [0],
        ]),
      )
      ..tapCell(0, 0);
    final scoreAfterEnd = container.read(tapMatchProvider).score;

    notifier.tapCell(0, 0);

    expect(container.read(tapMatchProvider).score, scoreAfterEnd);
  });

  test('刷新最高分', () {
    final container = _container(SilentAudioService());
    container.read(tapMatchProvider.notifier)
      ..debugSetGrid(
        gridOf([
          [0, 0, 1],
          [2, 3, 4],
          [5, 6, 7],
        ]),
      )
      ..tapCell(0, 0);

    expect(container.read(highScoreProvider(kTapMatchId)), 2);
  });

  test('重开清零分数', () {
    final container = _container(SilentAudioService());
    container.read(tapMatchProvider.notifier)
      ..debugSetGrid(
        gridOf([
          [0, 0, 1],
          [2, 3, 4],
          [5, 6, 7],
        ]),
      )
      ..tapCell(0, 0)
      ..restart();

    expect(container.read(tapMatchProvider).score, 0);
    expect(container.read(tapMatchProvider).over, isFalse);
  });
}
