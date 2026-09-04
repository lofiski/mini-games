# Mini Games — 设计文档

- 日期：2026-09-04
- 状态：已批准，进入实现计划阶段
- 目标平台：Android（架构不排斥后续扩展到其他平台）

## 1. 目标与非目标

### 目标

一个极简的安卓休闲小游戏合集：打开应用直接看到游戏方块列表，点击方块立即开始游戏。首批三款：

1. **2048**
2. **数字华容道**（15 拼图）
3. **点点消消乐**（点击色块，相邻同色连通块整体消除）

架构必须保持开放：新增一款游戏不应改动任何既有游戏的代码。

音效是一等公民，服务于「简单、畅快」的手感。

### 非目标

- 不做账号、联网、排行榜、内购、广告（应用不声明任何权限，含 INTERNET）
- 不做背景音乐，只有音效
- 不做关卡系统、成就系统
- 首个版本不上架应用商店（但签名方案为将来上架留好路径）

## 2. 技术栈

| 关注点 | 选型 | 理由 |
| --- | --- | --- |
| SDK | Flutter 3.47.2 stable / Dart 3.13.2（CI 中 pin 死版本） | 当前 stable，pin 版本避免 CI 漂移 |
| 状态管理 / DI | Riverpod 3，手写 Notifier，不使用 code generation | 跨屏共享音频服务与存档需要 DI；测试可用 ProviderContainer override；不引入 build_runner 以保持构建链简单 |
| 路由 | go_router，路由表由游戏注册表动态生成 | 新增游戏无需手写路由 |
| 音频 | flutter_soloud | Flutter 官方 cookbook 推荐的游戏音频方案：低延迟、内存预加载、变速变调、sample-accurate 调度 |
| 持久化 | shared_preferences | 只需存最高分与静音开关 |
| 渲染 | 纯 Flutter Widget + 隐式动画 | 三款均为离散网格回合制游戏，Widget 树足够且更简单 |
| 静态检查 | flutter_lints + `flutter analyze --fatal-infos` | 作为 CI 门禁 |
| 测试 | flutter_test；核心规则为纯 Dart 单元测试 | 本地秒级反馈 |

### 被否决的方案

- **Flame 游戏引擎**：面向有游戏循环的实时游戏。三款首发游戏都是离散网格回合制，引入 Flame 等于放弃 Widget 树的布局、主题与无障碍能力，换取用不上的 Canvas 循环。注意本设计并不排斥它：`GameDefinition.build()` 返回 Widget，将来某款实时游戏内部可以直接嵌入 Flame 的 `GameWidget`。
- **melos 多包 monorepo**：隔离最彻底，但三款游戏就上多包会让 CI 时间与构建配置复杂度翻倍。本设计的目录边界即按未来的包边界划分，游戏数量增长后再拆包成本很低。

## 3. 架构

### 3.1 核心契约

全部扩展性集中在一个不可变契约上：

```dart
@immutable
class GameDefinition {
  final String id;        // 路由 path、存档 key、音效场景 key
  final String title;
  final String tagline;
  final IconData icon;
  final Color accent;     // 首页方块配色
  final Widget Function(BuildContext) build;
}
```

### 3.2 目录结构

```
lib/
  main.dart
  app/
    app.dart                  MaterialApp.router + 主题
    router.dart               由注册表生成路由
    theme.dart                Material 3 + seed color
  core/
    game/
      game_definition.dart    游戏契约
      game_registry.dart      注册表
      game_scaffold.dart      统一游戏外壳：返回、重开、分数、静音
    audio/
      sfx.dart                音效枚举
      audio_service.dart      flutter_soloud 封装 + 连击升调 + 同帧限流
      audio_providers.dart
    storage/
      score_repository.dart   最高分与设置
    haptics/
      haptics.dart
    widgets/
      responsive_board.dart   响应式正方形棋盘容器
  games/
    game2048/
      domain/                 纯 Dart 规则，零 Flutter 依赖
      presentation/
      game2048_definition.dart
    sliding_puzzle/           同上
    tap_match/                同上
  games_registry.dart         新增游戏时唯一需要改动的文件
test/
assets/audio/
```

