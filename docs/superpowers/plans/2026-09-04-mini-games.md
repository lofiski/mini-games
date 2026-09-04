# Mini Games 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个极简安卓小游戏合集：打开即见游戏方块列表，点击直接开玩，首批含 2048、数字华容道、点点消消乐三款。

**Architecture:** 单 Flutter 应用，纯 Widget 渲染。全部扩展性集中在一个 `GameDefinition` 契约与一张注册表上——新增游戏只需新建目录并在注册表加一行，首页、路由、游戏外壳、音效、存档自动接入。每款游戏的规则写成零 Flutter 依赖的纯 Dart domain 层，UI 层只做渲染与事件转发，副作用（音效、触觉、存档）集中在 Notifier 一处。

**Tech Stack:** Flutter 3.47.2 / Dart 3.13.2、Riverpod 3（手写 Notifier，无 codegen）、go_router、flutter_soloud、shared_preferences、flutter_lints、GitHub Actions。

**Spec:** `docs/superpowers/specs/2026-09-04-flutter-mini-games-design.md`

## Global Constraints

以下约束适用于每一个 Task，数值直接取自 spec：

- Flutter **3.47.2** stable / Dart **3.13.2**。CI 中 pin 死此版本，不使用 `channel: stable` 的浮动解析。
- Android：`compileSdk 36`、`targetSdk 36`、`minSdk 24`。
- **不得声明任何 Android 权限**，包括 `INTERNET`。
- **不得锁定屏幕方向**（API 36 下 600dp 以上大屏不允许锁方向）。所有棋盘用 `LayoutBuilder` + `AspectRatio` 自适应，竖屏横屏各一套布局。
- **不得 opt-out edge-to-edge**（API 36 已移除该开关）。统一用 `SafeArea` 与 `SystemUiOverlayStyle` 处理系统栏。
- 状态管理一律 Riverpod 3 手写 `Notifier`，**禁止引入 build_runner / codegen**。
- 每款游戏的 `domain/` 目录**禁止 import 任何 `package:flutter/*`**，只允许 `dart:*` 与 `package:meta`。这是 domain 可单测的硬性边界。
- 所有 `GameState` 与 domain 数据结构必须是不可变的（`@immutable` + `final` 字段）。
- 音效音量分层固定为：UI 反馈 `0.4`、核心正反馈 `0.85`、负反馈 `0.3`、通关 `0.9`。
- 连击升调固定为每级 **+2 半音**，封顶 **+14 半音**，`playbackRate = pow(2, semitones / 12)`。
- 音频、存储的任何失败一律降级为 no-op，**禁止向上抛出异常**。游戏功能不得依赖音频可用。
- domain 层的每个公开函数都必须是全函数：越界坐标、点击空格、不可移动的方向等一律返回**未改变的状态**，
  而不是抛异常。spec 第 6 节要求的「非法状态在 release 下重置本局」因此退化为不会发生的情况，
  三款游戏都用这种方式满足该要求。
- APK 打包**只允许在 GitHub Actions 进行**，本地仅执行 `flutter analyze` 与 `flutter test`。
- 本地 Flutter SDK 位于 `C:\Users\mz\sdk\flutter\bin`，通过 `export PATH="/c/Users/mz/sdk/flutter/bin:$PATH"` 使用；本地未安装 Android SDK 与 JDK，因此**本地不能执行任何 `flutter build` 命令**。
- 每个 Task 结束时提交，提交信息使用中文，并附带：
  ```
  Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
  ```

---

## 文件结构

| 文件 | 职责 |
| --- | --- |
| `lib/main.dart` | 启动：初始化存储与音频，注入 ProviderScope |
| `lib/app/app.dart` | `MaterialApp.router` 装配 |
| `lib/app/theme.dart` | Material 3 主题（亮/暗） |
| `lib/app/router.dart` | 由注册表生成 go_router 路由表 |
| `lib/core/game/game_definition.dart` | `GameDefinition` 契约 |
| `lib/core/game/game_registry.dart` | `GameRegistry`，id 唯一性校验 |
| `lib/core/game/game_scaffold.dart` | 统一游戏外壳：返回 / 标题 / 分数 / 最佳 / 重开 / 静音 |
| `lib/core/audio/sfx.dart` | `Sfx` 枚举与资源路径映射 |
| `lib/core/audio/combo_pitch.dart` | 纯函数：连击级别 → 半音数 → playbackRate |
| `lib/core/audio/sfx_throttle.dart` | 纯逻辑：同帧同种音效去重，保留最高音 |
| `lib/core/audio/audio_service.dart` | `AudioService` 接口 + `SilentAudioService` 降级实现 |
| `lib/core/audio/soloud_audio_service.dart` | flutter_soloud 实现 |
| `lib/core/audio/audio_providers.dart` | 音频相关 Riverpod provider |
| `lib/core/storage/settings_store.dart` | `SettingsStore` 接口 + 内存实现 |
| `lib/core/storage/prefs_settings_store.dart` | shared_preferences 实现 |
| `lib/core/storage/storage_providers.dart` | 存储相关 provider |
| `lib/core/haptics/haptics.dart` | 触觉反馈封装（可关闭） |
| `lib/core/widgets/responsive_board.dart` | 自适应正方形棋盘容器 |
| `lib/features/home/home_page.dart` | 首页游戏方块列表 |
| `lib/games/game2048/domain/*.dart` | 2048 规则（纯 Dart） |
| `lib/games/game2048/presentation/*.dart` | 2048 UI 与 Notifier |
| `lib/games/game2048/game2048_definition.dart` | 2048 的 `GameDefinition` |
| `lib/games/sliding_puzzle/**` | 数字华容道，同上结构 |
| `lib/games/tap_match/**` | 点点消消乐，同上结构 |
| `lib/games_registry.dart` | **新增游戏时唯一需要改动的文件** |
| `.github/workflows/ci.yml` | 格式 / 静态检查 / 测试门禁 |
| `.github/workflows/release.yml` | 签名打包并发布 GitHub Release |

---

### Task 1: 项目脚手架与本地工具链

**Files:**
- Create: `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `.gitattributes`, `lib/main.dart`（由 `flutter create` 生成后改写）
- Create: `android/`, `test/`（由 `flutter create` 生成）

**Interfaces:**
- Consumes: 无（首个任务）
- Produces: 可运行的 `flutter analyze` / `flutter test`；包名 `mini_games`；Android `applicationId = dev.lofiski.minigames`

- [ ] **Step 1: 确认本地 SDK 可用**

```bash
export PATH="/c/Users/mz/sdk/flutter/bin:$PATH"
flutter --version
```

Expected: 输出 `Flutter 3.47.2` 与 `Dart 3.13.2`。若提示需要下载 Dart SDK，等待其自动完成。

- [ ] **Step 2: 生成 Android-only 工程骨架**

当前目录已有 `.git` 与 `docs/`，`flutter create` 可在非空目录中运行。

```bash
export PATH="/c/Users/mz/sdk/flutter/bin:$PATH"
flutter create --org dev.lofiski --project-name mini_games --platforms=android --empty .
```

`--empty` 生成不带计数器示例代码的最小骨架。

- [ ] **Step 3: 固定换行符，避免 Windows 上的 CRLF 污染**

创建 `.gitattributes`：

```
* text=auto eol=lf
*.png binary
*.jpg binary
*.ogg binary
*.wav binary
*.p12 binary
*.keystore binary
```

然后规范化已有文件：

```bash
git add --renormalize .
```

- [ ] **Step 4: 补充 .gitignore 的签名与本地产物条目**

在 `flutter create` 生成的 `.gitignore` 末尾追加：

```
# 签名密钥绝不入库
*.p12
*.jks
*.keystore
android/key.properties

# 本地覆盖率产物
coverage/
```

- [ ] **Step 5: 添加运行时依赖**

用 `pub add` 而非手写版本号，让解析器选出与 Dart 3.13.2 兼容的最新版本：

```bash
export PATH="/c/Users/mz/sdk/flutter/bin:$PATH"
flutter pub add flutter_riverpod go_router flutter_soloud shared_preferences
flutter pub add dev:flutter_lints
```

- [ ] **Step 6: 收紧静态检查规则**

改写 `analysis_options.yaml`：

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    - always_declare_return_types
    - avoid_dynamic_calls
    - prefer_final_locals
    - prefer_const_constructors
    - prefer_const_declarations
    - unawaited_futures
    - require_trailing_commas
    - use_super_parameters
    - sort_child_properties_last
```

- [ ] **Step 7: 写一个占位入口，确认工具链闭环**

`lib/main.dart`：

```dart
import 'package:flutter/material.dart';

void main() => runApp(const MiniGamesApp());

class MiniGamesApp extends StatelessWidget {
  const MiniGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Games',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF6750A4)),
      home: const Scaffold(body: Center(child: Text('Mini Games'))),
    );
  }
}
```

`test/smoke_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/main.dart';

void main() {
  testWidgets('应用能够启动并渲染标题', (tester) async {
    await tester.pumpWidget(const MiniGamesApp());
    expect(find.text('Mini Games'), findsOneWidget);
  });
}
```

- [ ] **Step 8: 运行全套本地门禁**

```bash
export PATH="/c/Users/mz/sdk/flutter/bin:$PATH"
dart format .
flutter analyze --fatal-infos
flutter test
```

Expected: analyze 输出 `No issues found!`，test 输出 `All tests passed!`

- [ ] **Step 9: 提交**

```bash
git add -A
git commit -m "$(cat <<'EOF'
chore: 初始化 Flutter 工程骨架

Android-only 工程，applicationId 为 dev.lofiski.minigames，
接入 riverpod / go_router / flutter_soloud / shared_preferences，
收紧 lint 规则并固定换行符为 LF。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
EOF
)"
```

---

### Task 2: GitHub 仓库与 CI 门禁

尽早建立 CI，使后续每一次提交都被自动验证。

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `README.md`

**Interfaces:**
- Consumes: Task 1 产出的可运行工程
- Produces: 远程仓库 `lofiski/mini-games`；每次 push 自动执行格式、静态检查、测试

- [ ] **Step 1: 编写 CI workflow**

`.github/workflows/ci.yml`：

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  verify:
    name: 格式 / 静态检查 / 测试
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.47.2
          channel: stable
          cache: true

      - name: 拉取依赖
        run: flutter pub get

      - name: 检查代码格式
        run: dart format --output=none --set-exit-if-changed .

      - name: 静态分析
        run: flutter analyze --fatal-infos

      - name: 运行测试
        run: flutter test --coverage

      - name: 上传覆盖率
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage/lcov.info
          if-no-files-found: warn
```

注意此 job 不安装 Android SDK——只跑纯 Dart 与 Widget 测试，耗时应在 2 分钟内。

- [ ] **Step 2: 编写 README**

`README.md`：

````markdown
# Mini Games

极简安卓小游戏合集。打开即见游戏列表，点击直接开玩。

## 已收录

| 游戏 | 玩法 |
| --- | --- |
| 2048 | 滑动合并相同数字，目标 2048 |
| 数字华容道 | 滑动方块还原 1–15 顺序 |
| 点点消消乐 | 点击色块，相邻同色连通块整体消除 |

## 下载

前往 [Releases](https://github.com/lofiski/mini-games/releases) 下载签名 APK。
`arm64-v8a` 适用于绝大多数现代安卓手机；不确定时选 `universal`。

## 开发

需要 Flutter 3.47.2。

```bash
flutter pub get
flutter analyze --fatal-infos
flutter test
```

APK 打包统一在 GitHub Actions 进行，不在本地构建。

## 新增一款游戏

1. 在 `lib/games/<game_name>/` 下新建目录，`domain/` 放纯 Dart 规则，`presentation/` 放 UI
2. 导出一个 `GameDefinition`
3. 在 `lib/games_registry.dart` 中加入该定义

首页列表、路由、游戏外壳、音效与最高分存档会自动接入，无需改动任何既有游戏。

## 音效版权

音效素材来自 [Kenney](https://kenney.nl/assets/category:Audio)，CC0 公有领域授权。
````

- [ ] **Step 3: 创建远程仓库并推送**

```bash
gh repo create mini-games --public --source=. --remote=origin --description "极简安卓小游戏合集：2048、数字华容道、点点消消乐" --push
```

- [ ] **Step 4: 确认 CI 通过**

```bash
gh run watch --exit-status
```

Expected: CI 全绿。若失败，读取日志并修复后再提交：

```bash
gh run view --log-failed
```

- [ ] **Step 5: 提交（若 Step 4 有修复）**

```bash
git add -A
git commit -m "$(cat <<'EOF'
ci: 添加格式 / 静态检查 / 测试门禁

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
EOF
)"
git push
```

---

### Task 3: 游戏契约与注册表

这是整个架构开放性的支点。

**Files:**
- Create: `lib/core/game/game_definition.dart`
- Create: `lib/core/game/game_registry.dart`
- Create: `lib/games_registry.dart`
- Test: `test/core/game/game_registry_test.dart`

**Interfaces:**
- Consumes: Task 1 的工程骨架
- Produces:
  - `class GameDefinition { final String id; final String title; final String tagline; final IconData icon; final Color accent; final WidgetBuilder builder; }`
  - `class GameRegistry { GameRegistry(List<GameDefinition> games); List<GameDefinition> get games; GameDefinition? byId(String id); }`
  - `final GameRegistry gameRegistry;`（`lib/games_registry.dart`，初始为空列表）

- [ ] **Step 1: 写失败的测试**

`test/core/game/game_registry_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/core/game/game_definition.dart';
import 'package:mini_games/core/game/game_registry.dart';

GameDefinition _def(String id) => GameDefinition(
      id: id,
      title: id,
      tagline: '测试用',
      icon: Icons.games,
      accent: const Color(0xFF000000),
      builder: (_) => const SizedBox.shrink(),
    );

void main() {
  test('按 id 查找已注册的游戏', () {
    final registry = GameRegistry([_def('a'), _def('b')]);
    expect(registry.byId('b')?.id, 'b');
  });

  test('查找不存在的 id 返回 null', () {
    final registry = GameRegistry([_def('a')]);
    expect(registry.byId('missing'), isNull);
  });

  test('games 保持注册时的顺序', () {
    final registry = GameRegistry([_def('a'), _def('b'), _def('c')]);
    expect(registry.games.map((g) => g.id).toList(), ['a', 'b', 'c']);
  });

  test('重复 id 在构造时即被拒绝', () {
    expect(() => GameRegistry([_def('a'), _def('a')]), throwsArgumentError);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/core/game/game_registry_test.dart`
Expected: 编译失败，提示找不到 `game_definition.dart`。

- [ ] **Step 3: 实现契约**

`lib/core/game/game_definition.dart`：

```dart
import 'package:flutter/widgets.dart';

/// 一款游戏对外暴露的全部信息。
///
/// 新增游戏时实现此契约并注册到 GameRegistry 即可，
/// 首页列表、路由、游戏外壳、音效与存档会自动接入。
@immutable
class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.accent,
    required this.builder,
  });

  /// 稳定标识，同时用作路由 path 与最高分存档 key。注册后不应更改。
  final String id;

  /// 首页方块上显示的游戏名。
  final String title;

  /// 一句话玩法说明。
  final String tagline;

  /// 首页方块图标。
  final IconData icon;

  /// 首页方块主色，同时作为游戏内强调色。
  final Color accent;

  /// 构建游戏主界面。返回类型是 Widget，
  /// 因此将来某款实时游戏内部改用 Flame 的 GameWidget 也不破坏本契约。
  final WidgetBuilder builder;
}
```

`lib/core/game/game_registry.dart`：

```dart
import 'game_definition.dart';

/// 全部已注册游戏的有序集合。
class GameRegistry {
  GameRegistry(this.games) {
    final seen = <String>{};
    for (final game in games) {
      if (!seen.add(game.id)) {
        throw ArgumentError.value(game.id, 'games', '游戏 id 重复');
      }
    }
  }

  /// 注册顺序即首页展示顺序。
  final List<GameDefinition> games;

  GameDefinition? byId(String id) {
    for (final game in games) {
      if (game.id == id) return game;
    }
    return null;
  }
}
```

`lib/games_registry.dart`：

```dart
import 'core/game/game_registry.dart';

/// 新增游戏的唯一改动点：在下面的列表中加入该游戏的 GameDefinition。
final GameRegistry gameRegistry = GameRegistry(const []);
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/core/game/game_registry_test.dart`
Expected: 4 个测试全部 PASS。

- [ ] **Step 5: 提交**

```bash
dart format . && flutter analyze --fatal-infos && flutter test
git add -A && git commit -F- <<'MSG'
feat: 添加游戏契约与注册表

