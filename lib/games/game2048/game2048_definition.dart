import 'package:flutter/material.dart';

import '../../core/game/game_definition.dart';
import 'presentation/game2048_page.dart';

const String kGame2048Id = 'game2048';

final GameDefinition game2048Definition = GameDefinition(
  id: kGame2048Id,
  title: '2048',
  tagline: '滑动合并相同数字',
  icon: Icons.grid_4x4,
  accent: const Color(0xFFEDC22E),
  builder: (context) => const Game2048Page(),
);
