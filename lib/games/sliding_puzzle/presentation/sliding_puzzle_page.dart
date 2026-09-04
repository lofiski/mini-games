import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_scaffold.dart';
import '../../../core/widgets/responsive_board.dart';
import '../sliding_puzzle_definition.dart';
import 'sliding_puzzle_notifier.dart';
import 'sliding_puzzle_state.dart';

class SlidingPuzzlePage extends ConsumerWidget {
  const SlidingPuzzlePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(slidingPuzzleProvider);
    final notifier = ref.read(slidingPuzzleProvider.notifier);

    return GameScaffold(
      definition: slidingPuzzleDefinition,
      score: state.moves,
      best: state.bestMoves,
      scoreLabel: '步数',
      bestLabel: '最少步数',
      onRestart: notifier.restart,
      banner: state.solved ? const _SolvedBanner() : null,
      child: ResponsiveBoard(
        child: _PuzzleBoard(state: state, onTap: notifier.tap),
      ),
    );
  }
}

class _SolvedBanner extends StatelessWidget {
  const _SolvedBanner();

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
        '还原成功，点右上角再来一局',
        style: TextStyle(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

class _PuzzleBoard extends StatelessWidget {
  const _PuzzleBoard({required this.state, required this.onTap});

  final SlidingPuzzleState state;
  final void Function(int index) onTap;

  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = state.puzzle.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.biggest.shortestSide;
        final cell = (boardSize - _gap * (size + 1)) / size;
        double offset(int index) => _gap + index * (cell + _gap);

        return Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              for (var index = 0; index < state.puzzle.tiles.length; index++)
                if (state.puzzle.tiles[index] != 0)
                  AnimatedPositioned(
                    // 用数字本身作为 key，方块在棋盘上移动时身份保持稳定
                    key: ValueKey<int>(state.puzzle.tiles[index]),
                    duration: const Duration(milliseconds: 130),
                    curve: Curves.easeOutCubic,
                    left: offset(index % size),
                    top: offset(index ~/ size),
                    width: cell,
                    height: cell,
                    child: _PuzzleTile(
                      number: state.puzzle.tiles[index],
                      cellSize: cell,
                      onTap: () => onTap(index),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _PuzzleTile extends StatelessWidget {
  const _PuzzleTile({
    required this.number,
    required this.cellSize,
    required this.onTap,
  });

  final int number;
  final double cellSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: cellSize * 0.4,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
