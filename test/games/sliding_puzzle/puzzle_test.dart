import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/games/sliding_puzzle/domain/puzzle.dart';

void main() {
  test('已解棋盘按顺序排列且空格在右下', () {
    final puzzle = Puzzle.solved(4);

    expect(puzzle.tiles.take(15).toList(), List.generate(15, (i) => i + 1));
    expect(puzzle.blankIndex, 15);
    expect(puzzle.isSolved, isTrue);
  });

  test('与空格不同行不同列的方块不可点击', () {
    final puzzle = Puzzle.solved(4); // 空格在 (3,3)

    expect(puzzle.canTap(0), isFalse); // (0,0)
    expect(puzzle.canTap(3), isTrue); // (0,3) 同列
    expect(puzzle.canTap(12), isTrue); // (3,0) 同行
  });

  test('空格本身不可点击', () {
    expect(Puzzle.solved(4).canTap(15), isFalse);
  });

  test('点击紧邻空格的方块使其移入空格', () {
    final puzzle = Puzzle.solved(4).tap(14);

    expect(puzzle.tiles[15], 15);
    expect(puzzle.tiles[14], 0);
  });

  test('点击同一行较远的方块使整排一起滑动', () {
    // 空格在 (3,3)，点击 (3,0)，则 13、14、15 整体右移一格
    final puzzle = Puzzle.solved(4).tap(12);

    expect(puzzle.tiles.sublist(12), [0, 13, 14, 15]);
  });

  test('点击同一列较远的方块使整列一起滑动', () {
    // 空格在 (3,3)，点击 (0,3)，则该列方块整体下移
    final puzzle = Puzzle.solved(4).tap(3);

    expect(puzzle.tiles[3], 0);
    expect(puzzle.tiles[7], 4);
    expect(puzzle.tiles[11], 8);
    expect(puzzle.tiles[15], 12);
  });

  test('slideDistance 返回本次移动的方块数', () {
    final puzzle = Puzzle.solved(4);

    expect(puzzle.slideDistance(14), 1);
    expect(puzzle.slideDistance(12), 3);
    expect(puzzle.slideDistance(0), 0);
  });

  test('点击不可点击的位置返回原棋盘', () {
    final puzzle = Puzzle.solved(4);

    expect(puzzle.tap(0).tiles, puzzle.tiles);
  });

  test('越界下标被安全忽略', () {
    final puzzle = Puzzle.solved(4);

    expect(puzzle.slideDistance(-1), 0);
    expect(puzzle.slideDistance(99), 0);
    expect(puzzle.tap(99).tiles, puzzle.tiles);
  });

  test('滑动后不再是已解状态', () {
    expect(Puzzle.solved(4).tap(12).isSolved, isFalse);
  });
}
