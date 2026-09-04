import 'package:flutter/foundation.dart';

import 'sfx.dart';

@immutable
class SfxRequest {
  const SfxRequest(this.sfx, {this.semitones = 0, required this.volume});

  final Sfx sfx;
  final int semitones;
  final double volume;
}

/// 同帧限流：一帧内同种音效只播一次，保留音高最高的那次。
///
/// 没有这一层时，十几个方块同时消除会把同一音效叠加成噪音——
/// 这是最容易被忽略、却对听感影响最大的一条。
class SfxThrottle {
  final Map<Sfx, SfxRequest> _pending = <Sfx, SfxRequest>{};

  void add(SfxRequest request) {
    final existing = _pending[request.sfx];
    if (existing == null || request.semitones > existing.semitones) {
      _pending[request.sfx] = request;
    }
  }

  bool get isEmpty => _pending.isEmpty;

  List<SfxRequest> flush() {
    final flushed = _pending.values.toList(growable: false);
    _pending.clear();
    return flushed;
  }
}
