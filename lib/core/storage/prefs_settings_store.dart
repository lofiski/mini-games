import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_store.dart';

/// shared_preferences 后端。
///
/// 任何读写失败都降级处理，绝不向上抛出：
/// 存档丢失可以接受，游戏崩溃不可以。
class PrefsSettingsStore implements SettingsStore {
  PrefsSettingsStore._(this._prefs, this._scores, this._muted);

  static const String _mutedKey = 'settings.muted';
  static const String _scorePrefix = 'highscore.';

  final SharedPreferences _prefs;
  final Map<String, int> _scores;
  bool _muted;

  /// 载入全部设置。失败时回退到内存实现，调用方无需处理异常。
  static Future<SettingsStore> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scores = <String, int>{};
      for (final key in prefs.getKeys()) {
        if (key.startsWith(_scorePrefix)) {
          final value = prefs.getInt(key);
          if (value != null) {
            scores[key.substring(_scorePrefix.length)] = value;
          }
        }
      }
      return PrefsSettingsStore._(
        prefs,
        scores,
        prefs.getBool(_mutedKey) ?? false,
      );
    } on Object catch (error, stack) {
      debugPrint('设置载入失败，降级为内存存储: $error\n$stack');
      return InMemorySettingsStore();
    }
  }

  @override
  int highScore(String gameId) => _scores[gameId] ?? 0;

  @override
  Future<void> setHighScore(String gameId, int value) async {
    _scores[gameId] = value;
    try {
      await _prefs.setInt('$_scorePrefix$gameId', value);
    } on Object catch (error) {
      debugPrint('最高分写入失败: $error');
    }
  }

  @override
  bool get muted => _muted;

  @override
  Future<void> setMuted(bool value) async {
    _muted = value;
    try {
      await _prefs.setBool(_mutedKey, value);
    } on Object catch (error) {
      debugPrint('静音设置写入失败: $error');
    }
  }
}
