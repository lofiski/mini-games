/// 应用设置与最高分的读写。
///
/// 读同步、写异步：启动时一次性把数据载入内存，
/// UI 层因此不需要处理 async 状态。
abstract interface class SettingsStore {
  int highScore(String gameId);

  Future<void> setHighScore(String gameId, int value);

  bool get muted;

  Future<void> setMuted(bool value);
}

/// 测试与降级场景使用的内存实现。
class InMemorySettingsStore implements SettingsStore {
  // 命名参数不允许以下划线开头，因此无法用初始化形参直接赋给 _muted。
  // ignore: prefer_initializing_formals
  InMemorySettingsStore({Map<String, int>? scores, bool muted = false})
    : _scores = {...?scores},
      _muted = muted;

  final Map<String, int> _scores;
  bool _muted;

  @override
  int highScore(String gameId) => _scores[gameId] ?? 0;

  @override
  Future<void> setHighScore(String gameId, int value) async {
    _scores[gameId] = value;
  }

  @override
  bool get muted => _muted;

  @override
  Future<void> setMuted(bool value) async {
    _muted = value;
  }
}
