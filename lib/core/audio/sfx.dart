/// 全部音效种类。新增音效时在此扩展并补充 [assetPathFor] 的分支。
///
/// 素材统一选用音调型音色（pluck / glass / bong），因为本项目的核心
/// 技巧是按连击升调——噪音型音色升调只会变刺耳，听不出音高递进。
enum Sfx { tap, invalid, merge, slide, pop, win, gameOver }

/// 音量分层。失败音效必须明显轻于成功音效，否则长时间游玩会烦躁。
const double kVolumeUi = 0.4;
const double kVolumeReward = 0.85;
const double kVolumeNegative = 0.3;
const double kVolumeWin = 0.9;

String assetPathFor(Sfx sfx) {
  switch (sfx) {
    case Sfx.tap:
      return 'assets/audio/tap.wav';
    case Sfx.invalid:
      return 'assets/audio/invalid.wav';
    case Sfx.merge:
      return 'assets/audio/merge.wav';
    case Sfx.slide:
      return 'assets/audio/slide.wav';
    case Sfx.pop:
      return 'assets/audio/pop.wav';
    case Sfx.win:
      return 'assets/audio/win.wav';
    case Sfx.gameOver:
      return 'assets/audio/game_over.wav';
  }
}
