import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';
import 'audio_service.dart';

/// 由 main() 在启动时 override 注入具体实现。
/// 默认值是无声实现，因此测试与 Widget 测试无需额外 override。
final Provider<AudioService> audioServiceProvider = Provider<AudioService>(
  (ref) => SilentAudioService(),
);

/// 全局静音开关。切换时同时更新音频服务与持久化存储，
/// 否则重启应用后设置会丢失。
class MutedNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsStoreProvider).muted;

  Future<void> toggle() async {
    final next = !state;
    state = next;
    await ref.read(audioServiceProvider).setMuted(next);
    unawaited(ref.read(settingsStoreProvider).setMuted(next));
  }
}

final mutedProvider = NotifierProvider<MutedNotifier, bool>(MutedNotifier.new);
