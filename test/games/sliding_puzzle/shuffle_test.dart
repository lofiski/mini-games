import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/games/sliding_puzzle/domain/puzzle.dart';
import 'package:mini_games/games/sliding_puzzle/domain/shuffle.dart';

/// 用逆序数奇偶性独立判定可解性，与「随机合法走步」的洗牌实现互为交叉验证。
///
/// 偶数边长的棋盘：逆序数 + 空格自底向上的行号（1 起）为奇数时可解。
/// 奇数边长的棋盘：逆序数为偶数时可解。
bool isSolvable(Puzzle puzzle) {
  final values = puzzle.tiles.where((v) => v != 0).toList();
  var inversions = 0;
  for (var i = 0; i < values.length; i++) {
    for (var j = i + 1; j < values.length; j++) {
      if (values[i] > values[j]) inversions++;
    }
  }
  if (puzzle.size.isOdd) return inversions.isEven;
  final blankRowFromBottom = puzzle.size - puzzle.blankIndex ~/ puzzle.size;
  return (inversions + blankRowFromBottom).isOdd;
}

void main() {
  test('已解棋盘可解', () {
    expect(isSolvable(Puzzle.solved(4)), isTrue);
  });

  test('随机洗牌 1000 次结果全部可解', () {
    final random = Random(20260904);

    for (var i = 0; i < 1000; i++) {
      final puzzle = shufflePuzzle(size: 4, random: random);
      expect(isSolvable(puzzle), isTrue, reason: '第 $i 次洗牌产生了不可解的局面');
    }
  });

  test('洗牌结果不会是已解状态', () {
    final random = Random(7);

    for (var i = 0; i < 200; i++) {
      expect(shufflePuzzle(size: 4, random: random).isSolved, isFalse);
    }
  });

  test('洗牌保留全部数字', () {
    final puzzle = shufflePuzzle(size: 4, random: Random(1));

    expect(puzzle.tiles.toSet(), List.generate(16, (i) => i).toSet());
  });

  test('相同种子产生相同结果', () {
    final a = shufflePuzzle(size: 4, random: Random(42));
    final b = shufflePuzzle(size: 4, random: Random(42));

    expect(a.tiles, b.tiles);
  });
}
