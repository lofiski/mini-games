import 'package:flutter/material.dart';

const Color _seed = Color(0xFF4C8BF5);

ThemeData buildLightTheme() => _base(Brightness.light);

ThemeData buildDarkTheme() => _base(Brightness.dark);

ThemeData _base(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  final typography = Typography.material2021();
  // 必须按 brightness 选择基础字色，否则暗色模式下文字会是黑的。
  final base = brightness == Brightness.dark
      ? typography.white
      : typography.black;
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    splashFactory: InkSparkle.splashFactory,
    textTheme: base.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
  );
}
