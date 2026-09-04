import 'package:flutter/material.dart';

import '../../core/game/game_definition.dart';
import 'presentation/sliding_puzzle_page.dart';

const String kSlidingPuzzleId = 'sliding_puzzle';

final GameDefinition slidingPuzzleDefinition = GameDefinition(
  id: kSlidingPuzzleId,
  title: '数字华容道',
  tagline: '滑动方块还原顺序',
  icon: Icons.apps,
  accent: const Color(0xFF4C8BF5),
  builder: (context) => const SlidingPuzzlePage(),
);
