import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/core/storage/settings_store.dart';

void main() {
  test('未记录过的游戏最高分为 0', () {
    expect(InMemorySettingsStore().highScore('game2048'), 0);
  });

  test('写入后能读回最高分', () async {
    final store = InMemorySettingsStore();
    await store.setHighScore('game2048', 1024);
    expect(store.highScore('game2048'), 1024);
  });

  test('不同游戏的最高分互不干扰', () async {
    final store = InMemorySettingsStore();
    await store.setHighScore('game2048', 1024);
    await store.setHighScore('tap_match', 300);
    expect(store.highScore('game2048'), 1024);
    expect(store.highScore('tap_match'), 300);
  });

  test('静音开关默认关闭且可切换', () async {
    final store = InMemorySettingsStore();
    expect(store.muted, isFalse);
    await store.setMuted(true);
    expect(store.muted, isTrue);
  });
}
