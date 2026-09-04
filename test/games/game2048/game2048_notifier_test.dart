import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/core/audio/audio_providers.dart';
import 'package:mini_games/core/audio/audio_service.dart';
import 'package:mini_games/core/audio/sfx.dart';
import 'package:mini_games/core/storage/settings_store.dart';
import 'package:mini_games/core/storage/storage_providers.dart';
import 'package:mini_games/games/game2048/domain/board.dart';
import 'package:mini_games/games/game2048/domain/move.dart';
import 'package:mini_games/games/game2048/domain/tile.dart';
import 'package:mini_games/games/game2048/game2048_definition.dart';
import 'package:mini_games/games/game2048/presentation/game2048_notifier.dart';
import 'package:mini_games/games/game2048/presentation/game2048_state.dart';

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

/// 左滑可合并的两格局面。
const Board2048 _mergeableBoard = Board2048(
  size: 4,
  tiles: [
    Tile(id: 1, value: 2, row: 0, col: 0),
    Tile(id: 2, value: 2, row: 0, col: 1),
  ],
);

void main() {
  test('新开局有两个方块', () {
    final container = _container(SilentAudioService());

    final state = container.read(game2048Provider);

    expect(state.board.tiles, hasLength(2));
    expect(state.score, 0);
    expect(state.status, Game2048Status.playing);
  });

  test('无效滑动播放 invalid 音效且不改变分数', () {
    final audio = SilentAudioService();
    final container = _container(audio);
    final notifier = container.read(game2048Provider.notifier);

    // 造一个左滑不动的局面
    notifier.debugSetBoard(
      const Board2048(
        size: 4,
        tiles: [
          Tile(id: 1, value: 2, row: 0, col: 0),
          Tile(id: 2, value: 4, row: 0, col: 1),
        ],
      ),
    );
    audio.played.clear();

    notifier.swipe(SwipeDirection.left);

    expect(audio.played, contains(Sfx.invalid));
    expect(container.read(game2048Provider).score, 0);
  });

  test('有效合并加分、播放 merge 音效并生成新方块', () {
    final audio = SilentAudioService();
    final container = _container(audio);
    final notifier = container.read(game2048Provider.notifier)
      ..debugSetBoard(_mergeableBoard);
    audio.played.clear();

    notifier.swipe(SwipeDirection.left);
    final state = container.read(game2048Provider);

    expect(state.score, 4);
    expect(audio.played, contains(Sfx.merge));
    // 一个合并结果 + 一个新生成的方块
    expect(state.board.tiles, hasLength(2));
  });

  test('刷新最高分', () {
    final container = _container(SilentAudioService());
    container.read(game2048Provider.notifier)
      ..debugSetBoard(_mergeableBoard)
      ..swipe(SwipeDirection.left);

    expect(container.read(highScoreProvider(kGame2048Id)), 4);
  });

  test('重开清零分数并回到两个方块', () {
    final container = _container(SilentAudioService());
    container.read(game2048Provider.notifier)
      ..debugSetBoard(_mergeableBoard)
      ..swipe(SwipeDirection.left)
      ..restart();

    final state = container.read(game2048Provider);
    expect(state.score, 0);
    expect(state.board.tiles, hasLength(2));
    expect(state.status, Game2048Status.playing);
  });
}
