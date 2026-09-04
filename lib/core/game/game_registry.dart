import 'game_definition.dart';

/// 全部已注册游戏的有序集合。
class GameRegistry {
  GameRegistry(this.games) {
    final seen = <String>{};
    for (final game in games) {
      if (!seen.add(game.id)) {
        throw ArgumentError.value(game.id, 'games', '游戏 id 重复');
      }
    }
  }

  /// 注册顺序即首页展示顺序。
  final List<GameDefinition> games;

  GameDefinition? byId(String id) {
    for (final game in games) {
      if (game.id == id) return game;
    }
    return null;
  }
}
