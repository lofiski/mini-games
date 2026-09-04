import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/core/audio/sfx.dart';
import 'package:mini_games/core/audio/sfx_throttle.dart';

void main() {
  test('同一帧内同种音效只保留音高最高的一次', () {
    final throttle = SfxThrottle()
      ..add(const SfxRequest(Sfx.pop, semitones: 2, volume: 0.85))
      ..add(const SfxRequest(Sfx.pop, semitones: 8, volume: 0.85))
      ..add(const SfxRequest(Sfx.pop, semitones: 4, volume: 0.85));

    final flushed = throttle.flush();

    expect(flushed, hasLength(1));
    expect(flushed.single.semitones, 8);
  });

  test('不同种音效互不影响', () {
    final throttle = SfxThrottle()
      ..add(const SfxRequest(Sfx.pop, semitones: 2, volume: 0.85))
      ..add(const SfxRequest(Sfx.tap, volume: 0.4));

    expect(throttle.flush(), hasLength(2));
  });

  test('flush 之后清空', () {
    final throttle = SfxThrottle()
      ..add(const SfxRequest(Sfx.pop, semitones: 2, volume: 0.85));

    throttle.flush();

    expect(throttle.isEmpty, isTrue);
    expect(throttle.flush(), isEmpty);
  });
}
