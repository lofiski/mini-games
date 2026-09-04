import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_providers.dart';
import '../audio/sfx.dart';
import 'game_definition.dart';

/// 所有游戏共用的外壳：返回、标题、当前分、最佳分、重开、静音。
///
/// 新游戏接入后自动获得这些能力，无需各自实现。
class GameScaffold extends ConsumerWidget {
  const GameScaffold({
    super.key,
    required this.definition,
    required this.score,
    required this.best,
    required this.onRestart,
    required this.child,
    this.banner,
    this.scoreLabel = '分数',
    this.bestLabel = '最佳',
  });

  final GameDefinition definition;
  final int score;
  final int best;
  final VoidCallback onRestart;
  final Widget child;

  /// 通关或结束时显示在棋盘上方的提示条。
  final Widget? banner;

  final String scoreLabel;
  final String bestLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = ref.watch(mutedProvider);
    final audio = ref.read(audioServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              definition: definition,
              muted: muted,
              onToggleMute: () => ref.read(mutedProvider.notifier).toggle(),
              onRestart: () {
                audio.play(Sfx.tap, volume: kVolumeUi);
                onRestart();
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _ScoreChip(
                    label: scoreLabel,
                    value: score,
                    accent: definition.accent,
                  ),
                  const SizedBox(width: 12),
                  _ScoreChip(
                    label: bestLabel,
                    value: best,
                    accent: definition.accent,
                  ),
                ],
              ),
            ),
            if (banner != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: banner,
              ),
            Expanded(
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.definition,
    required this.muted,
    required this.onToggleMute,
    required this.onRestart,
  });

  final GameDefinition definition;
  final bool muted;
  final VoidCallback onToggleMute;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回',
          ),
          Expanded(
            child: Text(
              definition.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            onPressed: onToggleMute,
            icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
            tooltip: muted ? '取消静音' : '静音',
          ),
          IconButton(
            onPressed: onRestart,
            icon: const Icon(Icons.refresh),
            tooltip: '重新开始',
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                '$value',
                key: ValueKey<int>(value),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
