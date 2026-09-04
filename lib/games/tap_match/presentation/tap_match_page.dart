import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_scaffold.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/widgets/responsive_board.dart';
import '../domain/match_grid.dart';
import '../tap_match_definition.dart';
import 'tap_match_notifier.dart';
import 'tap_match_state.dart';

/// 五种色块的配色，明度接近以免某一色显得突兀。
const List<Color> kMatchPalette = <Color>[
  Color(0xFFE8505B),
  Color(0xFF4C8BF5),
  Color(0xFF3FBF7F),
  Color(0xFFF5A623),
  Color(0xFF9B6DE8),
];

class TapMatchPage extends ConsumerWidget {
  const TapMatchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tapMatchProvider);
    final notifier = ref.read(tapMatchProvider.notifier);
    final best = ref.watch(highScoreProvider(kTapMatchId));

    return GameScaffold(
      definition: tapMatchDefinition,
      score: state.score,
      best: best,
      onRestart: notifier.restart,
      banner: state.over ? const _OverBanner() : null,
      child: ResponsiveBoard(
        aspectRatio: kMatchColumns / kMatchRows,
        child: _MatchBoard(state: state, onTap: notifier.tapCell),
      ),
    );
  }
}

class _OverBanner extends StatelessWidget {
  const _OverBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '没有可消的色块了，点右上角再来一局',
        style: TextStyle(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

class _MatchBoard extends StatelessWidget {
  const _MatchBoard({required this.state, required this.onTap});

  final TapMatchState state;
  final void Function(int row, int col) onTap;

  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    final grid = state.grid;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth =
            (constraints.maxWidth - _gap * (grid.columns + 1)) / grid.columns;
        final cellHeight =
            (constraints.maxHeight - _gap * (grid.rows + 1)) / grid.rows;
        final cell = cellWidth < cellHeight ? cellWidth : cellHeight;

        double left(int col) => _gap + col * (cell + _gap);
        double top(int row) => _gap + row * (cell + _gap);

        return Stack(
          children: [
            for (var r = 0; r < grid.rows; r++)
              for (var c = 0; c < grid.columns; c++)
                if (grid.at(r, c) case final MatchCell item)
                  AnimatedPositioned(
                    // 以色块 id 为 key，下落与左移因此是连续动画而非闪现
                    key: ValueKey<int>(item.id),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    left: left(c),
                    top: top(r),
                    width: cell,
                    height: cell,
                    child: _MatchTile(
                      color: kMatchPalette[item.color % kMatchPalette.length],
                      onTap: () => onTap(r, c),
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
