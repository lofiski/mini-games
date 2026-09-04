import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/core/game/game_definition.dart';
import 'package:mini_games/core/game/game_registry.dart';

GameDefinition _def(String id) => GameDefinition(
  id: id,
  title: id,
  tagline: '测试用',
  icon: Icons.games,
  accent: const Color(0xFF000000),
  builder: (_) => const SizedBox.shrink(),
);

void main() {
  test('按 id 查找已注册的游戏', () {
    final registry = GameRegistry([_def('a'), _def('b')]);
    expect(registry.byId('b')?.id, 'b');
  });

  test('查找不存在的 id 返回 null', () {
    final registry = GameRegistry([_def('a')]);
    expect(registry.byId('missing'), isNull);
  });

  test('games 保持注册时的顺序', () {
    final registry = GameRegistry([_def('a'), _def('b'), _def('c')]);
    expect(registry.games.map((g) => g.id).toList(), ['a', 'b', 'c']);
  });

  test('重复 id 在构造时即被拒绝', () {
    expect(() => GameRegistry([_def('a'), _def('a')]), throwsArgumentError);
  });
}
