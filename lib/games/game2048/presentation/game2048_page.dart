import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_scaffold.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/widgets/responsive_board.dart';
import '../domain/move.dart';
import '../domain/tile.dart';
import '../game2048_definition.dart';
import 'game2048_notifier.dart';
import 'game2048_state.dart';
import 'tile_colors.dart';

class Game2048Page extends ConsumerWidget {
  const Game2048Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(game2048Provider);
    final notifier = ref.read(game2048Provider.notifier);
    final best = ref.watch(highScoreProvider(kGame2048Id));

    return GameScaffold(
      definition: game2048Definition,
      score: state.score,
      best: best,
      onRestart: notifier.restart,
      banner: switch (state.status) {
        Game2048Status.won => const _Banner(text: '达成 2048，可以继续挑战'),
        Game2048Status.over => const _Banner(text: '无路可走了，点右上角重开'),
        Game2048Status.playing => null,
      },
      child: ResponsiveBoard(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanEnd: (details) {
            final velocity = details.velocity.pixelsPerSecond;
            if (velocity.distance < 120) return;
            final direction = velocity.dx.abs() > velocity.dy.abs()
                ? (velocity.dx > 0 ? SwipeDirection.right : SwipeDirection.left)
                : (velocity.dy > 0 ? SwipeDirection.down : SwipeDirection.up);
            notifier.swipe(direction);
          },
          child: _Board(state: state),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

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
      child: Text(text, style: TextStyle(color: scheme.onSecondaryContainer)),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.state});

  final Game2048State state;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = state.board.size;
        final boardSize = constraints.biggest.shortestSide;
        final cell = (boardSize - _gap * (size + 1)) / size;

        double offset(int index) => _gap + index * (cell + _gap);

        return Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            color: const Color(0xFFBBADA0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              for (var r = 0; r < size; r++)
                for (var c = 0; c < size; c++)
                  Positioned(
                    left: offset(c),
                    top: offset(r),
                    width: cell,
                    height: cell,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFCDC1B4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              // 被吞并的方块画在下层，滑动动画因此不会出现方块凭空消失
              for (final tile in state.absorbed)
                _TileView(
                  key: ValueKey<String>('absorbed-${tile.id}'),
                  tile: tile,
                  left: offset(tile.col),
                  top: offset(tile.row),
                  size: cell,
                  popped: false,
                ),
              for (final tile in state.board.tiles)
                _TileView(
                  key: ValueKey<int>(tile.id),
                  tile: tile,
                  left: offset(tile.col),
                  top: offset(tile.row),
                  size: cell,
                  popped: state.mergedIds.contains(tile.id),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TileView extends StatelessWidget {
  const _TileView({
    super.key,
    required this.tile,
    required this.left,
    required this.top,
    required this.size,
    required this.popped,
  });

  final Tile tile;
  final double left;
  final double top;
  final double size;
  final bool popped;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        key: ValueKey<int>(tile.value),
        tween: Tween<double>(begin: popped ? 0.82 : 1, end: 1),
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorForValue(tile.value),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${tile.value}',
              style: TextStyle(
                fontSize: fontSizeForValue(tile.value, size),
                fontWeight: FontWeight.w800,
                color: textColorForValue(tile.value),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
