import 'package:flutter/material.dart';

import '../../core/game/game_definition.dart';
import 'presentation/tap_match_page.dart';

const String kTapMatchId = 'tap_match';

final GameDefinition tapMatchDefinition = GameDefinition(
  id: kTapMatchId,
  title: '点点消消乐',
  tagline: '点击相连同色一次清空',
  icon: Icons.blur_on,
  accent: const Color(0xFFE8505B),
  builder: (context) => const TapMatchPage(),
);
