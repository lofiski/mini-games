import 'dart:math';

import 'puzzle.dart';

/// 从已解状态出发随机走合法步来洗牌。
///
/// 相比直接打乱数组再判定奇偶性，这种做法天然保证 100% 可解，
/// 实现更短也更容易测试。避免立即走回上一步，防止原地打转导致洗不散。
Puzzle shufflePuzzle({
  required int size,
  required Random random,
  int steps = 200,
}) {
  var puzzle = Puzzle.solved(size);
  var previousBlank = -1;

  for (var i = 0; i < steps; i++) {
    final blank = puzzle.blankIndex;
    final candidates = _neighbours(
      blank,
      size,
    ).where((candidate) => candidate != previousBlank).toList(growable: false);
    final pick = candidates[random.nextInt(candidates.length)];
    previousBlank = blank;
    puzzle = puzzle.tap(pick);
  }

  // 极小概率洗回已解状态，此时重洗。
  if (puzzle.isSolved) {
    return shufflePuzzle(size: size, random: random, steps: steps);
  }
  return puzzle;
}

List<int> _neighbours(int index, int size) {
  final row = index ~/ size;
  final col = index % size;
  return <int>[
    if (row > 0) (row - 1) * size + col,
    if (row < size - 1) (row + 1) * size + col,
    if (col > 0) row * size + (col - 1),
    if (col < size - 1) row * size + (col + 1),
  ];
}