新增一款游戏 = 新建一个 `games/<name>/` 目录 + 在 `games_registry.dart` 增加一行。首页列表、路由、游戏外壳、音效系统、最高分存储全部自动接入，不触碰任何既有游戏代码。

### 3.3 数据流

每款游戏内部使用 `Notifier<GameState>` 持有不可变状态，UI 只读。

```
用户操作 → domain 纯函数 → (新 GameState, 事件列表) → Notifier 提交状态
                                              └→ AudioService / Haptics
```

domain 层是纯函数：输入旧状态与操作，输出新状态和一组描述「发生了什么」的事件（合并了几次、消除了几块、是否非法操作、是否结束）。副作用集中在 Notifier 一处。这既是音效系统能拿到丰富语义的前提，也是 domain 能被完整单测覆盖的前提。

## 4. 游戏规则

### 4.1 2048

- 4×4 网格。
- **关键正确性约束**：单次移动中，已经参与合并产生的方块不得再次参与合并（经典实现 bug 点，必须有针对性测试）。
- domain 层不只返回数字网格，而是返回**带稳定 id 的 tile 列表以及 from→to 位置映射**。UI 依据 id 做 `AnimatedPositioned` 滑动与合并缩放，否则动画会退化成闪现。
- 每次有效移动后在随机空位生成新方块：2 的概率 90%，4 的概率 10%。
- 结束判定：无空位且四个方向均不可移动。
- 出现 2048 时提示达成，但允许继续游戏。

### 4.2 数字华容道

- 4×4（15 拼图）。
- **洗牌**：从已解状态出发随机走 200 步合法移动，并避免立即回退上一步；天然保证 100% 可解，无需推导逆序数奇偶性，且更容易测试。洗牌结果若等于已解状态则重洗。
- **移动**：点击与空格同行或同列的任意方块，该方块与空格之间的整排方块一起滑动。不限制为紧邻空格的方块，操作效率显著更高。
- 记录步数与用时；完成时记录最少步数。

### 4.3 点点消消乐

- 10 列 × 14 行，5 种颜色。
- 点击 → 4-邻接 flood fill 求同色连通块。
- **连通块大小 ≥ 2 才可消除**（单块不可消，经典规则）。
- 消除后：方块受重力下落，随后空列向左压缩。
- 计分：`n × (n - 1)`，n 为本次消除块数，鼓励攒大块。
- 结束判定：网格中不存在任何大小 ≥ 2 的同色连通块。
- 点击即消除，不做二次确认，保证畅快感。

## 5. 音效设计

素材来自 Kenney 的 CC0 音效包（Interface Sounds / Impact Sounds 等，公有领域，商用免归因），选取 7 个短 WAV，仓库体积增加约 125 KB。选 WAV 而非 OGG 是因为短音效免解码、启动更快，且镜像仓库提供的就是 WAV。

畅快感由以下技巧共同支撑：

1. **全量预加载**：应用启动后异步将全部音效解码进内存，首次播放零延迟。
2. **连击半音升调**：`playbackRate = pow(2, semitones / 12)`，每级 **+2 个半音**（大二度，比 +1 半音递进更可闻且不刺耳），封顶 +14 半音，连击中断即复位。2048 中一次滑动内第 k 次合并逐级升调；消消乐按本次消除块数决定起始音高，一次消 12 块直接从高音起。
3. **同帧限流**：同一帧内同种音效最多播放一次，取音高最高的那次。缺少这条时，十几块同时消除会叠加成噪音——这是最容易被忽略的一条。
4. **音量分层**：UI 反馈 0.4、核心正反馈 0.85、负反馈 0.3。失败音效必须明显轻于成功音效，否则长时间游玩会烦躁。
5. **触觉同步**：合并 / 消除配 `HapticFeedback.lightImpact()`，通关配 `mediumImpact()`。安卓端的「畅快」有相当一部分来自震动反馈。
6. **无背景音乐**，仅音效，符合极简定位。
7. **降级永不崩溃**：音频引擎初始化失败或资源缺失时，AudioService 退化为 no-op，游戏功能不受影响。

