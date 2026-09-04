import 'package:go_router/go_router.dart';

import '../core/game/game_registry.dart';
import '../features/home/home_page.dart';

/// 路由表由注册表生成，新增游戏无需在此改动。
GoRouter buildRouter(GameRegistry registry) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomePage(registry: registry),
        routes: [
          for (final game in registry.games)
            GoRoute(
              path: game.id,
              builder: (context, state) => game.builder(context),
            ),
        ],
      ),
    ],
  );
}
