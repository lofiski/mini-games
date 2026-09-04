import 'core/game/game_registry.dart';
import 'games/game2048/game2048_definition.dart';

/// 新增游戏的唯一改动点：在下面的列表中加入该游戏的 GameDefinition。
final GameRegistry gameRegistry = GameRegistry([game2048Definition]);
