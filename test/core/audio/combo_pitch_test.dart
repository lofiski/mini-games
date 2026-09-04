import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/core/audio/combo_pitch.dart';

void main() {
  test('连击第 0 级不升调', () {
    expect(comboSemitones(0), 0);
  });

  test('每级升 2 个半音', () {
    expect(comboSemitones(1), 2);
    expect(comboSemitones(3), 6);
  });

  test('升调封顶在 14 个半音', () {
    expect(comboSemitones(7), 14);
    expect(comboSemitones(100), 14);
  });

  test('负数连击级别按 0 处理', () {
    expect(comboSemitones(-1), 0);
  });

  test('0 半音对应原速播放', () {
    expect(playbackRateForSemitones(0), closeTo(1.0, 1e-9));
  });

  test('12 个半音对应两倍速，即升高一个八度', () {
    expect(playbackRateForSemitones(12), closeTo(2.0, 1e-9));
  });
}
