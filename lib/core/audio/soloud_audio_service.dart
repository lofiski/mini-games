import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'audio_service.dart';
import 'combo_pitch.dart';
import 'sfx.dart';
import 'sfx_throttle.dart';

/// flutter_soloud 后端：启动时把全部音效解码进内存，播放零延迟。
///
/// 初始化失败时 [_ready] 保持 false，此后所有 play 调用静默丢弃，
/// 游戏功能不受影响。
class SoLoudAudioService implements AudioService {
  SoLoudAudioService({required bool muted}) {
    _muted = muted;
  }

  final Map<Sfx, AudioSource> _sources = <Sfx, AudioSource>{};
  final SfxThrottle _throttle = SfxThrottle();
  bool _ready = false;
  bool _flushScheduled = false;
  bool _muted = false;

  @override
  Future<void> init() async {
    try {
      // lowLatency 默认开启，正是短音效需要的模式。
      await SoLoud.instance.init();
      for (final sfx in Sfx.values) {
        // LoadMode.memory 是默认值：短音效整段解码进内存，播放时零解码开销。
        _sources[sfx] = await SoLoud.instance.loadAsset(assetPathFor(sfx));
      }
      _ready = true;
    } on Object catch (error, stack) {
      debugPrint('音频初始化失败，本次运行将静音: $error\n$stack');
      _ready = false;
    }
  }

  @override
  void play(Sfx sfx, {int comboIndex = 0, double? volume}) {
    if (!_ready || _muted) return;
    _throttle.add(
      SfxRequest(
        sfx,
        semitones: comboSemitones(comboIndex),
        volume: volume ?? kVolumeReward,
      ),
    );
    _scheduleFlush();
  }

  /// 把本帧内累积的请求推迟到微任务末尾统一播放，实现同帧限流。
  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    scheduleMicrotask(() {
      _flushScheduled = false;
      for (final request in _throttle.flush()) {
        _playNow(request);
      }
    });
  }

  void _playNow(SfxRequest request) {
    final source = _sources[request.sfx];
    if (source == null) return;
    try {
      // play 在 5.x 是同步的，scale 直接指定相对播放速率，
      // 因此变调与起播是原子的，不存在先播原速再改速率的瞬间跑调。
      SoLoud.instance.play(
        source,
        volume: request.volume,
        scale: playbackRateForSemitones(request.semitones),
      );
    } on Object catch (error) {
      debugPrint('音效播放失败: $error');
    }
  }

  @override
  bool get muted => _muted;

  @override
  Future<void> setMuted(bool value) async {
    _muted = value;
  }

  @override
  Future<void> dispose() async {
    if (!_ready) return;
    try {
      SoLoud.instance.deinit();
    } on Object catch (error) {
      debugPrint('音频释放失败: $error');
    }
  }
}
