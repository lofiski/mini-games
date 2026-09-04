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
