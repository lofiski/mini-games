import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/game/game_registry.dart';
import 'router.dart';
import 'theme.dart';

class MiniGamesApp extends StatefulWidget {
  const MiniGamesApp({super.key, required this.registry});

  final GameRegistry registry;

  @override
  State<MiniGamesApp> createState() => _MiniGamesAppState();
}

class _MiniGamesAppState extends State<MiniGamesApp> {
  /// 路由只构建一次：GoRouter 持有导航栈，重建会丢失当前页面。
  late final GoRouter _router = buildRouter(widget.registry);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mini Games',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      routerConfig: _router,
    );
  }
}
