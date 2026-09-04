import 'dart:math' as math;

/// 连击每升一级抬高的半音数。取 2（大二度）而非 1，
/// 递进更可闻，长连击也不刺耳。
const int kComboStepSemitones = 2;

/// 升调封顶，避免长连击把音效推到尖锐失真。
const int kComboMaxSemitones = 14;

/// 连击级别对应的半音数。
int comboSemitones(int comboIndex) {
  if (comboIndex <= 0) return 0;
  final raw = comboIndex * kComboStepSemitones;
  return raw > kComboMaxSemitones ? kComboMaxSemitones : raw;
}

/// 半音数换算为播放速率：升高 12 个半音即两倍速。
double playbackRateForSemitones(int semitones) =>
    math.pow(2, semitones / 12).toDouble();
