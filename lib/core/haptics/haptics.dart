import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 触觉反馈。安卓端的「畅快」有相当一部分来自震动，
/// 因此每个正反馈音效都配一次轻震动。
class Haptics {
  const Haptics._();

  static void light() => _guard(HapticFeedback.lightImpact);

  static void medium() => _guard(HapticFeedback.mediumImpact);

  static void selection() => _guard(HapticFeedback.selectionClick);

  static void _guard(Future<void> Function() action) {
    action().catchError((Object error) {
      debugPrint('触觉反馈不可用: $error');
    });
  }
}
