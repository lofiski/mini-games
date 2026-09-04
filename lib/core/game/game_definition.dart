import 'package:flutter/widgets.dart';

/// 一款游戏对外暴露的全部信息。
///
/// 新增游戏时实现此契约并注册到 GameRegistry 即可，
/// 首页列表、路由、游戏外壳、音效与存档会自动接入。
@immutable
class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.accent,
    required this.builder,
  });

  /// 稳定标识，同时用作路由 path 与最高分存档 key。注册后不应更改。
  final String id;

  /// 首页方块上显示的游戏名。
  final String title;

  /// 一句话玩法说明。
  final String tagline;

  /// 首页方块图标。
  final IconData icon;

  /// 首页方块主色，同时作为游戏内强调色。
  final Color accent;

  /// 构建游戏主界面。返回类型是 Widget，
  /// 因此将来某款实时游戏内部改用 Flame 的 GameWidget 也不破坏本契约。
  final WidgetBuilder builder;
}
