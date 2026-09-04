import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/app/app.dart';
import 'package:mini_games/core/game/game_definition.dart';
import 'package:mini_games/core/game/game_registry.dart';
import 'package:mini_games/core/storage/settings_store.dart';
import 'package:mini_games/core/storage/storage_providers.dart';
import 'package:mini_games/games_registry.dart';

GameDefinition _def(String id, String title) => GameDefinition(
  id: id,
  title: title,
  tagline: '玩法说明',
  icon: Icons.grid_4x4,
  accent: const Color(0xFF4C8BF5),
  builder: (_) => Scaffold(body: Center(child: Text('进入 $title'))),
);

Widget _app(GameRegistry registry) => ProviderScope(
  overrides: [settingsStoreProvider.overrideWithValue(InMemorySettingsStore())],
  child: MiniGamesApp(registry: registry),
);

void main() {
  testWidgets('首页渲染注册表中的全部游戏', (tester) async {
    await tester.pumpWidget(
      _app(GameRegistry([_def('a', '游戏甲'), _def('b', '游戏乙')])),
    );
    await tester.pumpAndSettle();

    expect(find.text('游戏甲'), findsOneWidget);
    expect(find.text('游戏乙'), findsOneWidget);
  });

  testWidgets('点击方块进入对应游戏', (tester) async {
    await tester.pumpWidget(
      _app(GameRegistry([_def('a', '游戏甲'), _def('b', '游戏乙')])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('游戏乙'));
    await tester.pumpAndSettle();

    expect(find.text('进入 游戏乙'), findsOneWidget);
  });

  testWidgets('注册表为空时首页不崩溃', (tester) async {
    await tester.pumpWidget(_app(GameRegistry(const [])));
    await tester.pumpAndSettle();

    expect(find.byType(MiniGamesApp), findsOneWidget);
  });

  testWidgets('真实注册表中的三款游戏都出现在首页', (tester) async {
    // 手机竖屏尺寸，确保三个方块都在首屏可见
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(gameRegistry));
    await tester.pumpAndSettle();

    expect(find.text('2048'), findsOneWidget);
    expect(find.text('数字华容道'), findsOneWidget);
    expect(find.text('点点消消乐'), findsOneWidget);
  });

  testWidgets('点击首页方块能进入每一款真实游戏', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(gameRegistry));
    await tester.pumpAndSettle();

    for (final game in gameRegistry.games) {
      await tester.tap(find.text(game.title));
      await tester.pumpAndSettle();

      // 进入游戏后，外壳顶栏会提供重开按钮
      expect(
        find.byTooltip('重新开始'),
        findsOneWidget,
        reason: '${game.title} 未能进入游戏页',
      );

      // 用返回键回到首页，顺带覆盖外壳的返回按钮
      await tester.tap(find.byTooltip('返回'));
      await tester.pumpAndSettle();

      expect(
        find.byTooltip('重新开始'),
        findsNothing,
        reason: '${game.title} 未能返回首页',
      );
    }
  });
}
