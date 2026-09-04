import 'sfx.dart';

/// 音效播放。
///
/// 所有实现都必须遵守：任何失败都吞掉并降级，绝不抛出。
/// 音频永远不在游戏的关键路径上。
abstract interface class AudioService {
  Future<void> init();

  /// 播放一个音效。[comboIndex] 为连击级别，0 表示不升调。
  void play(Sfx sfx, {int comboIndex = 0, double? volume});

  bool get muted;

  Future<void> setMuted(bool value);

  Future<void> dispose();
}

/// 音频不可用时的降级实现，同时用于单元测试。
class SilentAudioService implements AudioService {
  bool _muted = false;

  /// 测试用：记录收到的播放请求。
  final List<Sfx> played = <Sfx>[];

  @override
  Future<void> init() async {}

  @override
  void play(Sfx sfx, {int comboIndex = 0, double? volume}) {
    if (!_muted) played.add(sfx);
  }

  @override
  bool get muted => _muted;

  @override
  Future<void> setMuted(bool value) async {
    _muted = value;
  }

  @override
  Future<void> dispose() async {}
}
