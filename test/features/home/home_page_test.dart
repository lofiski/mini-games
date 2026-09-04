import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/app/app.dart';
import 'package:mini_games/core/game/game_definition.dart';
import 'package:mini_games/core/game/game_registry.dart';
import 'package:mini_games/core/storage/settings_store.dart';
import 'package:mini_games/core/storage/storage_providers.dart';

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
}