GameDefinition 定义一款游戏对外暴露的全部信息，GameRegistry
负责有序保存并校验 id 唯一。新增游戏只需实现契约并注册。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
MSG
git push
```

---

### Task 4: 存储层

**Files:**
- Create: `lib/core/storage/settings_store.dart`
- Create: `lib/core/storage/prefs_settings_store.dart`
- Create: `lib/core/storage/storage_providers.dart`
- Test: `test/core/storage/settings_store_test.dart`

**Interfaces:**
- Consumes: Task 3
- Produces:
  - `abstract interface class SettingsStore { int highScore(String gameId); Future<void> setHighScore(String gameId, int value); bool get muted; Future<void> setMuted(bool value); }`
  - `class InMemorySettingsStore implements SettingsStore`
  - `class PrefsSettingsStore implements SettingsStore { static Future<SettingsStore> create(); }`
  - `final Provider<SettingsStore> settingsStoreProvider`（未 override 时抛错，由 main 注入）
  - `class HighScoreNotifier extends Notifier<int> { bool submit(int score); }`
  - `final highScoreProvider = NotifierProvider.family<HighScoreNotifier, int, String>(...)`

读取设计为同步（启动时一次性载入内存），避免在 UI 层引入 async provider，这是「保持最简」的关键取舍。

- [ ] **Step 1: 写失败的测试**

`test/core/storage/settings_store_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/core/storage/settings_store.dart';

