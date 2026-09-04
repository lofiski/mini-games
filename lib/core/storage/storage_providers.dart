import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_store.dart';

/// 由 main() 在启动时 override 注入具体实现。
final Provider<SettingsStore> settingsStoreProvider = Provider<SettingsStore>(
  (ref) =>
      throw StateError('settingsStoreProvider 必须在 ProviderScope 中被 override'),
);

/// 某款游戏的最高分。只在超过历史记录时才更新。
class HighScoreNotifier extends Notifier<int> {
  HighScoreNotifier(this.gameId);

  final String gameId;

  @override
  int build() => ref.read(settingsStoreProvider).highScore(gameId);

  /// 提交一局的得分，返回是否刷新了记录。
  bool submit(int score) {
    if (score <= state) return false;
    state = score;
    unawaited(ref.read(settingsStoreProvider).setHighScore(gameId, score));
    return true;
  }
}

final highScoreProvider =
    NotifierProvider.family<HighScoreNotifier, int, String>(
      HighScoreNotifier.new,
    );
