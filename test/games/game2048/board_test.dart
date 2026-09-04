import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/games/game2048/domain/board.dart';
import 'package:mini_games/games/game2048/domain/move.dart';

import 'move_test.dart' show boardOf;

void main() {
  test('空棋盘没有方块且不满', () {
    final board = Board2048.empty(4);

    expect(board.tiles, isEmpty);
    expect(board.isFull, isFalse);
    expect(board.emptyIndices, hasLength(16));
  });

  test('满盘且相邻无相同值时四方向均不可动', () {
    final board = boardOf([
      [2, 4, 2, 4],
      [4, 2, 4, 2],
      [2, 4, 2, 4],
      [4, 2, 4, 2],
    ]);

    expect(board.isFull, isTrue);
    expect(canMoveAnyDirection(board), isFalse);
  });

  test('满盘但存在相邻相同值时仍可移动', () {
    final board = boardOf([
      [2, 2, 2, 4],
      [4, 2, 4, 2],
      [2, 4, 2, 4],
      [4, 2, 4, 2],
    ]);

    expect(board.isFull, isTrue);
    expect(canMoveAnyDirection(board), isTrue);
  });

  test('maxValue 返回棋盘上的最大数字', () {
    final board = boardOf([
      [2, 4, 8, 16],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);

    expect(board.maxValue, 16);
  });
}