void main() {
  test('未记录过的游戏最高分为 0', () {
    expect(InMemorySettingsStore().highScore('game2048'), 0);
  });

  test('写入后能读回最高分', () async {
    final store = InMemorySettingsStore();
    await store.setHighScore('game2048', 1024);
    expect(store.highScore('game2048'), 1024);
  });

  test('不同游戏的最高分互不干扰', () async {
    final store = InMemorySettingsStore();
    await store.setHighScore('game2048', 1024);
    await store.setHighScore('tap_match', 300);
    expect(store.highScore('game2048'), 1024);
    expect(store.highScore('tap_match'), 300);
  });

  test('静音开关默认关闭且可切换', () async {
    final store = InMemorySettingsStore();
    expect(store.muted, isFalse);
    await store.setMuted(true);
    expect(store.muted, isTrue);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/core/storage/settings_store_test.dart`
Expected: 编译失败，找不到 `settings_store.dart`。

- [ ] **Step 3: 实现存储接口与内存实现**

`lib/core/storage/settings_store.dart`：

```dart
/// 应用设置与最高分的读写。
///
/// 读同步、写异步：启动时一次性把数据载入内存，
/// UI 层因此不需要处理 async 状态。
abstract interface class SettingsStore {
  int highScore(String gameId);

  Future<void> setHighScore(String gameId, int value);

  bool get muted;

  Future<void> setMuted(bool value);
}

/// 测试与降级场景使用的内存实现。
class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore({Map<String, int>? scores, bool muted = false})
      : _scores = {...?scores},
        _muted = muted;

  final Map<String, int> _scores;
  bool _muted;

  @override
  int highScore(String gameId) => _scores[gameId] ?? 0;

  @override
  Future<void> setHighScore(String gameId, int value) async {
    _scores[gameId] = value;
  }

  @override
  bool get muted => _muted;

  @override
  Future<void> setMuted(bool value) async {
    _muted = value;
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/core/storage/settings_store_test.dart`
Expected: 4 个测试 PASS。

- [ ] **Step 5: 实现 shared_preferences 后端**

`lib/core/storage/prefs_settings_store.dart`：

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_store.dart';

/// shared_preferences 后端。
///
/// 任何读写失败都降级处理，绝不向上抛出：
/// 存档丢失可以接受，游戏崩溃不可以。
class PrefsSettingsStore implements SettingsStore {
  PrefsSettingsStore._(this._prefs, this._scores, this._muted);

  static const String _mutedKey = 'settings.muted';
  static const String _scorePrefix = 'highscore.';

  final SharedPreferences _prefs;
  final Map<String, int> _scores;
  bool _muted;

  /// 载入全部设置。失败时回退到内存实现，调用方无需处理异常。
  static Future<SettingsStore> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scores = <String, int>{};
      for (final key in prefs.getKeys()) {
        if (key.startsWith(_scorePrefix)) {
          final value = prefs.getInt(key);
          if (value != null) {
            scores[key.substring(_scorePrefix.length)] = value;
          }
        }
      }
      return PrefsSettingsStore._(
        prefs,
        scores,
        prefs.getBool(_mutedKey) ?? false,
      );
    } on Object catch (error, stack) {
      debugPrint('设置载入失败，降级为内存存储: $error\n$stack');
      return InMemorySettingsStore();
    }
  }

  @override
  int highScore(String gameId) => _scores[gameId] ?? 0;

  @override
  Future<void> setHighScore(String gameId, int value) async {
    _scores[gameId] = value;
    try {
      await _prefs.setInt('$_scorePrefix$gameId', value);
    } on Object catch (error) {
      debugPrint('最高分写入失败: $error');
    }
  }

  @override
  bool get muted => _muted;

  @override
  Future<void> setMuted(bool value) async {
    _muted = value;
    try {
      await _prefs.setBool(_mutedKey, value);
    } on Object catch (error) {
      debugPrint('静音设置写入失败: $error');
    }
  }
}
```

- [ ] **Step 6: 实现 provider**

`lib/core/storage/storage_providers.dart`：

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_store.dart';

/// 由 main() 在启动时 override 注入具体实现。
final Provider<SettingsStore> settingsStoreProvider = Provider<SettingsStore>(
  (ref) => throw StateError('settingsStoreProvider 必须在 ProviderScope 中被 override'),
);

/// 某款游戏的最高分。只在超过历史记录时才更新。
class HighScoreNotifier extends Notifier<int> {
  HighScoreNotifier(this.gameId);

  final String gameId;

  @override
  int build() => ref.read(settingsStoreProvider).highScore(gameId);

  /// 提交一局的得分，返回是否刷新了记录。
  bool submit(int score) {
    if (score <= state) return false;
    state = score;
    unawaited(ref.read(settingsStoreProvider).setHighScore(gameId, score));
    return true;
  }
}

final highScoreProvider =
    NotifierProvider.family<HighScoreNotifier, int, String>(
  HighScoreNotifier.new,
);
```

- [ ] **Step 7: 全套门禁并提交**

```bash
dart format . && flutter analyze --fatal-infos && flutter test
git add -A && git commit -F- <<'MSG'
feat: 添加设置与最高分存储层

读同步写异步，启动时一次性载入内存以避免 UI 层引入 async 状态。
读写失败一律降级为内存存储，不向上抛出异常。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
MSG
git push
```

---

### Task 5: 音效系统

音效是本项目「畅快感」的主要来源，因此把可测的部分（升调计算、同帧限流）拆成纯逻辑单独测试，
只把真正调用音频引擎的薄壳留给不可测的实现类。

**Files:**
- Create: `lib/core/audio/sfx.dart`
- Create: `lib/core/audio/combo_pitch.dart`
- Create: `lib/core/audio/sfx_throttle.dart`
- Create: `lib/core/audio/audio_service.dart`
- Create: `lib/core/audio/soloud_audio_service.dart`
- Create: `lib/core/audio/audio_providers.dart`
- Create: `lib/core/haptics/haptics.dart`
- Create: `assets/audio/*.ogg`（7 个 CC0 音效）
- Modify: `pubspec.yaml`（声明 assets）
- Test: `test/core/audio/combo_pitch_test.dart`, `test/core/audio/sfx_throttle_test.dart`

**Interfaces:**
- Consumes: Task 4 的 `SettingsStore`
- Produces:
  - `enum Sfx { tap, invalid, merge, slide, pop, win, gameOver }`，`String assetPathFor(Sfx sfx)`
  - `int comboSemitones(int comboIndex)`、`double playbackRateForSemitones(int semitones)`
  - `const double kVolumeUi = 0.4; kVolumeReward = 0.85; kVolumeNegative = 0.3; kVolumeWin = 0.9;`
  - `class SfxRequest { final Sfx sfx; final int semitones; final double volume; }`
  - `class SfxThrottle { void add(SfxRequest r); List<SfxRequest> flush(); bool get isEmpty; }`
  - `abstract interface class AudioService { Future<void> init(); void play(Sfx sfx, {int comboIndex, double? volume}); bool get muted; Future<void> setMuted(bool value); Future<void> dispose(); }`
  - `class SilentAudioService implements AudioService`
  - `class SoLoudAudioService implements AudioService`
  - `final Provider<AudioService> audioServiceProvider`（由 main override）
  - `class Haptics { static void light(); static void medium(); }`

- [ ] **Step 1: 获取 CC0 音效素材**

从 Kenney 的 CC0 音效包中挑选 7 个短音，放入 `assets/audio/`，统一重命名：

| 文件名 | 用途 | 来源包 |
| --- | --- | --- |
| `tap.ogg` | 通用点击 / 选中 | Interface Sounds |
| `invalid.ogg` | 无效操作 | Interface Sounds |
| `merge.ogg` | 2048 合并 | Impact Sounds |
| `slide.ogg` | 华容道滑动 | Interface Sounds |
| `pop.ogg` | 消消乐消除 | Impact Sounds |
| `win.ogg` | 通关 / 达成 2048 | Interface Sounds |
| `game_over.ogg` | 对局结束 | Interface Sounds |

```bash
mkdir -p assets/audio
curl -L -o /tmp/interface.zip https://kenney.nl/media/pages/assets/interface-sounds/<实际下载路径>
```

Kenney 的下载直链会变动，执行时先访问 `https://kenney.nl/assets/interface-sounds` 与
`https://kenney.nl/assets/impact-sounds` 确认当前 zip 地址。若直链不可用，改用镜像仓库
`https://github.com/Calinou/kenney-interface-sounds`（同为 CC0）：

```bash
git clone --depth 1 https://github.com/Calinou/kenney-interface-sounds /tmp/kenney-interface
git clone --depth 1 https://github.com/Calinou/kenney-ui-audio /tmp/kenney-ui
```

挑选后确认每个文件时长小于 0.5 秒、体积小于 30KB，并在 `README.md` 的音效版权段落中保留 CC0 声明。

- [ ] **Step 2: 在 pubspec.yaml 声明资源**

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/audio/
```

- [ ] **Step 3: 写升调与限流的失败测试**

`test/core/audio/combo_pitch_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/core/audio/combo_pitch.dart';

void main() {
  test('连击第 0 级不升调', () {
    expect(comboSemitones(0), 0);
  });

  test('每级升 2 个半音', () {
    expect(comboSemitones(1), 2);
    expect(comboSemitones(3), 6);
  });

  test('升调封顶在 14 个半音', () {
    expect(comboSemitones(7), 14);
    expect(comboSemitones(100), 14);
  });

  test('负数连击级别按 0 处理', () {
    expect(comboSemitones(-1), 0);
  });

  test('0 半音对应原速播放', () {
    expect(playbackRateForSemitones(0), closeTo(1.0, 1e-9));
  });

  test('12 个半音对应两倍速，即升高一个八度', () {
    expect(playbackRateForSemitones(12), closeTo(2.0, 1e-9));
  });
}
```

`test/core/audio/sfx_throttle_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/core/audio/sfx.dart';
import 'package:mini_games/core/audio/sfx_throttle.dart';

void main() {
  test('同一帧内同种音效只保留音高最高的一次', () {
    final throttle = SfxThrottle()
      ..add(const SfxRequest(Sfx.pop, semitones: 2, volume: 0.85))
      ..add(const SfxRequest(Sfx.pop, semitones: 8, volume: 0.85))
      ..add(const SfxRequest(Sfx.pop, semitones: 4, volume: 0.85));

    final flushed = throttle.flush();

    expect(flushed, hasLength(1));
    expect(flushed.single.semitones, 8);
  });

  test('不同种音效互不影响', () {
    final throttle = SfxThrottle()
      ..add(const SfxRequest(Sfx.pop, semitones: 2, volume: 0.85))
      ..add(const SfxRequest(Sfx.tap, semitones: 0, volume: 0.4));

    expect(throttle.flush(), hasLength(2));
  });

  test('flush 之后清空', () {
    final throttle = SfxThrottle()
      ..add(const SfxRequest(Sfx.pop, semitones: 2, volume: 0.85));

    throttle.flush();

    expect(throttle.isEmpty, isTrue);
    expect(throttle.flush(), isEmpty);
  });
}
```

- [ ] **Step 4: 运行测试确认失败**

Run: `flutter test test/core/audio/`
Expected: 编译失败，找不到 `combo_pitch.dart` 与 `sfx_throttle.dart`。

- [ ] **Step 5: 实现纯逻辑部分**

`lib/core/audio/sfx.dart`：

```dart
/// 全部音效种类。新增音效时在此扩展并补充 assetPathFor 的分支。
enum Sfx { tap, invalid, merge, slide, pop, win, gameOver }

/// 音量分层。失败音效必须明显轻于成功音效，否则长时间游玩会烦躁。
const double kVolumeUi = 0.4;
const double kVolumeReward = 0.85;
const double kVolumeNegative = 0.3;
const double kVolumeWin = 0.9;

String assetPathFor(Sfx sfx) {
  switch (sfx) {
    case Sfx.tap:
      return 'assets/audio/tap.ogg';
    case Sfx.invalid:
      return 'assets/audio/invalid.ogg';
    case Sfx.merge:
      return 'assets/audio/merge.ogg';
    case Sfx.slide:
      return 'assets/audio/slide.ogg';
    case Sfx.pop:
      return 'assets/audio/pop.ogg';
    case Sfx.win:
      return 'assets/audio/win.ogg';
    case Sfx.gameOver:
      return 'assets/audio/game_over.ogg';
  }
}
```

`lib/core/audio/combo_pitch.dart`：

```dart
import 'dart:math' as math;

/// 连击每升一级抬高的半音数。取 2（大二度）而非 1，
/// 递进更可闻，长连击也不刺耳。
const int kComboStepSemitones = 2;

/// 升调封顶，避免长连击把音效推到尖锐失真。
const int kComboMaxSemitones = 14;

/// 连击级别对应的半音数。
int comboSemitones(int comboIndex) {
  if (comboIndex <= 0) return 0;
  final raw = comboIndex * kComboStepSemitones;
  return raw > kComboMaxSemitones ? kComboMaxSemitones : raw;
}

/// 半音数换算为播放速率：升高 12 个半音即两倍速。
double playbackRateForSemitones(int semitones) =>
    math.pow(2, semitones / 12).toDouble();
```

`lib/core/audio/sfx_throttle.dart`：

```dart
import 'package:flutter/foundation.dart';

import 'sfx.dart';

@immutable
class SfxRequest {
  const SfxRequest(this.sfx, {this.semitones = 0, required this.volume});

  final Sfx sfx;
  final int semitones;
  final double volume;
}

/// 同帧限流：一帧内同种音效只播一次，保留音高最高的那次。
///
/// 没有这一层时，十几个方块同时消除会把同一音效叠加成噪音——
/// 这是最容易被忽略、却对听感影响最大的一条。
class SfxThrottle {
  final Map<Sfx, SfxRequest> _pending = <Sfx, SfxRequest>{};

  void add(SfxRequest request) {
    final existing = _pending[request.sfx];
    if (existing == null || request.semitones > existing.semitones) {
      _pending[request.sfx] = request;
    }
  }

  bool get isEmpty => _pending.isEmpty;

  List<SfxRequest> flush() {
    final flushed = _pending.values.toList(growable: false);
    _pending.clear();
    return flushed;
  }
}
```

- [ ] **Step 6: 运行测试确认通过**

Run: `flutter test test/core/audio/`
Expected: 9 个测试全部 PASS。

- [ ] **Step 7: 实现音频服务接口与静音降级实现**

`lib/core/audio/audio_service.dart`：

```dart
import 'sfx.dart';

/// 音效播放。
///
/// 所有实现都必须遵守：任何失败都吞掉并降级，绝不抛出。
/// 音频永远不在游戏的关键路径上。
abstract interface class AudioService {
  Future<void> init();

  /// 播放一个音效。[comboIndex] 为连击级别，0 表示不升调。
  void play(Sfx sfx, {int comboIndex = 0, double? volume});

  bool get muted;

  Future<void> setMuted(bool value);

  Future<void> dispose();
}

/// 音频不可用时的降级实现，同时用于单元测试。
class SilentAudioService implements AudioService {
  SilentAudioService({bool muted = false}) : _muted = muted;

  bool _muted;

  /// 测试用：记录收到的播放请求。
  final List<Sfx> played = <Sfx>[];

  @override
  Future<void> init() async {}

  @override
  void play(Sfx sfx, {int comboIndex = 0, double? volume}) {
    if (!_muted) played.add(sfx);
  }

  @override
  bool get muted => _muted;

  @override
  Future<void> setMuted(bool value) async {
    _muted = value;
  }

  @override
  Future<void> dispose() async {}
}
```

- [ ] **Step 8: 实现 flutter_soloud 后端**

`lib/core/audio/soloud_audio_service.dart`：

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'audio_service.dart';
import 'combo_pitch.dart';
import 'sfx.dart';
import 'sfx_throttle.dart';

/// flutter_soloud 后端：启动时把全部音效解码进内存，播放零延迟。
///
/// 初始化失败时 [_ready] 保持 false，此后所有 play 调用静默丢弃，
/// 游戏功能不受影响。
class SoLoudAudioService implements AudioService {
  SoLoudAudioService({required bool muted}) : _muted = muted;

  final Map<Sfx, AudioSource> _sources = <Sfx, AudioSource>{};
  final SfxThrottle _throttle = SfxThrottle();
  bool _ready = false;
  bool _flushScheduled = false;
  bool _muted;

  @override
  Future<void> init() async {
    try {
      await SoLoud.instance.init();
      for (final sfx in Sfx.values) {
        _sources[sfx] = await SoLoud.instance.loadAsset(assetPathFor(sfx));
      }
      _ready = true;
    } on Object catch (error, stack) {
      debugPrint('音频初始化失败，本次运行将静音: $error\n$stack');
      _ready = false;
    }
  }

  @override
  void play(Sfx sfx, {int comboIndex = 0, double? volume}) {
    if (!_ready || _muted) return;
    _throttle.add(
      SfxRequest(
        sfx,
        semitones: comboSemitones(comboIndex),
        volume: volume ?? kVolumeReward,
      ),
    );
    _scheduleFlush();
  }

  /// 把本帧内累积的请求合并到帧末统一播放，实现同帧限流。
  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    scheduleMicrotask(() {
      _flushScheduled = false;
      for (final request in _throttle.flush()) {
        unawaited(_playNow(request));
      }
    });
  }

  Future<void> _playNow(SfxRequest request) async {
    final source = _sources[request.sfx];
    if (source == null) return;
    try {
      final handle = await SoLoud.instance.play(source, volume: request.volume);
      if (request.semitones != 0) {
        SoLoud.instance.setRelativePlaySpeed(
          handle,
          playbackRateForSemitones(request.semitones),
        );
      }
    } on Object catch (error) {
      debugPrint('音效播放失败: $error');
    }
  }

  @override
  bool get muted => _muted;

  @override
  Future<void> setMuted(bool value) async {
    _muted = value;
  }

  @override
  Future<void> dispose() async {
    if (!_ready) return;
    try {
      SoLoud.instance.deinit();
    } on Object catch (error) {
      debugPrint('音频释放失败: $error');
    }
  }
}
```

执行时用 `flutter pub deps` 确认 flutter_soloud 的实际 API 名称（`setRelativePlaySpeed`、`loadAsset`、`deinit`）；
若上游有改动，以 `.pub-cache` 中的实际签名为准并同步修改本文件。`SchedulerBinding` 的 import 若未使用则删除。

- [ ] **Step 9: 实现 provider 与触觉封装**

`lib/core/audio/audio_providers.dart`：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_service.dart';

/// 由 main() 在启动时 override 注入具体实现。
final Provider<AudioService> audioServiceProvider = Provider<AudioService>(
  (ref) => SilentAudioService(),
);

/// 全局静音开关，切换时同步落盘。
class MutedNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(audioServiceProvider).muted;

  Future<void> toggle() async {
    final next = !state;
    state = next;
    await ref.read(audioServiceProvider).setMuted(next);
  }
}

final mutedProvider = NotifierProvider<MutedNotifier, bool>(MutedNotifier.new);
```

`lib/core/haptics/haptics.dart`：

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 触觉反馈。安卓端的「畅快」有相当一部分来自震动，
/// 因此每个正反馈音效都配一次轻震动。
class Haptics {
  const Haptics._();

  static void light() => _guard(HapticFeedback.lightImpact);

  static void medium() => _guard(HapticFeedback.mediumImpact);

  static void selection() => _guard(HapticFeedback.selectionClick);

  static void _guard(Future<void> Function() action) {
    action().catchError((Object error) {
      debugPrint('触觉反馈不可用: $error');
    });
  }
}
```

- [ ] **Step 10: 全套门禁并提交**

```bash
dart format . && flutter analyze --fatal-infos && flutter test
git add -A && git commit -F- <<'MSG'
feat: 添加音效系统

连击升调与同帧限流拆为纯逻辑并单独测试；flutter_soloud 后端
在启动时预加载全部音效，初始化失败时静默降级为无声。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
MSG
git push
```

---

### Task 6: 主题、首页、路由与游戏外壳

**Files:**
- Create: `lib/app/theme.dart`, `lib/app/router.dart`, `lib/app/app.dart`
- Create: `lib/features/home/home_page.dart`
- Create: `lib/core/game/game_scaffold.dart`
- Create: `lib/core/widgets/responsive_board.dart`
- Modify: `lib/main.dart`
- Test: `test/features/home/home_page_test.dart`

**Interfaces:**
- Consumes: Task 3 的 `GameRegistry`、Task 4 的 `settingsStoreProvider`、Task 5 的 `audioServiceProvider` 与 `mutedProvider`
- Produces:
  - `ThemeData buildLightTheme(); ThemeData buildDarkTheme();`
  - `GoRouter buildRouter(GameRegistry registry)`
  - `class HomePage extends ConsumerWidget`
  - `class GameScaffold extends ConsumerWidget { GameScaffold({required GameDefinition definition, required int score, required int best, required VoidCallback onRestart, required Widget child, Widget? banner}); }`
  - `class ResponsiveBoard extends StatelessWidget { ResponsiveBoard({required Widget child, double maxSize = 520}); }`

- [ ] **Step 1: 写首页的失败测试**

`test/features/home/home_page_test.dart`：

```dart
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
      overrides: [
        settingsStoreProvider.overrideWithValue(InMemorySettingsStore()),
      ],
      child: MiniGamesApp(registry: registry),
    );

void main() {
  testWidgets('首页渲染注册表中的全部游戏', (tester) async {
    await tester.pumpWidget(_app(GameRegistry([_def('a', '游戏甲'), _def('b', '游戏乙')])));
    await tester.pumpAndSettle();

    expect(find.text('游戏甲'), findsOneWidget);
    expect(find.text('游戏乙'), findsOneWidget);
  });

  testWidgets('点击方块进入对应游戏', (tester) async {
    await tester.pumpWidget(_app(GameRegistry([_def('a', '游戏甲'), _def('b', '游戏乙')])));
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
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/features/home/home_page_test.dart`
Expected: 编译失败，找不到 `app.dart`。

- [ ] **Step 3: 实现主题**

`lib/app/theme.dart`：

```dart
import 'package:flutter/material.dart';

const Color _seed = Color(0xFF4C8BF5);

ThemeData buildLightTheme() => _base(Brightness.light);

ThemeData buildDarkTheme() => _base(Brightness.dark);

ThemeData _base(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  final typography = Typography.material2021();
  // 必须按 brightness 选择基础字色，否则暗色模式下文字会是黑的。
  final base = brightness == Brightness.dark ? typography.white : typography.black;
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
```

- [ ] **Step 4: 实现自适应棋盘容器**

`lib/core/widgets/responsive_board.dart`：

```dart
import 'package:flutter/material.dart';

/// 居中的自适应正方形棋盘容器。
///
/// API 36 起 600dp 以上大屏不允许锁定方向，因此棋盘尺寸
/// 必须由可用空间推导，不能假设竖屏或固定尺寸。
class ResponsiveBoard extends StatelessWidget {
  const ResponsiveBoard({
    super.key,
    required this.child,
    this.maxSize = 520,
    this.aspectRatio = 1,
  });

  final Widget child;
  final double maxSize;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.biggest;
          var width = available.width;
          var height = width / aspectRatio;
          if (height > available.height) {
            height = available.height;
            width = height * aspectRatio;
          }
          if (width > maxSize) {
            width = maxSize;
            height = maxSize / aspectRatio;
          }
          return SizedBox(width: width, height: height, child: child);
        },
      ),
    );
  }
}
```

- [ ] **Step 5: 实现游戏外壳**

`lib/core/game/game_scaffold.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_providers.dart';
import '../audio/sfx.dart';
import 'game_definition.dart';

/// 所有游戏共用的外壳：返回、标题、当前分、最佳分、重开、静音。
///
/// 新游戏接入后自动获得这些能力，无需各自实现。
class GameScaffold extends ConsumerWidget {
  const GameScaffold({
    super.key,
    required this.definition,
    required this.score,
    required this.best,
    required this.onRestart,
    required this.child,
    this.banner,
    this.scoreLabel = '分数',
    this.bestLabel = '最佳',
  });

  final GameDefinition definition;
  final int score;
  final int best;
  final VoidCallback onRestart;
  final Widget child;

  /// 通关或结束时显示在棋盘上方的提示条。
  final Widget? banner;

  final String scoreLabel;
  final String bestLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = ref.watch(mutedProvider);
    final audio = ref.read(audioServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              definition: definition,
              muted: muted,
              onToggleMute: () => ref.read(mutedProvider.notifier).toggle(),
              onRestart: () {
                audio.play(Sfx.tap, volume: kVolumeUi);
                onRestart();
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _ScoreChip(label: scoreLabel, value: score, accent: definition.accent),
                  const SizedBox(width: 12),
                  _ScoreChip(label: bestLabel, value: best, accent: definition.accent),
                ],
              ),
            ),
            if (banner != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: banner,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.definition,
    required this.muted,
    required this.onToggleMute,
    required this.onRestart,
  });

  final GameDefinition definition;
  final bool muted;
  final VoidCallback onToggleMute;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回',
          ),
          Expanded(
            child: Text(
              definition.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            onPressed: onToggleMute,
            icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
            tooltip: muted ? '取消静音' : '静音',
          ),
          IconButton(
            onPressed: onRestart,
            icon: const Icon(Icons.refresh),
            tooltip: '重新开始',
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value, required this.accent});

  final String label;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                '$value',
                key: ValueKey<int>(value),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: 实现首页**

`lib/features/home/home_page.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/sfx.dart';
import '../../core/game/game_definition.dart';
import '../../core/game/game_registry.dart';
import '../../core/haptics/haptics.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.registry});

  final GameRegistry registry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 220).floor().clamp(2, 4);
            return CustomScrollView(
              slivers: [
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                  sliver: SliverToBoxAdapter(child: _Header()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: registry.games.length,
                    itemBuilder: (context, index) {
                      final game = registry.games[index];
                      return _GameTile(
                        game: game,
                        onTap: () {
                          ref.read(audioServiceProvider).play(Sfx.tap, volume: kVolumeUi);
                          Haptics.selection();
                          context.go('/${game.id}');
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Mini Games',
      style: Theme.of(context)
          .textTheme
          .headlineMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game, required this.onTap});

  final GameDefinition game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: game.accent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(game.icon, size: 32, color: Colors.white),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    game.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    game.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: 实现路由与应用装配**

`lib/app/router.dart`：

```dart
import 'package:go_router/go_router.dart';

import '../core/game/game_registry.dart';
import '../features/home/home_page.dart';

/// 路由表由注册表生成，新增游戏无需在此改动。
GoRouter buildRouter(GameRegistry registry) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomePage(registry: registry),
        routes: [
          for (final game in registry.games)
            GoRoute(
              path: game.id,
              builder: (context, state) => game.builder(context),
            ),
        ],
      ),
    ],
  );
}
```

`lib/app/app.dart`：

```dart
import 'package:flutter/material.dart';

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
  late final _router = buildRouter(widget.registry);

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
```

`lib/main.dart`：

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/audio/audio_providers.dart';
import 'core/audio/audio_service.dart';
import 'core/audio/soloud_audio_service.dart';
import 'core/storage/prefs_settings_store.dart';
import 'core/storage/storage_providers.dart';
import 'games_registry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = await PrefsSettingsStore.create();

  final AudioService audio = SoLoudAudioService(muted: store.muted);
  // 音频初始化不阻塞首帧：预加载在后台完成，期间的播放请求会被静默丢弃。
  unawaited(audio.init());

  runApp(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        audioServiceProvider.overrideWithValue(audio),
      ],
      child: MiniGamesApp(registry: gameRegistry),
    ),
  );
}
```

Task 1 创建的 `test/smoke_test.dart` 使用了不带参数的 `MiniGamesApp()`，本任务给它加了必填的
`registry` 参数，因此该文件此时已经失效。删除它——`home_page_test.dart` 已经覆盖了同样的启动路径：

```bash
rm test/smoke_test.dart
```

- [ ] **Step 8: 运行测试确认通过**

Run: `flutter test test/features/home/home_page_test.dart`
Expected: 3 个测试 PASS。若 `mutedProvider` 在测试中因 `audioServiceProvider` 默认实现而报错，
确认 `audioServiceProvider` 的默认值是 `SilentAudioService()`（Task 5 Step 9 已如此设定）。

- [ ] **Step 9: 全套门禁并提交**

```bash
dart format . && flutter analyze --fatal-infos && flutter test
git add -A && git commit -F- <<'MSG'
feat: 添加主题、首页、路由与统一游戏外壳

首页与路由表均由游戏注册表生成，新增游戏自动出现在列表中。
游戏外壳统一提供返回、分数、最佳、重开与静音能力。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
MSG
git push
```

---

### Task 7: 2048 规则层

**Files:**
- Create: `lib/games/game2048/domain/tile.dart`
- Create: `lib/games/game2048/domain/board.dart`
- Create: `lib/games/game2048/domain/move.dart`
- Test: `test/games/game2048/move_test.dart`, `test/games/game2048/board_test.dart`

**Interfaces:**
- Consumes: 无（纯 Dart，禁止 import flutter）
- Produces:
  - `class Tile { final int id; final int value; final int row; final int col; Tile copyWith({int? value, int? row, int? col}); }`
  - `enum SwipeDirection { up, down, left, right }`
  - `class Board2048 { const Board2048({required int size, required List<Tile> tiles}); factory Board2048.empty(int size); Tile? tileAt(int row, int col); bool get isFull; int get maxValue; List<int> get emptyIndices; Board2048 withTile(Tile tile); }`
  - `class MoveOutcome { final Board2048 board; final List<Tile> absorbed; final Set<int> mergedIds; final int gainedScore; final int mergeCount; final bool moved; }`
  - `MoveOutcome applyMove(Board2048 board, SwipeDirection direction)`
  - `bool canMoveAnyDirection(Board2048 board)`

- [ ] **Step 1: 写失败的测试**

`test/games/game2048/move_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/games/game2048/domain/board.dart';
import 'package:mini_games/games/game2048/domain/move.dart';
import 'package:mini_games/games/game2048/domain/tile.dart';

/// 从二维数值构造棋盘，0 表示空格。id 按顺序分配。
Board2048 boardOf(List<List<int>> rows) {
  final tiles = <Tile>[];
  var id = 1;
  for (var r = 0; r < rows.length; r++) {
    for (var c = 0; c < rows[r].length; c++) {
      if (rows[r][c] != 0) {
        tiles.add(Tile(id: id++, value: rows[r][c], row: r, col: c));
      }
    }
  }
  return Board2048(size: rows.length, tiles: tiles);
}

/// 把棋盘还原为二维数值，便于断言。
List<List<int>> valuesOf(Board2048 board) {
  final grid = List.generate(
    board.size,
    (_) => List<int>.filled(board.size, 0),
    growable: false,
  );
  for (final tile in board.tiles) {
    grid[tile.row][tile.col] = tile.value;
  }
  return grid;
}

void main() {
  test('相同数字向左合并为两倍', () {
    final outcome = applyMove(
      boardOf([
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.left,
    );

    expect(valuesOf(outcome.board)[0], [4, 0, 0, 0]);
    expect(outcome.gainedScore, 4);
    expect(outcome.mergeCount, 1);
    expect(outcome.moved, isTrue);
  });

  test('单次移动中已合并的方块不再二次合并', () {
    final outcome = applyMove(
      boardOf([
        [2, 2, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.left,
    );

    expect(valuesOf(outcome.board)[0], [4, 4, 0, 0]);
    expect(outcome.mergeCount, 2);
    expect(outcome.gainedScore, 8);
  });

  test('相邻不同值只滑动不合并', () {
    final outcome = applyMove(
      boardOf([
        [4, 4, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.left,
    );

    expect(valuesOf(outcome.board)[0], [8, 4, 0, 0]);
    expect(outcome.gainedScore, 12);
  });

  test('跨越空格也能合并', () {
    final outcome = applyMove(
      boardOf([
        [2, 0, 0, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.left,
    );

    expect(valuesOf(outcome.board)[0], [4, 0, 0, 0]);
  });

  test('向右合并时靠右的一对优先', () {
    final outcome = applyMove(
      boardOf([
        [2, 2, 2, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.right,
    );

    expect(valuesOf(outcome.board)[0], [0, 0, 2, 4]);
  });

  test('向上合并按列处理', () {
    final outcome = applyMove(
      boardOf([
        [2, 0, 0, 0],
        [2, 0, 0, 0],
        [4, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.up,
    );

    expect(valuesOf(outcome.board).map((r) => r[0]).toList(), [4, 4, 0, 0]);
  });

  test('无法移动时 moved 为 false 且棋盘不变', () {
    final board = boardOf([
      [2, 4, 2, 4],
      [4, 2, 4, 2],
      [2, 4, 2, 4],
      [4, 2, 4, 2],
    ]);

    final outcome = applyMove(board, SwipeDirection.left);

    expect(outcome.moved, isFalse);
    expect(valuesOf(outcome.board), valuesOf(board));
    expect(outcome.gainedScore, 0);
  });

  test('合并后的方块沿用参与合并的旧 id，保证动画连续', () {
    final board = boardOf([
      [2, 2, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    final oldIds = board.tiles.map((t) => t.id).toSet();

    final outcome = applyMove(board, SwipeDirection.left);

    expect(oldIds.contains(outcome.board.tiles.single.id), isTrue);
    expect(outcome.mergedIds, {outcome.board.tiles.single.id});
  });

  test('被吞并的方块出现在 absorbed 中且已移动到目标格', () {
    final outcome = applyMove(
      boardOf([
        [2, 0, 0, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      SwipeDirection.left,
    );

    expect(outcome.absorbed, hasLength(1));
    expect(outcome.absorbed.single.col, 0);
    expect(outcome.absorbed.single.value, 2);
  });

  test('没有方块凭空消失：结果加被吞并数等于原方块数', () {
    final board = boardOf([
      [2, 2, 4, 4],
      [8, 8, 2, 2],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);

    final outcome = applyMove(board, SwipeDirection.left);

    expect(
      outcome.board.tiles.length + outcome.absorbed.length,
      board.tiles.length,
    );
  });
}
```

`test/games/game2048/board_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/games/game2048/domain/board.dart';
import 'package:mini_games/games/game2048/domain/move.dart';

import 'move_test.dart' show boardOf;

void main() {
  test('空棋盘没有方块且不满', () {
    final board = Board2048.empty(4);

    expect(board.tiles, isEmpty);
    expect(board.isFull, isFalse);
    expect(board.emptyIndices, hasLength(16));
  });

  test('满盘且相邻无相同值时四方向均不可动', () {
    final board = boardOf([
      [2, 4, 2, 4],
      [4, 2, 4, 2],
      [2, 4, 2, 4],
      [4, 2, 4, 2],
    ]);

    expect(board.isFull, isTrue);
    expect(canMoveAnyDirection(board), isFalse);
  });

  test('满盘但存在相邻相同值时仍可移动', () {
    final board = boardOf([
      [2, 2, 2, 4],
      [4, 2, 4, 2],
      [2, 4, 2, 4],
      [4, 2, 4, 2],
    ]);

    expect(board.isFull, isTrue);
    expect(canMoveAnyDirection(board), isTrue);
  });

  test('maxValue 返回棋盘上的最大数字', () {
    final board = boardOf([
      [2, 4, 8, 16],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);

    expect(board.maxValue, 16);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/games/game2048/`
Expected: 编译失败，找不到 `board.dart`。

- [ ] **Step 3: 实现方块与棋盘**

`lib/games/game2048/domain/tile.dart`：

```dart
import 'package:meta/meta.dart';

/// 棋盘上的一个方块。
///
/// [id] 在方块的整个生命周期内保持稳定，UI 依据它做位移动画；
/// 合并时结果方块沿用参与合并的旧 id，因此动画不会跳变。
@immutable
class Tile {
  const Tile({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
  });

  final int id;
  final int value;
  final int row;
  final int col;

  Tile copyWith({int? value, int? row, int? col}) => Tile(
        id: id,
        value: value ?? this.value,
        row: row ?? this.row,
        col: col ?? this.col,
      );

  @override
  String toString() => 'Tile(id: $id, value: $value, row: $row, col: $col)';
}
```

`lib/games/game2048/domain/board.dart`：

```dart
import 'package:meta/meta.dart';

import 'tile.dart';

@immutable
class Board2048 {
  const Board2048({required this.size, required this.tiles});

  factory Board2048.empty(int size) =>
      Board2048(size: size, tiles: const <Tile>[]);

  final int size;
  final List<Tile> tiles;

  Tile? tileAt(int row, int col) {
    for (final tile in tiles) {
      if (tile.row == row && tile.col == col) return tile;
    }
    return null;
  }

  bool get isFull => tiles.length == size * size;

  int get maxValue =>
      tiles.isEmpty ? 0 : tiles.map((t) => t.value).reduce((a, b) => a > b ? a : b);

  /// 全部空格的扁平下标（row * size + col）。
  List<int> get emptyIndices {
    final occupied = <int>{for (final t in tiles) t.row * size + t.col};
    return [
      for (var i = 0; i < size * size; i++)
        if (!occupied.contains(i)) i,
    ];
  }

  Board2048 withTile(Tile tile) =>
      Board2048(size: size, tiles: [...tiles, tile]);
}
```

- [ ] **Step 4: 实现移动算法**

`lib/games/game2048/domain/move.dart`：

```dart
import 'package:meta/meta.dart';

import 'board.dart';
import 'tile.dart';

enum SwipeDirection { up, down, left, right }

@immutable
class MoveOutcome {
  const MoveOutcome({
    required this.board,
    required this.absorbed,
    required this.mergedIds,
    required this.gainedScore,
    required this.mergeCount,
    required this.moved,
  });

  /// 移动并合并后的棋盘，尚未生成新方块。
  final Board2048 board;

  /// 被吞并的旧方块，位置已更新到目标格。
  /// UI 把它们画在合并结果之下，滑动动画因此不会出现方块凭空消失。
  final List<Tile> absorbed;

  /// [board] 中由合并产生的方块 id，UI 据此播放放大回弹。
  final Set<int> mergedIds;

  final int gainedScore;
  final int mergeCount;
  final bool moved;
}

/// 沿 [direction] 执行一次移动。
///
/// 关键规则：单次移动中，已经参与过合并的方块不得再次参与合并。
/// 实现方式是合并后把游标直接前进两格（`i += 2`）。
MoveOutcome applyMove(Board2048 board, SwipeDirection direction) {
  final size = board.size;
  final result = <Tile>[];
  final absorbed = <Tile>[];
  final mergedIds = <int>{};
  var gainedScore = 0;
  var mergeCount = 0;
  var moved = false;

  final horizontal =
      direction == SwipeDirection.left || direction == SwipeDirection.right;
  final towardStart =
      direction == SwipeDirection.left || direction == SwipeDirection.up;

  for (var line = 0; line < size; line++) {
    // 沿移动方向收集本行/列的方块：最先抵达目标边的排在最前。
    final lineTiles = <Tile>[];
    for (var step = 0; step < size; step++) {
      final index = towardStart ? step : size - 1 - step;
      final tile =
          horizontal ? board.tileAt(line, index) : board.tileAt(index, line);
      if (tile != null) lineTiles.add(tile);
    }

    var cursor = 0;
    var i = 0;
    while (i < lineTiles.length) {
      final current = lineTiles[i];
      final canMerge = i + 1 < lineTiles.length &&
          lineTiles[i + 1].value == current.value;

      final targetIndex = towardStart ? cursor : size - 1 - cursor;
      final targetRow = horizontal ? line : targetIndex;
      final targetCol = horizontal ? targetIndex : line;

      if (canMerge) {
        final partner = lineTiles[i + 1];
        final mergedValue = current.value * 2;
        result.add(
          Tile(id: current.id, value: mergedValue, row: targetRow, col: targetCol),
        );
        absorbed.add(partner.copyWith(row: targetRow, col: targetCol));
        mergedIds.add(current.id);
        gainedScore += mergedValue;
        mergeCount++;
        moved = true;
        i += 2; // 已合并的方块本次不再参与合并
      } else {
        result.add(current.copyWith(row: targetRow, col: targetCol));
        if (current.row != targetRow || current.col != targetCol) moved = true;
        i += 1;
      }
      cursor++;
    }
  }

  if (!moved) {
    return MoveOutcome(
      board: board,
      absorbed: const <Tile>[],
      mergedIds: const <int>{},
      gainedScore: 0,
      mergeCount: 0,
      moved: false,
    );
  }

  return MoveOutcome(
    board: Board2048(size: size, tiles: result),
    absorbed: absorbed,
    mergedIds: mergedIds,
    gainedScore: gainedScore,
    mergeCount: mergeCount,
    moved: true,
  );
}

/// 是否还存在任何可行的移动。四个方向都试一遍。
bool canMoveAnyDirection(Board2048 board) {
  for (final direction in SwipeDirection.values) {
    if (applyMove(board, direction).moved) return true;
  }
  return false;
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `flutter test test/games/game2048/`
Expected: 14 个测试全部 PASS。

- [ ] **Step 6: 确认 domain 层没有 Flutter 依赖**

```bash
grep -r "package:flutter/" lib/games/game2048/domain/ && echo "违反约束：domain 不得依赖 Flutter" || echo "domain 层干净"
```

Expected: 输出「domain 层干净」。

- [ ] **Step 7: 提交**

```bash
dart format . && flutter analyze --fatal-infos && flutter test
git add -A && git commit -F- <<'MSG'
feat: 添加 2048 规则层

带稳定 id 的方块模型使 UI 能做真正的位移动画；合并后游标前进
两格，确保单次移动内已合并的方块不再二次合并。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
MSG
git push
```

---

### Task 8: 2048 界面与音效接入

**Files:**
- Create: `lib/games/game2048/presentation/game2048_state.dart`
- Create: `lib/games/game2048/presentation/game2048_notifier.dart`
- Create: `lib/games/game2048/presentation/game2048_page.dart`
- Create: `lib/games/game2048/presentation/tile_colors.dart`
- Create: `lib/games/game2048/game2048_definition.dart`
- Modify: `lib/games_registry.dart`
- Test: `test/games/game2048/game2048_notifier_test.dart`

**Interfaces:**
- Consumes: Task 7 的 `applyMove` / `canMoveAnyDirection` / `Board2048` / `Tile`；Task 5 的 `audioServiceProvider`；Task 4 的 `highScoreProvider`
- Produces:
  - `enum Game2048Status { playing, won, over }`
  - `class Game2048State { final Board2048 board; final List<Tile> absorbed; final Set<int> mergedIds; final int score; final int nextTileId; final Game2048Status status; }`
  - `class Game2048Notifier extends Notifier<Game2048State> { void swipe(SwipeDirection d); void restart(); }`
  - `final game2048Provider = NotifierProvider<Game2048Notifier, Game2048State>(...)`
  - `const GameDefinition game2048Definition`
  - `const String kGame2048Id = 'game2048';`

- [ ] **Step 1: 写失败的测试**

`test/games/game2048/game2048_notifier_test.dart`：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/core/audio/audio_providers.dart';
import 'package:mini_games/core/audio/audio_service.dart';
import 'package:mini_games/core/audio/sfx.dart';
import 'package:mini_games/core/storage/settings_store.dart';
import 'package:mini_games/core/storage/storage_providers.dart';
import 'package:mini_games/games/game2048/domain/board.dart';
import 'package:mini_games/games/game2048/domain/move.dart';
import 'package:mini_games/games/game2048/domain/tile.dart';
import 'package:mini_games/games/game2048/game2048_definition.dart';
import 'package:mini_games/games/game2048/presentation/game2048_notifier.dart';
import 'package:mini_games/games/game2048/presentation/game2048_state.dart';

ProviderContainer _container(SilentAudioService audio) {
  final container = ProviderContainer(
    overrides: [
      settingsStoreProvider.overrideWithValue(InMemorySettingsStore()),
      audioServiceProvider.overrideWithValue(audio),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('新开局有两个方块', () {
    final container = _container(SilentAudioService());

    final state = container.read(game2048Provider);

    expect(state.board.tiles, hasLength(2));
    expect(state.score, 0);
    expect(state.status, Game2048Status.playing);
  });

  test('无效滑动播放 invalid 音效且不改变分数', () {
    final audio = SilentAudioService();
    final container = _container(audio);
    final notifier = container.read(game2048Provider.notifier);

    // 造一个左滑不动的局面
    notifier.debugSetBoard(
      const Board2048(
        size: 4,
        tiles: [
          Tile(id: 1, value: 2, row: 0, col: 0),
          Tile(id: 2, value: 4, row: 0, col: 1),
        ],
      ),
    );
    audio.played.clear();

    notifier.swipe(SwipeDirection.left);

    expect(audio.played, contains(Sfx.invalid));
    expect(container.read(game2048Provider).score, 0);
  });

  test('有效合并加分、播放 merge 音效并生成新方块', () {
    final audio = SilentAudioService();
    final container = _container(audio);
    final notifier = container.read(game2048Provider.notifier);

    notifier.debugSetBoard(
      const Board2048(
        size: 4,
        tiles: [
          Tile(id: 1, value: 2, row: 0, col: 0),
          Tile(id: 2, value: 2, row: 0, col: 1),
        ],
      ),
    );
    audio.played.clear();

    notifier.swipe(SwipeDirection.left);
    final state = container.read(game2048Provider);

    expect(state.score, 4);
    expect(audio.played, contains(Sfx.merge));
    // 一个合并结果 + 一个新生成的方块
    expect(state.board.tiles, hasLength(2));
  });

  test('刷新最高分', () {
    final container = _container(SilentAudioService());
    final notifier = container.read(game2048Provider.notifier);

    notifier.debugSetBoard(
      const Board2048(
        size: 4,
        tiles: [
          Tile(id: 1, value: 2, row: 0, col: 0),
          Tile(id: 2, value: 2, row: 0, col: 1),
        ],
      ),
    );
    notifier.swipe(SwipeDirection.left);

    expect(container.read(highScoreProvider(kGame2048Id)), 4);
  });

  test('重开清零分数并回到两个方块', () {
    final container = _container(SilentAudioService());
    final notifier = container.read(game2048Provider.notifier);

    notifier.debugSetBoard(
      const Board2048(
        size: 4,
        tiles: [
          Tile(id: 1, value: 2, row: 0, col: 0),
          Tile(id: 2, value: 2, row: 0, col: 1),
        ],
      ),
    );
    notifier.swipe(SwipeDirection.left);
    notifier.restart();

    final state = container.read(game2048Provider);
    expect(state.score, 0);
    expect(state.board.tiles, hasLength(2));
    expect(state.status, Game2048Status.playing);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/games/game2048/game2048_notifier_test.dart`
Expected: 编译失败，找不到 `game2048_state.dart`。

- [ ] **Step 3: 实现状态**

`lib/games/game2048/presentation/game2048_state.dart`：

```dart
import 'package:meta/meta.dart';

import '../domain/board.dart';
import '../domain/tile.dart';

enum Game2048Status { playing, won, over }

@immutable
class Game2048State {
  const Game2048State({
    required this.board,
    required this.absorbed,
    required this.mergedIds,
    required this.score,
    required this.nextTileId,
    required this.status,
  });

  final Board2048 board;

  /// 上一次移动中被吞并的方块，画在合并结果之下，一帧后随下次状态更新消失。
  final List<Tile> absorbed;

  final Set<int> mergedIds;
  final int score;

  /// 下一个可用的方块 id。合并不消耗 id，只有新生成的方块才取用。
  final int nextTileId;

  final Game2048Status status;

  Game2048State copyWith({
    Board2048? board,
    List<Tile>? absorbed,
    Set<int>? mergedIds,
    int? score,
    int? nextTileId,
    Game2048Status? status,
  }) =>
      Game2048State(
        board: board ?? this.board,
        absorbed: absorbed ?? this.absorbed,
        mergedIds: mergedIds ?? this.mergedIds,
        score: score ?? this.score,
        nextTileId: nextTileId ?? this.nextTileId,
        status: status ?? this.status,
      );
}
```

- [ ] **Step 4: 实现 Notifier**

`lib/games/game2048/presentation/game2048_notifier.dart`：

```dart
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_providers.dart';
import '../../../core/audio/sfx.dart';
import '../../../core/haptics/haptics.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/board.dart';
import '../domain/move.dart';
import '../domain/tile.dart';
import '../game2048_definition.dart';
import 'game2048_state.dart';

const int kBoardSize = 4;
const int kWinValue = 2048;

class Game2048Notifier extends Notifier<Game2048State> {
  Game2048Notifier({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  Game2048State build() => _newGame();

  Game2048State _newGame() {
    var board = Board2048.empty(kBoardSize);
    var nextId = 1;
    for (var i = 0; i < 2; i++) {
      final spawned = _spawn(board, nextId);
      board = spawned.$1;
      nextId = spawned.$2;
    }
    return Game2048State(
      board: board,
      absorbed: const <Tile>[],
      mergedIds: const <int>{},
      score: 0,
      nextTileId: nextId,
      status: Game2048Status.playing,
    );
  }

  /// 在随机空格生成一个方块，返回新棋盘与下一个可用 id。
  (Board2048, int) _spawn(Board2048 board, int nextId) {
    final empties = board.emptyIndices;
    if (empties.isEmpty) return (board, nextId);
    final index = empties[_random.nextInt(empties.length)];
    final value = _random.nextDouble() < 0.9 ? 2 : 4;
    return (
      board.withTile(
        Tile(
          id: nextId,
          value: value,
          row: index ~/ board.size,
          col: index % board.size,
        ),
      ),
      nextId + 1,
    );
  }

  void swipe(SwipeDirection direction) {
    if (state.status == Game2048Status.over) return;

    final audio = ref.read(audioServiceProvider);
    final outcome = applyMove(state.board, direction);

    if (!outcome.moved) {
      audio.play(Sfx.invalid, volume: kVolumeNegative);
      return;
    }

    // 本次滑动内第 k 次合并逐级升调。同帧限流会只播放音高最高的那一次，
    // 因此多次合并听感是「一次更高的音」而不是一堆噪音。
    for (var k = 0; k < outcome.mergeCount; k++) {
      audio.play(Sfx.merge, comboIndex: k, volume: kVolumeReward);
    }
    if (outcome.mergeCount > 0) Haptics.light();

    final spawned = _spawn(outcome.board, state.nextTileId);
    final board = spawned.$1;
    final score = state.score + outcome.gainedScore;

    var status = state.status;
    if (status == Game2048Status.playing && board.maxValue >= kWinValue) {
      status = Game2048Status.won;
      audio.play(Sfx.win, volume: kVolumeWin);
      Haptics.medium();
    }
    if (!canMoveAnyDirection(board)) {
      status = Game2048Status.over;
      audio.play(Sfx.gameOver, volume: kVolumeUi);
    }

    ref.read(highScoreProvider(kGame2048Id).notifier).submit(score);

    state = Game2048State(
      board: board,
      absorbed: outcome.absorbed,
      mergedIds: outcome.mergedIds,
      score: score,
      nextTileId: spawned.$2,
      status: status,
    );
  }

  void restart() {
    state = _newGame();
  }

  @visibleForTesting
  void debugSetBoard(Board2048 board) {
    state = state.copyWith(
      board: board,
      absorbed: const <Tile>[],
      mergedIds: const <int>{},
      nextTileId: 1000,
      status: Game2048Status.playing,
    );
  }
}

final game2048Provider =
    NotifierProvider<Game2048Notifier, Game2048State>(Game2048Notifier.new);
```

- [ ] **Step 5: 运行测试确认通过**

Run: `flutter test test/games/game2048/game2048_notifier_test.dart`
Expected: 5 个测试 PASS。

- [ ] **Step 6: 实现配色与界面**

`lib/games/game2048/presentation/tile_colors.dart`：

```dart
import 'package:flutter/material.dart';

/// 经典 2048 配色。超出表格范围的高数值统一使用最深色。
const Map<int, Color> _tileColors = <int, Color>{
  2: Color(0xFFEEE4DA),
  4: Color(0xFFEDE0C8),
  8: Color(0xFFF2B179),
  16: Color(0xFFF59563),
  32: Color(0xFFF67C5F),
  64: Color(0xFFF65E3B),
  128: Color(0xFFEDCF72),
  256: Color(0xFFEDCC61),
  512: Color(0xFFEDC850),
  1024: Color(0xFFEDC53F),
  2048: Color(0xFFEDC22E),
};

Color colorForValue(int value) => _tileColors[value] ?? const Color(0xFF3C3A32);

Color textColorForValue(int value) =>
    value <= 4 ? const Color(0xFF776E65) : Colors.white;

double fontSizeForValue(int value, double cellSize) {
  final digits = value.toString().length;
  final scale = switch (digits) {
    1 || 2 => 0.42,
    3 => 0.34,
    4 => 0.27,
    _ => 0.22,
  };
  return cellSize * scale;
}
```

`lib/games/game2048/presentation/game2048_page.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_scaffold.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/widgets/responsive_board.dart';
import '../domain/move.dart';
import '../domain/tile.dart';
import '../game2048_definition.dart';
import 'game2048_notifier.dart';
import 'game2048_state.dart';
import 'tile_colors.dart';

class Game2048Page extends ConsumerWidget {
  const Game2048Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(game2048Provider);
    final notifier = ref.read(game2048Provider.notifier);
    final best = ref.watch(highScoreProvider(kGame2048Id));

    return GameScaffold(
      definition: game2048Definition,
      score: state.score,
      best: best,
      onRestart: notifier.restart,
      banner: switch (state.status) {
        Game2048Status.won => const _Banner(text: '达成 2048，可以继续挑战'),
        Game2048Status.over => const _Banner(text: '无路可走了，点右上角重开'),
        Game2048Status.playing => null,
      },
      child: ResponsiveBoard(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanEnd: (details) {
            final velocity = details.velocity.pixelsPerSecond;
            if (velocity.distance < 120) return;
            final direction = velocity.dx.abs() > velocity.dy.abs()
                ? (velocity.dx > 0 ? SwipeDirection.right : SwipeDirection.left)
                : (velocity.dy > 0 ? SwipeDirection.down : SwipeDirection.up);
            notifier.swipe(direction);
          },
          child: _Board(state: state),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: scheme.onSecondaryContainer)),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.state});

  final Game2048State state;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = state.board.size;
        final boardSize = constraints.biggest.shortestSide;
        final cell = (boardSize - _gap * (size + 1)) / size;

        double offset(int index) => _gap + index * (cell + _gap);

        return Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            color: const Color(0xFFBBADA0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              for (var r = 0; r < size; r++)
                for (var c = 0; c < size; c++)
                  Positioned(
                    left: offset(c),
                    top: offset(r),
                    width: cell,
                    height: cell,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFCDC1B4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              // 被吞并的方块画在下层，滑动动画因此不会出现方块凭空消失
              for (final tile in state.absorbed)
                _TileView(
                  key: ValueKey<String>('absorbed-${tile.id}'),
                  tile: tile,
                  left: offset(tile.col),
                  top: offset(tile.row),
                  size: cell,
                  popped: false,
                ),
              for (final tile in state.board.tiles)
                _TileView(
                  key: ValueKey<int>(tile.id),
                  tile: tile,
                  left: offset(tile.col),
                  top: offset(tile.row),
                  size: cell,
                  popped: state.mergedIds.contains(tile.id),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TileView extends StatelessWidget {
  const _TileView({
    super.key,
    required this.tile,
    required this.left,
    required this.top,
    required this.size,
    required this.popped,
  });

  final Tile tile;
  final double left;
  final double top;
  final double size;
  final bool popped;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        key: ValueKey<int>(tile.value),
        tween: Tween<double>(begin: popped ? 0.82 : 1, end: 1),
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorForValue(tile.value),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${tile.value}',
              style: TextStyle(
                fontSize: fontSizeForValue(tile.value, size),
                fontWeight: FontWeight.w800,
                color: textColorForValue(tile.value),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: 实现游戏定义并注册**

`lib/games/game2048/game2048_definition.dart`：

```dart
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
```

`lib/games_registry.dart`：

```dart
import 'core/game/game_registry.dart';
import 'games/game2048/game2048_definition.dart';

/// 新增游戏的唯一改动点：在下面的列表中加入该游戏的 GameDefinition。
final GameRegistry gameRegistry = GameRegistry([
  game2048Definition,
]);
```

- [ ] **Step 8: 全套门禁并提交**

```bash
dart format . && flutter analyze --fatal-infos && flutter test
git add -A && git commit -F- <<'MSG'
feat: 添加 2048 界面并接入音效

方块按稳定 id 做位移动画，合并结果播放放大回弹；一次滑动内的
多次合并逐级升调，经同帧限流后听感为一次更高的音。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
MSG
git push
```

---

### Task 9: 数字华容道规则层

**Files:**
- Create: `lib/games/sliding_puzzle/domain/puzzle.dart`
- Create: `lib/games/sliding_puzzle/domain/shuffle.dart`
- Test: `test/games/sliding_puzzle/puzzle_test.dart`, `test/games/sliding_puzzle/shuffle_test.dart`

**Interfaces:**
- Consumes: 无（纯 Dart）
- Produces:
  - `class Puzzle { const Puzzle({required int size, required List<int> tiles}); factory Puzzle.solved(int size); int get blankIndex; bool get isSolved; bool canTap(int index); int slideDistance(int index); Puzzle tap(int index); }`（`tiles` 长度为 `size*size`，`0` 表示空格）
  - `Puzzle shufflePuzzle({required int size, required Random random, int steps = 200})`

- [ ] **Step 1: 写失败的测试**

`test/games/sliding_puzzle/puzzle_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/games/sliding_puzzle/domain/puzzle.dart';

void main() {
  test('已解棋盘按顺序排列且空格在右下', () {
    final puzzle = Puzzle.solved(4);

    expect(puzzle.tiles.take(15).toList(), List.generate(15, (i) => i + 1));
    expect(puzzle.blankIndex, 15);
    expect(puzzle.isSolved, isTrue);
  });

  test('与空格不同行不同列的方块不可点击', () {
    final puzzle = Puzzle.solved(4); // 空格在 (3,3)

    expect(puzzle.canTap(0), isFalse); // (0,0)
    expect(puzzle.canTap(3), isTrue); // (0,3) 同列
    expect(puzzle.canTap(12), isTrue); // (3,0) 同行
  });

  test('空格本身不可点击', () {
    expect(Puzzle.solved(4).canTap(15), isFalse);
  });

  test('点击紧邻空格的方块使其移入空格', () {
    final puzzle = Puzzle.solved(4).tap(14);

    expect(puzzle.tiles[15], 15);
    expect(puzzle.tiles[14], 0);
  });

  test('点击同一行较远的方块使整排一起滑动', () {
    // 空格在 (3,3)，点击 (3,0)，则 13、14、15 整体右移一格
    final puzzle = Puzzle.solved(4).tap(12);

    expect(puzzle.tiles.sublist(12), [0, 13, 14, 15]);
  });

  test('点击同一列较远的方块使整列一起滑动', () {
    // 空格在 (3,3)，点击 (0,3)，则 4、8、12 列上的方块整体下移
    final puzzle = Puzzle.solved(4).tap(3);

    expect(puzzle.tiles[3], 0);
    expect(puzzle.tiles[7], 4);
    expect(puzzle.tiles[11], 8);
    expect(puzzle.tiles[15], 12);
  });

  test('slideDistance 返回本次移动的方块数', () {
    final puzzle = Puzzle.solved(4);

    expect(puzzle.slideDistance(14), 1);
    expect(puzzle.slideDistance(12), 3);
    expect(puzzle.slideDistance(0), 0);
  });

  test('点击不可点击的位置返回原棋盘', () {
    final puzzle = Puzzle.solved(4);

    expect(puzzle.tap(0).tiles, puzzle.tiles);
  });

  test('滑动后不再是已解状态', () {
    expect(Puzzle.solved(4).tap(12).isSolved, isFalse);
  });
}
```

`test/games/sliding_puzzle/shuffle_test.dart`：

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/games/sliding_puzzle/domain/puzzle.dart';
import 'package:mini_games/games/sliding_puzzle/domain/shuffle.dart';

/// 用逆序数奇偶性独立判定可解性，与「随机合法走步」的洗牌实现互为交叉验证。
///
/// 偶数边长的棋盘：逆序数 + 空格自底向上的行号（1 起）为奇数时可解。
/// 奇数边长的棋盘：逆序数为偶数时可解。
bool isSolvable(Puzzle puzzle) {
  final values = puzzle.tiles.where((v) => v != 0).toList();
  var inversions = 0;
  for (var i = 0; i < values.length; i++) {
    for (var j = i + 1; j < values.length; j++) {
      if (values[i] > values[j]) inversions++;
    }
  }
  if (puzzle.size.isOdd) return inversions.isEven;
  final blankRowFromBottom = puzzle.size - puzzle.blankIndex ~/ puzzle.size;
  return (inversions + blankRowFromBottom).isOdd;
}

void main() {
  test('已解棋盘可解', () {
    expect(isSolvable(Puzzle.solved(4)), isTrue);
  });

  test('随机洗牌 1000 次结果全部可解', () {
    final random = Random(20260904);

    for (var i = 0; i < 1000; i++) {
      final puzzle = shufflePuzzle(size: 4, random: random);
      expect(isSolvable(puzzle), isTrue, reason: '第 $i 次洗牌产生了不可解的局面');
    }
  });

  test('洗牌结果不会是已解状态', () {
    final random = Random(7);

    for (var i = 0; i < 200; i++) {
      expect(shufflePuzzle(size: 4, random: random).isSolved, isFalse);
    }
  });

  test('洗牌保留全部数字', () {
    final puzzle = shufflePuzzle(size: 4, random: Random(1));

    expect(puzzle.tiles.toSet(), List.generate(16, (i) => i).toSet());
  });

  test('相同种子产生相同结果', () {
    final a = shufflePuzzle(size: 4, random: Random(42));
    final b = shufflePuzzle(size: 4, random: Random(42));

    expect(a.tiles, b.tiles);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/games/sliding_puzzle/`
Expected: 编译失败，找不到 `puzzle.dart`。

- [ ] **Step 3: 实现棋盘**

`lib/games/sliding_puzzle/domain/puzzle.dart`：

```dart
import 'package:meta/meta.dart';

/// 数字华容道棋盘。
///
/// [tiles] 长度为 size*size，按行主序存放；0 表示空格。
@immutable
class Puzzle {
  const Puzzle({required this.size, required this.tiles});

  factory Puzzle.solved(int size) => Puzzle(
        size: size,
        tiles: [
          for (var i = 1; i < size * size; i++) i,
          0,
        ],
      );

  final int size;
  final List<int> tiles;

  int get blankIndex => tiles.indexOf(0);

  bool get isSolved {
    for (var i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return tiles.last == 0;
  }

  /// 与空格同行或同列的方块可点击（空格自身除外）。
  ///
  /// 允许点击整排而非仅紧邻空格的方块，操作效率显著更高。
  bool canTap(int index) => slideDistance(index) > 0;

  /// 点击该位置会带动多少个方块移动。不可点击时为 0。
  int slideDistance(int index) {
    if (index < 0 || index >= tiles.length) return 0;
    if (tiles[index] == 0) return 0;
    final blank = blankIndex;
    final row = index ~/ size;
    final col = index % size;
    final blankRow = blank ~/ size;
    final blankCol = blank % size;
    if (row == blankRow) return (col - blankCol).abs();
    if (col == blankCol) return (row - blankRow).abs();
    return 0;
  }

  /// 把点击位置到空格之间的整排方块朝空格方向推进一格。
  Puzzle tap(int index) {
    if (!canTap(index)) return this;

    final next = List<int>.of(tiles);
    final blank = blankIndex;
    final row = index ~/ size;
    final col = index % size;
    final blankRow = blank ~/ size;
    final blankCol = blank % size;

    if (row == blankRow) {
      final step = col < blankCol ? 1 : -1;
      for (var x = blankCol; x != col; x -= step) {
        next[row * size + x] = next[row * size + (x - step)];
      }
    } else {
      final step = row < blankRow ? 1 : -1;
      for (var y = blankRow; y != row; y -= step) {
        next[y * size + col] = next[(y - step) * size + col];
      }
    }
    next[index] = 0;

    return Puzzle(size: size, tiles: next);
  }
}
```

- [ ] **Step 4: 实现洗牌**

`lib/games/sliding_puzzle/domain/shuffle.dart`：

```dart
import 'dart:math';

import 'puzzle.dart';

/// 从已解状态出发随机走合法步来洗牌。
///
/// 相比直接打乱数组再判定奇偶性，这种做法天然保证 100% 可解，
/// 实现更短也更容易测试。避免立即走回上一步，防止原地打转导致洗不散。
Puzzle shufflePuzzle({
  required int size,
  required Random random,
  int steps = 200,
}) {
  var puzzle = Puzzle.solved(size);
  var previousBlank = -1;

  for (var i = 0; i < steps; i++) {
    final blank = puzzle.blankIndex;
    final candidates = _neighbours(blank, size)
        .where((candidate) => candidate != previousBlank)
        .toList(growable: false);
    final pick = candidates[random.nextInt(candidates.length)];
    previousBlank = blank;
    puzzle = puzzle.tap(pick);
  }

  // 极小概率洗回已解状态，此时重洗。
  if (puzzle.isSolved) {
    return shufflePuzzle(size: size, random: random, steps: steps);
  }
  return puzzle;
}

List<int> _neighbours(int index, int size) {
  final row = index ~/ size;
  final col = index % size;
  return <int>[
    if (row > 0) (row - 1) * size + col,
    if (row < size - 1) (row + 1) * size + col,
    if (col > 0) row * size + (col - 1),
    if (col < size - 1) row * size + (col + 1),
  ];
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `flutter test test/games/sliding_puzzle/`
Expected: 14 个测试全部 PASS，其中「随机洗牌 1000 次结果全部可解」是核心保证。

- [ ] **Step 6: 确认 domain 层没有 Flutter 依赖**

```bash
grep -r "package:flutter/" lib/games/sliding_puzzle/domain/ && echo "违反约束" || echo "domain 层干净"
```

- [ ] **Step 7: 提交**

```bash
dart format . && flutter analyze --fatal-infos && flutter test
git add -A && git commit -F- <<'MSG'
feat: 添加数字华容道规则层

洗牌采用从已解状态随机走合法步的方式，天然保证可解；测试用
逆序数奇偶性独立验证 1000 次洗牌结果，两套实现互为交叉验证。
点击支持整排滑动而非仅限紧邻空格。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
MSG
git push
```

---

### Task 10: 数字华容道界面与音效接入

**Files:**
- Create: `lib/games/sliding_puzzle/presentation/sliding_puzzle_state.dart`
- Create: `lib/games/sliding_puzzle/presentation/sliding_puzzle_notifier.dart`
- Create: `lib/games/sliding_puzzle/presentation/sliding_puzzle_page.dart`
- Create: `lib/games/sliding_puzzle/sliding_puzzle_definition.dart`
- Modify: `lib/games_registry.dart`
- Test: `test/games/sliding_puzzle/sliding_puzzle_notifier_test.dart`

**Interfaces:**
- Consumes: Task 9 的 `Puzzle` / `shufflePuzzle`；Task 5 的 `audioServiceProvider`；Task 4 的 `highScoreProvider`
- Produces:
  - `class SlidingPuzzleState { final Puzzle puzzle; final int moves; final bool solved; final int bestMoves; }`
  - `class SlidingPuzzleNotifier extends Notifier<SlidingPuzzleState> { void tap(int index); void restart(); }`
  - `final slidingPuzzleProvider = NotifierProvider<SlidingPuzzleNotifier, SlidingPuzzleState>(...)`
  - `const String kSlidingPuzzleId`（定义在 `sliding_puzzle_definition.dart`，与另外两款游戏保持一致）
  - `final GameDefinition slidingPuzzleDefinition`

最高分语义在本游戏是「最少步数」，因此不复用 `highScoreProvider`（它只在更大时更新）。
改为在 `SettingsStore` 中以 `sliding_puzzle` 为 key 存最少步数，由 Notifier 自行比较更小值后写入。

最少步数必须放进 `SlidingPuzzleState`，**不能**用 `Provider<int>((ref) => store.highScore(...))`：
`SettingsStore` 是可变对象且不通知 Riverpod，那种写法在赢下一局后不会刷新界面。

- [ ] **Step 1: 写失败的测试**

`test/games/sliding_puzzle/sliding_puzzle_notifier_test.dart`：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/core/audio/audio_providers.dart';
import 'package:mini_games/core/audio/audio_service.dart';
import 'package:mini_games/core/audio/sfx.dart';
import 'package:mini_games/core/storage/settings_store.dart';
import 'package:mini_games/core/storage/storage_providers.dart';
import 'package:mini_games/games/sliding_puzzle/domain/puzzle.dart';
import 'package:mini_games/games/sliding_puzzle/presentation/sliding_puzzle_notifier.dart';
import 'package:mini_games/games/sliding_puzzle/sliding_puzzle_definition.dart';

ProviderContainer _container(SilentAudioService audio, SettingsStore store) {
  final container = ProviderContainer(
    overrides: [
      settingsStoreProvider.overrideWithValue(store),
      audioServiceProvider.overrideWithValue(audio),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('开局是打乱且未完成的局面，步数为 0', () {
    final container = _container(SilentAudioService(), InMemorySettingsStore());

    final state = container.read(slidingPuzzleProvider);

    expect(state.solved, isFalse);
    expect(state.puzzle.isSolved, isFalse);
    expect(state.moves, 0);
  });

  test('有效点击增加步数并播放 slide 音效', () {
    final audio = SilentAudioService();
    final container = _container(audio, InMemorySettingsStore());
    final notifier = container.read(slidingPuzzleProvider.notifier);
    final movable = List.generate(16, (i) => i)
        .firstWhere(container.read(slidingPuzzleProvider).puzzle.canTap);
    audio.played.clear();

    notifier.tap(movable);

    expect(container.read(slidingPuzzleProvider).moves, 1);
    expect(audio.played, contains(Sfx.slide));
  });

  test('无效点击播放 invalid 音效且步数不变', () {
    final audio = SilentAudioService();
    final container = _container(audio, InMemorySettingsStore());
    final notifier = container.read(slidingPuzzleProvider.notifier);
    final blank = container.read(slidingPuzzleProvider).puzzle.blankIndex;
    audio.played.clear();

    notifier.tap(blank);

    expect(container.read(slidingPuzzleProvider).moves, 0);
    expect(audio.played, contains(Sfx.invalid));
  });

  test('还原成功时标记完成并播放 win 音效', () {
    final audio = SilentAudioService();
    final container = _container(audio, InMemorySettingsStore());
    final notifier = container.read(slidingPuzzleProvider.notifier);

    // 差一步即可完成：空格在 (3,3)，14 号在 (3,2) 之外的位置
    notifier.debugSetPuzzle(
      const Puzzle(
        size: 4,
        tiles: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 0, 15],
      ),
    );
    audio.played.clear();

    notifier.tap(15);

    expect(container.read(slidingPuzzleProvider).solved, isTrue);
    expect(audio.played, contains(Sfx.win));
  });

  test('完成后记录最少步数，更少的成绩才覆盖', () async {
    final store = InMemorySettingsStore();
    await store.setHighScore(kSlidingPuzzleId, 10);
    final container = _container(SilentAudioService(), store);
    final notifier = container.read(slidingPuzzleProvider.notifier);

    notifier.debugSetPuzzle(
      const Puzzle(
        size: 4,
        tiles: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 0, 15],
      ),
    );
    notifier.tap(15);

    expect(store.highScore(kSlidingPuzzleId), 1);
    expect(container.read(slidingPuzzleProvider).bestMoves, 1);
  });

  test('重开后步数归零且局面未完成', () {
    final container = _container(SilentAudioService(), InMemorySettingsStore());
    final notifier = container.read(slidingPuzzleProvider.notifier);

    notifier.restart();

    final state = container.read(slidingPuzzleProvider);
    expect(state.moves, 0);
    expect(state.solved, isFalse);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/games/sliding_puzzle/sliding_puzzle_notifier_test.dart`
Expected: 编译失败，找不到 `sliding_puzzle_notifier.dart`。

- [ ] **Step 3: 实现状态与 Notifier**

`lib/games/sliding_puzzle/presentation/sliding_puzzle_state.dart`：

```dart
import 'package:meta/meta.dart';

import '../domain/puzzle.dart';

@immutable
class SlidingPuzzleState {
  const SlidingPuzzleState({
    required this.puzzle,
    required this.moves,
    required this.solved,
    required this.bestMoves,
  });

  final Puzzle puzzle;
  final int moves;
  final bool solved;

  /// 历史最少步数，0 表示尚无记录。
  /// 放在 state 里而非独立 Provider，否则赢下一局后界面不会刷新。
  final int bestMoves;

  SlidingPuzzleState copyWith({
    Puzzle? puzzle,
    int? moves,
    bool? solved,
    int? bestMoves,
  }) =>
      SlidingPuzzleState(
        puzzle: puzzle ?? this.puzzle,
        moves: moves ?? this.moves,
        solved: solved ?? this.solved,
        bestMoves: bestMoves ?? this.bestMoves,
      );
}
```

`lib/games/sliding_puzzle/presentation/sliding_puzzle_notifier.dart`：

```dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_providers.dart';
import '../../../core/audio/sfx.dart';
import '../../../core/haptics/haptics.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/puzzle.dart';
import '../domain/shuffle.dart';
import '../sliding_puzzle_definition.dart';
import 'sliding_puzzle_state.dart';

const int kPuzzleSize = 4;

class SlidingPuzzleNotifier extends Notifier<SlidingPuzzleState> {
  SlidingPuzzleNotifier({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  SlidingPuzzleState build() => _newGame();

  SlidingPuzzleState _newGame() => SlidingPuzzleState(
        puzzle: shufflePuzzle(size: kPuzzleSize, random: _random),
        moves: 0,
        solved: false,
        bestMoves: ref.read(settingsStoreProvider).highScore(kSlidingPuzzleId),
      );

  void tap(int index) {
    if (state.solved) return;

    final audio = ref.read(audioServiceProvider);
    final distance = state.puzzle.slideDistance(index);

    if (distance == 0) {
      audio.play(Sfx.invalid, volume: kVolumeNegative);
      return;
    }

    // 一次推动的方块越多，音高越高：整排滑动比单格移动更有分量。
    audio.play(Sfx.slide, comboIndex: distance - 1, volume: kVolumeUi);
    Haptics.selection();

    final next = state.puzzle.tap(index);
    final moves = state.moves + 1;
    final solved = next.isSolved;
    var bestMoves = state.bestMoves;

    if (solved) {
      audio.play(Sfx.win, volume: kVolumeWin);
      Haptics.medium();
      bestMoves = _recordBestMoves(moves);
    }

    state = SlidingPuzzleState(
      puzzle: next,
      moves: moves,
      solved: solved,
      bestMoves: bestMoves,
    );
  }

  /// 本游戏的「最佳」是最少步数，因此只在更小时才写入。返回写入后的记录值。
  int _recordBestMoves(int moves) {
    final store = ref.read(settingsStoreProvider);
    final best = store.highScore(kSlidingPuzzleId);
    if (best == 0 || moves < best) {
      unawaited(store.setHighScore(kSlidingPuzzleId, moves));
      return moves;
    }
    return best;
  }

  void restart() {
    state = _newGame();
  }

  @visibleForTesting
  void debugSetPuzzle(Puzzle puzzle) {
    state = SlidingPuzzleState(
      puzzle: puzzle,
      moves: 0,
      solved: false,
      bestMoves: ref.read(settingsStoreProvider).highScore(kSlidingPuzzleId),
    );
  }
}

final slidingPuzzleProvider =
    NotifierProvider<SlidingPuzzleNotifier, SlidingPuzzleState>(
  SlidingPuzzleNotifier.new,
);
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/games/sliding_puzzle/sliding_puzzle_notifier_test.dart`
Expected: 6 个测试 PASS。

- [ ] **Step 5: 实现界面**

`lib/games/sliding_puzzle/presentation/sliding_puzzle_page.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_scaffold.dart';
import '../../../core/widgets/responsive_board.dart';
import '../sliding_puzzle_definition.dart';
import 'sliding_puzzle_notifier.dart';
import 'sliding_puzzle_state.dart';

class SlidingPuzzlePage extends ConsumerWidget {
  const SlidingPuzzlePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(slidingPuzzleProvider);
    final notifier = ref.read(slidingPuzzleProvider.notifier);

    return GameScaffold(
      definition: slidingPuzzleDefinition,
      score: state.moves,
      best: state.bestMoves,
      scoreLabel: '步数',
      bestLabel: '最少步数',
      onRestart: notifier.restart,
      banner: state.solved
          ? const _SolvedBanner()
          : null,
      child: ResponsiveBoard(
        child: _PuzzleBoard(state: state, onTap: notifier.tap),
      ),
    );
  }
}

class _SolvedBanner extends StatelessWidget {
  const _SolvedBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '还原成功，点右上角再来一局',
        style: TextStyle(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

class _PuzzleBoard extends StatelessWidget {
  const _PuzzleBoard({required this.state, required this.onTap});

  final SlidingPuzzleState state;
  final void Function(int index) onTap;

  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = state.puzzle.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.biggest.shortestSide;
        final cell = (boardSize - _gap * (size + 1)) / size;
        double offset(int index) => _gap + index * (cell + _gap);

        return Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              for (var index = 0; index < state.puzzle.tiles.length; index++)
                if (state.puzzle.tiles[index] != 0)
                  AnimatedPositioned(
                    // 用数字本身作为 key，方块在棋盘上移动时身份保持稳定
                    key: ValueKey<int>(state.puzzle.tiles[index]),
                    duration: const Duration(milliseconds: 130),
                    curve: Curves.easeOutCubic,
                    left: offset(index % size),
                    top: offset(index ~/ size),
                    width: cell,
                    height: cell,
                    child: _PuzzleTile(
                      number: state.puzzle.tiles[index],
                      cellSize: cell,
                      onTap: () => onTap(index),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _PuzzleTile extends StatelessWidget {
  const _PuzzleTile({
    required this.number,
    required this.cellSize,
    required this.onTap,
  });

  final int number;
  final double cellSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: cellSize * 0.4,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: 实现游戏定义并注册**

`lib/games/sliding_puzzle/sliding_puzzle_definition.dart`：

```dart
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
```

`lib/games_registry.dart` 加入一行：

```dart
import 'core/game/game_registry.dart';
import 'games/game2048/game2048_definition.dart';
import 'games/sliding_puzzle/sliding_puzzle_definition.dart';

final GameRegistry gameRegistry = GameRegistry([
  game2048Definition,
  slidingPuzzleDefinition,
]);
```

三款游戏统一约定：**id 常量定义在各自的 `<game>_definition.dart` 中**，notifier 与页面从那里 import。
definition 与 page 之间存在互相 import（definition 需要 page 来构建界面，page 需要 definition 传给
GameScaffold），这在 Dart 中合法：顶层 final 是惰性初始化的，运行时不会出现循环。

- [ ] **Step 7: 全套门禁并提交**

```bash
dart format . && flutter analyze --fatal-infos && flutter test
git add -A && git commit -F- <<'MSG'
feat: 添加数字华容道界面并接入音效

整排滑动时按推动的方块数升调，方块以数字为 key 保持身份稳定，
移动动画因此连续。最佳成绩语义为最少步数。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
MSG
git push
```

---

### Task 11: 点点消消乐规则层

**Files:**
- Create: `lib/games/tap_match/domain/match_grid.dart`
- Create: `lib/games/tap_match/domain/clear.dart`
- Test: `test/games/tap_match/match_grid_test.dart`, `test/games/tap_match/clear_test.dart`

**Interfaces:**
- Consumes: 无（纯 Dart）
- Produces:
  - `class MatchCell { const MatchCell({required int id, required int color}); }`
  - `class MatchGrid { const MatchGrid({required int columns, required int rows, required List<MatchCell?> cells}); MatchCell? at(int row, int col); int indexOf(int row, int col); }`（`cells` 按行主序，索引 `row * columns + col`，`row == 0` 为顶部，`null` 表示空）
  - `MatchGrid randomGrid({required int columns, required int rows, required int colorCount, required Random random})`
  - `List<int> findGroup(MatchGrid grid, int row, int col)`
  - `int scoreFor(int count)`
  - `bool hasMoves(MatchGrid grid)`
  - `class ClearOutcome { final MatchGrid grid; final List<int> clearedIndices; final int gainedScore; final bool valid; }`
  - `ClearOutcome clearAt(MatchGrid grid, int row, int col)`

- [ ] **Step 1: 写失败的测试**

`test/games/tap_match/match_grid_test.dart`：

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/games/tap_match/domain/match_grid.dart';

/// 从颜色矩阵构造网格，-1 表示空。id 按顺序分配。
MatchGrid gridOf(List<List<int>> rows) {
  final columns = rows.first.length;
  var id = 1;
  final cells = <MatchCell?>[];
  for (final row in rows) {
    for (final color in row) {
      cells.add(color < 0 ? null : MatchCell(id: id++, color: color));
    }
  }
  return MatchGrid(columns: columns, rows: rows.length, cells: cells);
}

List<List<int>> colorsOf(MatchGrid grid) => [
      for (var r = 0; r < grid.rows; r++)
        [for (var c = 0; c < grid.columns; c++) grid.at(r, c)?.color ?? -1],
    ];

void main() {
  test('孤立色块的连通块只有自己', () {
    final grid = gridOf([
      [0, 1],
      [1, 1],
    ]);

    expect(findGroup(grid, 0, 0), hasLength(1));
  });

  test('4-邻接同色连成一块', () {
    final grid = gridOf([
      [1, 1, 0],
      [1, 0, 0],
      [0, 0, 0],
    ]);

    expect(findGroup(grid, 0, 0), hasLength(3));
  });

  test('对角线不算连通', () {
    final grid = gridOf([
      [1, 0],
      [0, 1],
    ]);

    expect(findGroup(grid, 0, 0), hasLength(1));
  });

  test('空格不参与连通', () {
    final grid = gridOf([
      [1, -1, 1],
      [0, 0, 0],
      [0, 0, 0],
    ]);

    expect(findGroup(grid, 0, 0), hasLength(1));
    expect(findGroup(grid, 0, 1), isEmpty);
  });

  test('计分公式为 n 乘以 n 减一', () {
    expect(scoreFor(2), 2);
    expect(scoreFor(3), 6);
    expect(scoreFor(10), 90);
  });

  test('存在可消连通块时 hasMoves 为真', () {
    expect(
      hasMoves(gridOf([
        [1, 1],
        [0, 2],
      ])),
      isTrue,
    );
  });

  test('无任何同色相邻时 hasMoves 为假', () {
    expect(
      hasMoves(gridOf([
        [0, 1],
        [1, 0],
      ])),
      isFalse,
    );
  });

  test('随机网格填满且颜色在取值范围内', () {
    final grid = randomGrid(
      columns: 10,
      rows: 14,
      colorCount: 5,
      random: Random(3),
    );

    expect(grid.cells.whereType<MatchCell>(), hasLength(140));
    for (final cell in grid.cells.whereType<MatchCell>()) {
      expect(cell.color, inInclusiveRange(0, 4));
    }
  });

  test('随机网格开局一定有可消的块', () {
    for (var seed = 0; seed < 50; seed++) {
      final grid = randomGrid(
        columns: 10,
        rows: 14,
        colorCount: 5,
        random: Random(seed),
      );
      expect(hasMoves(grid), isTrue, reason: 'seed $seed 产生了开局死局');
    }
  });
}
```

`test/games/tap_match/clear_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/games/tap_match/domain/clear.dart';
import 'package:mini_games/games/tap_match/domain/match_grid.dart';

import 'match_grid_test.dart' show colorsOf, gridOf;

void main() {
  test('单个色块不可消除，网格保持不变', () {
    final grid = gridOf([
      [0, 1],
      [1, 1],
    ]);

    final outcome = clearAt(grid, 0, 0);

    expect(outcome.valid, isFalse);
    expect(outcome.gainedScore, 0);
    expect(colorsOf(outcome.grid), colorsOf(grid));
  });

  test('两块及以上可消除并计分', () {
    final grid = gridOf([
      [0, 0],
      [1, 2],
    ]);

    final outcome = clearAt(grid, 0, 0);

    expect(outcome.valid, isTrue);
    expect(outcome.clearedIndices, hasLength(2));
    expect(outcome.gainedScore, 2);
  });

  test('消除后上方色块下落填补', () {
    final grid = gridOf([
      [2, 9],
      [0, 9],
      [0, 9],
    ]);

    final outcome = clearAt(grid, 1, 0);

    // 第 0 列原本自上而下是 2、0、0，消掉两个 0 后 2 落到底部
    expect(colorsOf(outcome.grid).map((r) => r[0]).toList(), [-1, -1, 2]);
  });

  test('整列被清空后右侧列向左压缩', () {
    final grid = gridOf([
      [0, 1, 2],
      [0, 1, 2],
    ]);

    final outcome = clearAt(grid, 0, 0);

    // 第 0 列清空，原第 1、2 列左移
    expect(colorsOf(outcome.grid), [
      [1, 2, -1],
      [1, 2, -1],
    ]);
  });

  test('点击空格不产生任何变化', () {
    final grid = gridOf([
      [-1, 1],
      [1, 1],
    ]);

    final outcome = clearAt(grid, 0, 0);

    expect(outcome.valid, isFalse);
    expect(colorsOf(outcome.grid), colorsOf(grid));
  });

  test('消除不会丢失未参与消除的色块身份', () {
    final grid = gridOf([
      [0, 5],
      [0, 6],
    ]);
    final survivorIds =
        grid.cells.whereType<MatchCell>().where((c) => c.color != 0).map((c) => c.id).toSet();

    final outcome = clearAt(grid, 0, 0);

    final remainingIds =
        outcome.grid.cells.whereType<MatchCell>().map((c) => c.id).toSet();
    expect(remainingIds, survivorIds);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/games/tap_match/`
Expected: 编译失败，找不到 `match_grid.dart`。

- [ ] **Step 3: 实现网格与查找**

`lib/games/tap_match/domain/match_grid.dart`：

```dart
import 'dart:math';

import 'package:meta/meta.dart';

/// 网格中的一个色块。[id] 在整个生命周期内稳定，UI 依据它做下落动画。
@immutable
class MatchCell {
  const MatchCell({required this.id, required this.color});

  final int id;
  final int color;
}

/// 消消乐网格。
///
/// [cells] 按行主序存放，索引为 `row * columns + col`；
/// `row == 0` 是顶部，重力方向为 row 增大的方向；null 表示空位。
@immutable
class MatchGrid {
  const MatchGrid({
    required this.columns,
    required this.rows,
    required this.cells,
  });

  final int columns;
  final int rows;
  final List<MatchCell?> cells;

  int indexOf(int row, int col) => row * columns + col;

  MatchCell? at(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= columns) return null;
    return cells[indexOf(row, col)];
  }
}

/// 生成一个填满的随机网格。若开局即为死局则重新生成。
MatchGrid randomGrid({
  required int columns,
  required int rows,
  required int colorCount,
  required Random random,
}) {
  var nextId = 1;
  while (true) {
    final cells = <MatchCell?>[
      for (var i = 0; i < columns * rows; i++)
        MatchCell(id: nextId++, color: random.nextInt(colorCount)),
    ];
    final grid = MatchGrid(columns: columns, rows: rows, cells: cells);
    if (hasMoves(grid)) return grid;
  }
}

/// 从 (row, col) 出发的 4-邻接同色连通块，返回扁平索引集合。
/// 点击空位时返回空列表。
List<int> findGroup(MatchGrid grid, int row, int col) {
  final origin = grid.at(row, col);
  if (origin == null) return const <int>[];

  final color = origin.color;
  final visited = <int>{};
  final stack = <int>[grid.indexOf(row, col)];

  while (stack.isNotEmpty) {
    final index = stack.removeLast();
    if (!visited.add(index)) continue;
    final r = index ~/ grid.columns;
    final c = index % grid.columns;
    for (final (nr, nc) in <(int, int)>[
      (r - 1, c),
      (r + 1, c),
      (r, c - 1),
      (r, c + 1),
    ]) {
      final neighbour = grid.at(nr, nc);
      if (neighbour != null && neighbour.color == color) {
        final neighbourIndex = grid.indexOf(nr, nc);
        if (!visited.contains(neighbourIndex)) stack.add(neighbourIndex);
      }
    }
  }

  return visited.toList(growable: false);
}

/// 消除 n 块的得分。n 越大收益越陡，鼓励攒大块。
int scoreFor(int count) => count * (count - 1);

/// 是否还存在任何大小不小于 2 的同色连通块。
bool hasMoves(MatchGrid grid) {
  for (var r = 0; r < grid.rows; r++) {
    for (var c = 0; c < grid.columns; c++) {
      final cell = grid.at(r, c);
      if (cell == null) continue;
      final right = grid.at(r, c + 1);
      if (right != null && right.color == cell.color) return true;
      final below = grid.at(r + 1, c);
      if (below != null && below.color == cell.color) return true;
    }
  }
  return false;
}
```

- [ ] **Step 4: 实现消除、重力与列压缩**

`lib/games/tap_match/domain/clear.dart`：

```dart
import 'package:meta/meta.dart';

import 'match_grid.dart';

@immutable
class ClearOutcome {
  const ClearOutcome({
    required this.grid,
    required this.clearedIndices,
    required this.gainedScore,
    required this.valid,
  });

  final MatchGrid grid;

  /// 被消除的色块在消除前的扁平索引，UI 用来播放消失动画。
  final List<int> clearedIndices;

  final int gainedScore;

  /// 连通块大小不足 2 或点击空位时为 false，此时 [grid] 与输入相同。
  final bool valid;
}

/// 消除 (row, col) 所在的同色连通块，随后下落并压缩空列。
ClearOutcome clearAt(MatchGrid grid, int row, int col) {
  final group = findGroup(grid, row, col);
  if (group.length < 2) {
    return ClearOutcome(
      grid: grid,
      clearedIndices: const <int>[],
      gainedScore: 0,
      valid: false,
    );
  }

  final removed = group.toSet();
  final remaining = <MatchCell?>[
    for (var i = 0; i < grid.cells.length; i++)
      removed.contains(i) ? null : grid.cells[i],
  ];

  final collapsed = _collapse(
    MatchGrid(columns: grid.columns, rows: grid.rows, cells: remaining),
  );

  return ClearOutcome(
    grid: collapsed,
    clearedIndices: group,
    gainedScore: scoreFor(group.length),
    valid: true,
  );
}

/// 先让每列内的色块落到底部，再把空列整体向左压缩。
MatchGrid _collapse(MatchGrid grid) {
  final columns = <List<MatchCell>>[];
  for (var c = 0; c < grid.columns; c++) {
    final column = <MatchCell>[];
    for (var r = 0; r < grid.rows; r++) {
      final cell = grid.at(r, c);
      if (cell != null) column.add(cell);
    }
    if (column.isNotEmpty) columns.add(column);
  }

  final cells = List<MatchCell?>.filled(grid.rows * grid.columns, null);
  for (var c = 0; c < columns.length; c++) {
    final column = columns[c];
    // column 是自上而下收集的，底部对齐后相对顺序保持不变
    for (var i = 0; i < column.length; i++) {
      final r = grid.rows - column.length + i;
      cells[r * grid.columns + c] = column[i];
    }
  }

  return MatchGrid(columns: grid.columns, rows: grid.rows, cells: cells);
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `flutter test test/games/tap_match/`
Expected: 15 个测试全部 PASS。

- [ ] **Step 6: 确认 domain 层没有 Flutter 依赖**

```bash
grep -r "package:flutter/" lib/games/tap_match/domain/ && echo "违反约束" || echo "domain 层干净"
```

- [ ] **Step 7: 提交**

```bash
dart format . && flutter analyze --fatal-infos && flutter test
git add -A && git commit -F- <<'MSG'
feat: 添加点点消消乐规则层

4-邻接 flood fill 求同色连通块，不小于 2 才可消除；消除后先在
列内下落再压缩空列。色块带稳定 id 以支撑下落动画。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
MSG
git push
```

---

### Task 12: 点点消消乐界面与音效接入

**Files:**
- Create: `lib/games/tap_match/presentation/tap_match_state.dart`
- Create: `lib/games/tap_match/presentation/tap_match_notifier.dart`
- Create: `lib/games/tap_match/presentation/tap_match_page.dart`
- Create: `lib/games/tap_match/tap_match_definition.dart`
- Modify: `lib/games_registry.dart`
- Test: `test/games/tap_match/tap_match_notifier_test.dart`

**Interfaces:**
- Consumes: Task 11 的 `MatchGrid` / `clearAt` / `hasMoves` / `randomGrid`；Task 5 的 `audioServiceProvider`；Task 4 的 `highScoreProvider`
- Produces:
  - `class TapMatchState { final MatchGrid grid; final int score; final bool over; }`
  - `class TapMatchNotifier extends Notifier<TapMatchState> { void tapCell(int row, int col); void restart(); }`
  - `final tapMatchProvider = NotifierProvider<TapMatchNotifier, TapMatchState>(...)`
  - `const String kTapMatchId = 'tap_match';`
  - `final GameDefinition tapMatchDefinition`

- [ ] **Step 1: 写失败的测试**

`test/games/tap_match/tap_match_notifier_test.dart`：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/core/audio/audio_providers.dart';
import 'package:mini_games/core/audio/audio_service.dart';
import 'package:mini_games/core/audio/sfx.dart';
import 'package:mini_games/core/storage/settings_store.dart';
import 'package:mini_games/core/storage/storage_providers.dart';
import 'package:mini_games/games/tap_match/presentation/tap_match_notifier.dart';
import 'package:mini_games/games/tap_match/tap_match_definition.dart';

import 'match_grid_test.dart' show gridOf;

ProviderContainer _container(SilentAudioService audio) {
  final container = ProviderContainer(
    overrides: [
      settingsStoreProvider.overrideWithValue(InMemorySettingsStore()),
      audioServiceProvider.overrideWithValue(audio),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('开局有分数为 0 的可玩局面', () {
    final container = _container(SilentAudioService());

    final state = container.read(tapMatchProvider);

    expect(state.score, 0);
    expect(state.over, isFalse);
  });

  test('消除成功时加分并播放 pop 音效', () {
    final audio = SilentAudioService();
    final container = _container(audio);
    final notifier = container.read(tapMatchProvider.notifier);

    notifier.debugSetGrid(gridOf([
      [0, 0, 1],
      [2, 3, 4],
      [5, 6, 7],
    ]));
    audio.played.clear();

    notifier.tapCell(0, 0);

    expect(container.read(tapMatchProvider).score, 2);
    expect(audio.played, contains(Sfx.pop));
  });

  test('点击单块播放 invalid 音效且不加分', () {
    final audio = SilentAudioService();
    final container = _container(audio);
    final notifier = container.read(tapMatchProvider.notifier);

    notifier.debugSetGrid(gridOf([
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
    ]));
    audio.played.clear();

    notifier.tapCell(0, 0);

    expect(container.read(tapMatchProvider).score, 0);
    expect(audio.played, contains(Sfx.invalid));
  });

  test('消到死局时标记结束并播放 gameOver 音效', () {
    final audio = SilentAudioService();
    final container = _container(audio);
    final notifier = container.read(tapMatchProvider.notifier);

    // 消掉这一对之后棋盘为空，不存在任何可消块
    notifier.debugSetGrid(gridOf([
      [0],
      [0],
    ]));
    audio.played.clear();

    notifier.tapCell(0, 0);

    expect(container.read(tapMatchProvider).over, isTrue);
    expect(audio.played, contains(Sfx.gameOver));
  });

  test('结束后再点击不产生变化', () {
    final container = _container(SilentAudioService());
    final notifier = container.read(tapMatchProvider.notifier);

    notifier.debugSetGrid(gridOf([
      [0],
      [0],
    ]));
    notifier.tapCell(0, 0);
    final scoreAfterEnd = container.read(tapMatchProvider).score;

    notifier.tapCell(0, 0);

    expect(container.read(tapMatchProvider).score, scoreAfterEnd);
  });

  test('刷新最高分', () {
    final container = _container(SilentAudioService());
    final notifier = container.read(tapMatchProvider.notifier);

    notifier.debugSetGrid(gridOf([
      [0, 0, 1],
      [2, 3, 4],
      [5, 6, 7],
    ]));
    notifier.tapCell(0, 0);

    expect(container.read(highScoreProvider(kTapMatchId)), 2);
  });

  test('重开清零分数', () {
    final container = _container(SilentAudioService());
    final notifier = container.read(tapMatchProvider.notifier);

    notifier.debugSetGrid(gridOf([
      [0, 0, 1],
      [2, 3, 4],
      [5, 6, 7],
    ]));
    notifier.tapCell(0, 0);
    notifier.restart();

    expect(container.read(tapMatchProvider).score, 0);
    expect(container.read(tapMatchProvider).over, isFalse);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/games/tap_match/tap_match_notifier_test.dart`
Expected: 编译失败，找不到 `tap_match_notifier.dart`。

- [ ] **Step 3: 实现状态与 Notifier**

`lib/games/tap_match/presentation/tap_match_state.dart`：

```dart
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
```

`lib/games/tap_match/presentation/tap_match_notifier.dart`：

```dart
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_providers.dart';
import '../../../core/audio/sfx.dart';
import '../../../core/haptics/haptics.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/clear.dart';
import '../domain/match_grid.dart';
import '../tap_match_definition.dart';
import 'tap_match_state.dart';

const int kMatchColumns = 10;
const int kMatchRows = 14;
const int kMatchColors = 5;

class TapMatchNotifier extends Notifier<TapMatchState> {
  TapMatchNotifier({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  TapMatchState build() => _newGame();

  TapMatchState _newGame() => TapMatchState(
        grid: randomGrid(
          columns: kMatchColumns,
          rows: kMatchRows,
          colorCount: kMatchColors,
          random: _random,
        ),
        score: 0,
        over: false,
      );

  void tapCell(int row, int col) {
    if (state.over) return;

    final audio = ref.read(audioServiceProvider);
    final outcome = clearAt(state.grid, row, col);

    if (!outcome.valid) {
      audio.play(Sfx.invalid, volume: kVolumeNegative);
      return;
    }

    // 起始音高由本次消除的块数决定：消 2 块是基准音，消一大片直接起高音。
    // 这是三款游戏里最能体现「越猛越爽」的一处。
    final comboIndex = outcome.clearedIndices.length - 2;
    audio.play(Sfx.pop, comboIndex: comboIndex, volume: kVolumeReward);
    Haptics.light();

    final score = state.score + outcome.gainedScore;
    final over = !hasMoves(outcome.grid);

    if (over) {
      audio.play(Sfx.gameOver, volume: kVolumeUi);
    }

    ref.read(highScoreProvider(kTapMatchId).notifier).submit(score);

    state = TapMatchState(grid: outcome.grid, score: score, over: over);
  }

  void restart() {
    state = _newGame();
  }

  @visibleForTesting
  void debugSetGrid(MatchGrid grid) {
    state = TapMatchState(grid: grid, score: 0, over: false);
  }
}

final tapMatchProvider =
    NotifierProvider<TapMatchNotifier, TapMatchState>(TapMatchNotifier.new);
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/games/tap_match/tap_match_notifier_test.dart`
Expected: 7 个测试 PASS。

- [ ] **Step 5: 实现界面**

`lib/games/tap_match/presentation/tap_match_page.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_scaffold.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/widgets/responsive_board.dart';
import '../domain/match_grid.dart';
import '../tap_match_definition.dart';
import 'tap_match_notifier.dart';
import 'tap_match_state.dart';

/// 五种色块的配色，饱和度接近以免某一色显得突兀。
const List<Color> kMatchPalette = <Color>[
  Color(0xFFE8505B),
  Color(0xFF4C8BF5),
  Color(0xFF3FBF7F),
  Color(0xFFF5A623),
  Color(0xFF9B6DE8),
];

class TapMatchPage extends ConsumerWidget {
  const TapMatchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tapMatchProvider);
    final notifier = ref.read(tapMatchProvider.notifier);
    final best = ref.watch(highScoreProvider(kTapMatchId));

    return GameScaffold(
      definition: tapMatchDefinition,
      score: state.score,
      best: best,
      onRestart: notifier.restart,
      banner: state.over ? const _OverBanner() : null,
      child: ResponsiveBoard(
        aspectRatio: kMatchColumns / kMatchRows,
        maxSize: 520,
        child: _MatchBoard(state: state, onTap: notifier.tapCell),
      ),
    );
  }
}

class _OverBanner extends StatelessWidget {
  const _OverBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '没有可消的色块了，点右上角再来一局',
        style: TextStyle(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

class _MatchBoard extends StatelessWidget {
  const _MatchBoard({required this.state, required this.onTap});

  final TapMatchState state;
  final void Function(int row, int col) onTap;

  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    final grid = state.grid;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - _gap * (grid.columns + 1)) / grid.columns;
        final cellHeight = (constraints.maxHeight - _gap * (grid.rows + 1)) / grid.rows;
        final cell = cellWidth < cellHeight ? cellWidth : cellHeight;

        double left(int col) => _gap + col * (cell + _gap);
        double top(int row) => _gap + row * (cell + _gap);

        return Stack(
          children: [
            for (var r = 0; r < grid.rows; r++)
              for (var c = 0; c < grid.columns; c++)
                if (grid.at(r, c) case final MatchCell item)
                  AnimatedPositioned(
                    // 以色块 id 为 key，下落与左移因此是连续动画而非闪现
                    key: ValueKey<int>(item.id),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    left: left(c),
                    top: top(r),
                    width: cell,
                    height: cell,
                    child: _MatchTile(
                      color: kMatchPalette[item.color % kMatchPalette.length],
                      onTap: () => onTap(r, c),
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
```

`_MatchBoard` 中的 `onTap(r, c)` 捕获的是构建时的坐标，而每次状态更新都会重建整棵子树，
因此坐标始终与当前网格一致。

- [ ] **Step 6: 实现游戏定义并注册**

`lib/games/tap_match/tap_match_definition.dart`：

```dart
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
```

`lib/games_registry.dart` 最终形态：

```dart
import 'core/game/game_registry.dart';
import 'games/game2048/game2048_definition.dart';
import 'games/sliding_puzzle/sliding_puzzle_definition.dart';
import 'games/tap_match/tap_match_definition.dart';

/// 新增游戏的唯一改动点：在下面的列表中加入该游戏的 GameDefinition。
final GameRegistry gameRegistry = GameRegistry([
  game2048Definition,
  slidingPuzzleDefinition,
  tapMatchDefinition,
]);
```

- [ ] **Step 7: 补一个覆盖全注册表的首页测试**

在 `test/features/home/home_page_test.dart` 末尾追加：

```dart
  testWidgets('真实注册表中的三款游戏都出现在首页', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(InMemorySettingsStore()),
        ],
        child: MiniGamesApp(registry: gameRegistry),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2048'), findsOneWidget);
    expect(find.text('数字华容道'), findsOneWidget);
    expect(find.text('点点消消乐'), findsOneWidget);
  });
```

需要在该测试文件顶部补 `import 'package:mini_games/games_registry.dart';`。

- [ ] **Step 8: 全套门禁并提交**

```bash
dart format . && flutter analyze --fatal-infos && flutter test
git add -A && git commit -F- <<'MSG'
feat: 添加点点消消乐界面并接入音效

消除音高由本次消除的块数决定，消一大片直接起高音。色块以 id
为 key，下落与列压缩均为连续动画。三款游戏至此全部接入注册表。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
MSG
git push
```

---

### Task 13: Android 平台配置

**Files:**
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `android/app/proguard-rules.pro`

**Interfaces:**
- Consumes: Task 1 生成的 Android 工程
- Produces: 满足 2026 年 Google Play 要求的构建配置；`release` 签名配置在 `android/key.properties` 存在时启用，缺失时回退到 debug 签名以便本地或未配置密钥的 CI 也能构建

- [ ] **Step 1: 检查生成的构建脚本形态**

```bash
ls android/app/build.gradle*
```

Flutter 3.47 默认生成 Kotlin DSL（`build.gradle.kts`）。若实际为 Groovy（`build.gradle`），
把下面的配置按 Groovy 语法等价改写，语义不变。

- [ ] **Step 2: 配置 SDK 版本与签名**

`android/app/build.gradle.kts` 中，在 `plugins { ... }` 之后、`android { ... }` 之前插入：

```kotlin
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
```

`android { ... }` 内设置：

```kotlin
android {
    namespace = "dev.lofiski.minigames"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "dev.lofiski.minigames"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeType = "PKCS12"
            }
        }
    }

    buildTypes {
        release {
            // 缺少密钥时回退到 debug 签名，保证任何环境都能完成构建
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}
```

- [ ] **Step 3: 添加 ProGuard 规则**

`android/app/proguard-rules.pro`：

```
# flutter_soloud 通过 FFI 调用原生库，保留其入口避免被裁剪
-keep class com.soloud.** { *; }
-keep class **.SoLoud** { *; }

# Flutter 嵌入层
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
```

- [ ] **Step 4: 收紧 Manifest**

`android/app/src/main/AndroidManifest.xml`：

- 确认 `<manifest>` 下**没有任何 `<uses-permission>` 元素**。若 `flutter create` 生成了 `INTERNET` 权限（通常在 debug/profile 的 manifest 中），保留 debug 版本但确保 `main` 与 `release` 中没有。
- `android:label` 设为 `Mini Games`。
- **不要**添加 `android:screenOrientation`：API 36 下 600dp 以上大屏不允许锁定方向。
- **不要**添加 `windowOptOutEdgeToEdgeEnforcement`：API 36 已移除该开关。

验证：

```bash
grep -rn "uses-permission" android/app/src/main/AndroidManifest.xml && echo "存在权限声明，需要移除" || echo "无权限声明"
grep -rn "screenOrientation" android/app/src/ && echo "存在方向锁定，需要移除" || echo "无方向锁定"
```

Expected: 分别输出「无权限声明」「无方向锁定」。

- [ ] **Step 5: 提交**

本地没有 Android SDK，无法验证构建；正确性由 Task 14 的 CI 构建确认。

```bash
git add -A && git commit -F- <<'MSG'
build: 按 2026 年要求配置 Android 构建

compileSdk 与 targetSdk 提升到 36，minSdk 24，开启 R8 压缩混淆。
不声明任何权限、不锁定屏幕方向、不 opt-out edge-to-edge。
签名配置在 key.properties 缺失时回退到 debug 签名。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
MSG
git push
```

---

### Task 14: 签名密钥、发布流水线与首个版本

**Files:**
- Create: `.github/workflows/release.yml`
- Create: 本地 `mini-games-release.p12`（**不入库**，备份到仓库目录之外）

**Interfaces:**
- Consumes: Task 13 的签名配置
- Produces: 仓库 Secrets `KEYSTORE_BASE64` / `KEYSTORE_PASSWORD` / `KEY_ALIAS`；GitHub Release 附带签名 APK

- [ ] **Step 1: 生成 PKCS12 签名密钥**

本地无 JDK，因此用 openssl 生成 PKCS12。Android 原生支持 PKCS12 keystore。

```bash
KEYSTORE_DIR="$HOME/keys"
mkdir -p "$KEYSTORE_DIR"
KEYSTORE_PASSWORD="$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)"

openssl req -x509 -newkey rsa:4096 -sha256 -days 10950 -nodes \
  -keyout /tmp/mg-key.pem -out /tmp/mg-cert.pem \
  -subj "/CN=Mini Games/O=lofiski/C=CN"

openssl pkcs12 -export \
  -inkey /tmp/mg-key.pem -in /tmp/mg-cert.pem \
  -name upload \
  -out "$KEYSTORE_DIR/mini-games-release.p12" \
  -passout "pass:$KEYSTORE_PASSWORD"

rm -f /tmp/mg-key.pem /tmp/mg-cert.pem
echo "密钥口令（请自行妥善保存）：$KEYSTORE_PASSWORD"
```

有效期 10950 天（约 30 年），满足 Google Play 对上传密钥有效期的要求。
`-name upload` 指定的 friendlyName 即 Gradle 中的 `keyAlias`。

- [ ] **Step 2: 写入仓库 Secrets**

```bash
base64 -w0 "$HOME/keys/mini-games-release.p12" | gh secret set KEYSTORE_BASE64
printf '%s' "$KEYSTORE_PASSWORD" | gh secret set KEYSTORE_PASSWORD
printf 'upload' | gh secret set KEY_ALIAS
gh secret list
```

Expected: 列出三个 secret。确认密钥文件位于 `$HOME/keys`（仓库目录之外），且 `.gitignore` 已排除 `*.p12`。

- [ ] **Step 3: 编写发布 workflow**

`.github/workflows/release.yml`：

```yaml
name: Release

on:
  push:
    tags: ['v*']
  workflow_dispatch:

concurrency:
  group: release-${{ github.ref }}
  cancel-in-progress: false

jobs:
  build:
    name: 构建并发布签名 APK
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.47.2
          channel: stable
          cache: true

      - name: 缓存 Gradle
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: gradle-${{ runner.os }}-${{ hashFiles('android/**/*.gradle*', 'android/**/gradle-wrapper.properties') }}
          restore-keys: gradle-${{ runner.os }}-

      - name: 拉取依赖
        run: flutter pub get

      - name: 静态分析
        run: flutter analyze --fatal-infos

      - name: 运行测试
        run: flutter test

      - name: 还原签名密钥
        env:
          KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
        run: |
          if [ -z "$KEYSTORE_BASE64" ]; then
            echo "未配置签名密钥，将使用 debug 签名构建" >&2
            exit 0
          fi
          echo "$KEYSTORE_BASE64" | base64 -d > "$RUNNER_TEMP/release.p12"
          cat > android/key.properties <<EOF
          storeFile=$RUNNER_TEMP/release.p12
          storePassword=$KEYSTORE_PASSWORD
          keyAlias=$KEY_ALIAS
          keyPassword=$KEYSTORE_PASSWORD
          EOF

      - name: 构建按 ABI 拆分的 APK
        run: flutter build apk --release --split-per-abi

      - name: 构建通用 APK
        run: flutter build apk --release

      - name: 清理密钥
        if: always()
        run: rm -f android/key.properties "$RUNNER_TEMP/release.p12"

      - name: 上传构建产物
        uses: actions/upload-artifact@v4
        with:
          name: apk
          path: build/app/outputs/flutter-apk/*.apk
          if-no-files-found: error

      - name: 发布 Release
        if: startsWith(github.ref, 'refs/tags/v')
        uses: softprops/action-gh-release@v2
        with:
          files: build/app/outputs/flutter-apk/*.apk
          generate_release_notes: true
```

PKCS12 的 store 口令与 key 口令相同，因此 `keyPassword` 复用 `storePassword`。
「清理密钥」步骤设为 `if: always()`，即使构建失败也不会把密钥留在工作区。

- [ ] **Step 4: 用手动触发验证流水线**

先不打 tag，用 `workflow_dispatch` 跑一次，确认能构建出签名 APK：

```bash
git add -A && git commit -F- <<'MSG'
ci: 添加签名打包与发布流水线

从 Secrets 还原 PKCS12 密钥后构建 release APK，按 ABI 拆分并
额外产出通用包；打 v 开头的 tag 时自动发布 GitHub Release。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
MSG
git push

gh workflow run release.yml
gh run watch --exit-status
```

若失败，用 `gh run view --log-failed` 读取日志并修复。常见问题：

- AGP 要求的 JDK 版本与 `setup-java` 不一致 → 调整 `java-version`
- `flutter_soloud` 的原生构建需要更高的 `minSdk` → 按报错提升 `minSdk` 并同步更新本计划的约束
- R8 裁剪掉了 FFI 入口导致运行时崩溃 → 补充 `proguard-rules.pro`

- [ ] **Step 5: 下载产物做一次真机验证**

```bash
gh run download --name apk --dir /tmp/apk
ls -lh /tmp/apk
```

把 `app-arm64-v8a-release.apk` 安装到手机，逐项确认：

1. 首页显示三个游戏方块，点击均能进入
2. 2048 滑动有位移动画，合并有音效且连续合并音高递增
3. 华容道点击整排能一起滑动，还原成功有通关音效
4. 消消乐点击相邻同色能整片消除，消得越多音效越高
5. 右上角静音开关生效，且重启应用后保持
6. 横竖屏切换棋盘均正常显示、不溢出
7. 最高分在重启应用后仍然保留

- [ ] **Step 6: 发布首个版本**

```bash
git tag v0.1.0
git push origin v0.1.0
gh run watch --exit-status
gh release view v0.1.0
```

Expected: Release 页面包含 4 个 APK（3 个 ABI 拆分包 + 1 个通用包）。

- [ ] **Step 7: 更新 README 的下载说明并提交**

确认 README 中的 Releases 链接可用，补上首个版本的说明。

```bash
git add -A && git commit -F- <<'MSG'
docs: 补充首个版本的下载说明

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TVwsjdrfhz6Rscqv3noGmw
MSG
git push
```

---

## 附录：新增第四款游戏的步骤

本计划完成后，加一款新游戏的完整流程如下（无需改动任何既有游戏）：

1. 新建 `lib/games/<game_name>/domain/`，用纯 Dart 写规则，同时在 `test/games/<game_name>/` 写单元测试
2. 新建 `lib/games/<game_name>/presentation/`，写 `Notifier` 与页面，页面外层套 `GameScaffold`
3. 新建 `lib/games/<game_name>/<game_name>_definition.dart`，导出 `GameDefinition`
4. 在 `lib/games_registry.dart` 的列表中加入该 definition
5. 若需要新音效，在 `Sfx` 枚举中扩展并补 `assetPathFor` 的分支，把 CC0 音频放进 `assets/audio/`

首页方块、路由、返回、分数、最佳、重开、静音、最高分持久化全部自动接入。
