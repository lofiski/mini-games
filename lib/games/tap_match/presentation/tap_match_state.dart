import 'package:meta/meta.dart';

import '../domain/match_grid.dart';

@immutable
class TapMatchState {
  const TapMatchState({
    required this.grid,
    required this.score,
    required this.over,
  });

  final MatchGrid grid;
  final int score;
  final bool over;
}
