import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/audio/audio_providers.dart';
import 'core/audio/audio_service.dart';
import 'core/audio/soloud_audio_service.dart';
import 'core/storage/prefs_settings_store.dart';
import 'core/storage/storage_providers.dart';
import 'games_registry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = await PrefsSettingsStore.create();

  final AudioService audio = SoLoudAudioService(muted: store.muted);
  // 音频初始化不阻塞首帧：预加载在后台完成，期间的播放请求会被静默丢弃。
  unawaited(audio.init());

  runApp(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        audioServiceProvider.overrideWithValue(audio),
      ],
      child: MiniGamesApp(registry: gameRegistry),
    ),
  );
}
