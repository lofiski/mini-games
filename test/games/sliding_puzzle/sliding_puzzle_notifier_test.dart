import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/core/audio/audio_providers.dart';
import 'package:mini_games/core/audio/audio_service.dart';
import 'package:mini_games/core/audio/sfx.dart';
import 'package:mini_games/core/storage/settings_store.dart';
import 'package:mini_games/core/storage/storage_providers.dart';
import 'package:mini_games/games/sliding_puzzle/domain/puzzle.dart';
import 'package:mini_games/games/sliding_puzzle/presentation/sliding_puzzle_notifier.dart';
import 'package:mini_games/games/sliding_puzzle/sliding_puzzle_definition.dart';

ProviderContainer _container(SilentAudioService audio, SettingsStore store) {
  final container = ProviderContainer(
    overrides: [
      settingsStoreProvider.overrideWithValue(store),
      audioServiceProvider.overrideWithValue(audio),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// 差一步即可完成：空格在 (3,2)，点击 (3,3) 处的 15 即还原。
const Puzzle _oneMoveFromSolved = Puzzle(
  size: 4,
  tiles: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 0, 15],
);

void main() {
  test('开局是打乱且未完成的局面，步数为 0', () {
    final container = _container(SilentAudioService(), InMemorySettingsStore());

    final state = container.read(slidingPuzzleProvider);

    expect(state.solved, isFalse);
    expect(state.puzzle.isSolved, isFalse);
    expect(state.moves, 0);
  });

  test('有效点击增加步数并播放 slide 音效', () {
    final audio = SilentAudioService();
    final container = _container(audio, InMemorySettingsStore());
    final notifier = container.read(slidingPuzzleProvider.notifier);
    final movable = List.generate(
      16,
      (i) => i,
    ).firstWhere(container.read(slidingPuzzleProvider).puzzle.canTap);
    audio.played.clear();

    notifier.tap(movable);

    expect(container.read(slidingPuzzleProvider).moves, 1);
    expect(audio.played, contains(Sfx.slide));
  });

  test('无效点击播放 invalid 音效且步数不变', () {
    final audio = SilentAudioService();
    final container = _container(audio, InMemorySettingsStore());
    final notifier = container.read(slidingPuzzleProvider.notifier);
    final blank = container.read(slidingPuzzleProvider).puzzle.blankIndex;
    audio.played.clear();

    notifier.tap(blank);

    expect(container.read(slidingPuzzleProvider).moves, 0);
    expect(audio.played, contains(Sfx.invalid));
  });

  test('还原成功时标记完成并播放 win 音效', () {
    final audio = SilentAudioService();
    final container = _container(audio, InMemorySettingsStore());
    final notifier = container.read(slidingPuzzleProvider.notifier)
      ..debugSetPuzzle(_oneMoveFromSolved);
    audio.played.clear();

    notifier.tap(15);

    expect(container.read(slidingPuzzleProvider).solved, isTrue);
    expect(audio.played, contains(Sfx.win));
  });

  test('完成后记录最少步数，更少的成绩才覆盖', () async {
    final store = InMemorySettingsStore();
    await store.setHighScore(kSlidingPuzzleId, 10);
    final container = _container(SilentAudioService(), store);

    container.read(slidingPuzzleProvider.notifier)
      ..debugSetPuzzle(_oneMoveFromSolved)
      ..tap(15);

    expect(store.highScore(kSlidingPuzzleId), 1);
    expect(container.read(slidingPuzzleProvider).bestMoves, 1);
  });

  test('已有更好成绩时不被更差的成绩覆盖', () async {
    final store = InMemorySettingsStore();
    await store.setHighScore(kSlidingPuzzleId, 1);
    final container = _container(SilentAudioService(), store);

    container.read(slidingPuzzleProvider.notifier)
      ..debugSetPuzzle(_oneMoveFromSolved)
      ..tap(15);

    expect(store.highScore(kSlidingPuzzleId), 1);
  });

  test('完成后再点击不产生变化', () {
    final container = _container(SilentAudioService(), InMemorySettingsStore());
    final notifier = container.read(slidingPuzzleProvider.notifier)
      ..debugSetPuzzle(_oneMoveFromSolved)
      ..tap(15);

    notifier.tap(14);

    expect(container.read(slidingPuzzleProvider).moves, 1);
  });

  test('重开后步数归零且局面未完成', () {
    final container = _container(SilentAudioService(), InMemorySettingsStore());

    container.read(slidingPuzzleProvider.notifier).restart();

    final state = container.read(slidingPuzzleProvider);
    expect(state.moves, 0);
    expect(state.solved, isFalse);
  });
}