### 5.1 音效事件映射

| 事件 | 音效 | 音量 | 音高策略 |
| --- | --- | --- | --- |
| 通用点击 / 选中 | click | 0.4 | 固定 |
| 无效操作（不可移动、单块不可消） | error 低音 | 0.3 | 固定 |
| 2048 方块合并 | impact | 0.85 | 本次滑动内第 k 次合并 → +2k 半音 |
| 华容道整排滑动 | slide | 0.5 | 按本次滑动的方块数轻微升调 |
| 消消乐消除 | pop | 0.85 | 起始音高由消除块数决定，连消继续累加 |
| 达成 2048 / 拼图完成 | 上行琶音 | 0.9 | 固定三音序列 |
| 对局结束（死局） | 下行低音 | 0.5 | 固定 |

全局静音开关持久化保存，在游戏外壳上一键切换。

## 6. 错误处理

所有失败路径一律降级，不向上抛出：

- 音频引擎不可用 → 静音继续游戏。音频永远不在关键路径上。
- `shared_preferences` 读取失败 → 最高分按 0 处理，写入失败静默忽略。
- 出现不应发生的非法游戏状态 → debug 构建下 `assert` 暴露，release 构建下重置当前对局。

## 7. 测试策略

本地只安装 Flutter SDK 本体（不装 Android SDK / JDK），`flutter test` 与 `flutter analyze` 秒级反馈；APK 打包一律在 GitHub Actions 进行。

重点覆盖 domain 纯逻辑：

- **2048**：单次移动内二次合并的反例、四个方向的边界行为、得分累计、结束判定、tile id 映射自洽性。
- **数字华容道**：随机洗牌 1000 次全部可解、整排滑动行为、完成判定、步数统计。
- **点点消消乐**：flood fill 正确性、单块不可消、重力下落与空列压缩、计分公式、死局判定。
- **Widget 测试**：首页渲染注册表中的全部条目、点击进入正确路由、静音开关生效。
- AudioService 通过接口注入，测试使用 fake 实现，不触碰真实音频设备。

## 8. CI/CD

两个 workflow：

- **`ci.yml`**（push / PR 触发）：`dart format --set-exit-if-changed` → `flutter analyze --fatal-infos` → `flutter test --coverage`。不需要 Android SDK，预期 1–2 分钟。
- **`release.yml`**（推送 `v*` tag 或手动 `workflow_dispatch`）：执行全套检查，从 Secrets 还原 base64 编码的 keystore，`flutter build apk --release --split-per-abi`，上传为 Actions artifact 并创建 GitHub Release 附带 APK。

均使用 `subosito/flutter-action` 并 pin 到 3.47.2，缓存 pub 与 gradle，配置 concurrency group 取消同分支的过期运行。

**签名**：使用 openssl 在本地生成 PKCS12 keystore（无需 JDK），base64 后经 `gh secret set` 存入仓库 Secrets。签名保持长期稳定，新版本可直接覆盖安装，也为将来上架商店留好路径。私钥文件不进入 git。

## 9. Android 配置

依据 2026 年的平台要求：

- `compileSdk 36` / `targetSdk 36` / `minSdk 24`。自 2026-08-31 起 Google Play 要求新应用与更新必须 target API 36。
- API 36 **不再允许 opt-out edge-to-edge**，因此统一通过 `SafeArea` 与 `SystemUiOverlayStyle` 处理系统栏，不假设固定的系统栏高度。
- API 36 下 600dp 以上大屏**不允许锁定方向**，因此不做方向锁：棋盘统一使用 `LayoutBuilder + AspectRatio` 自适应，竖屏与横屏各一套布局。
- 开启 R8 代码压缩与混淆。
- AndroidManifest 不声明任何权限（含 INTERNET）。

## 10. 交付

- 公开 GitHub 仓库 `lofiski/mini-games`（公开仓库 Actions 额度无限制，Secrets 依然安全）。
- Android `applicationId`：`dev.lofiski.mini_games`（与 namespace 保持一致）。
- 签名 release APK 通过 GitHub Release 分发。
