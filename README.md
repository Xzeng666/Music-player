# Resonance Music

一款使用 Flutter 重构的跨平台音乐播放器：支持 Windows、Ubuntu、iOS、Android，以本地优先的数据模型记录听歌行为，通过多标签和阈值控制生成可解释推荐。

> 当前仓库由旧 Qt Widgets 单窗口播放器整体重构而来。旧版评审见 [`docs/CURRENT_STATE_REVIEW.md`](docs/CURRENT_STATE_REVIEW.md)，标准化需求与验收项见 [`docs/PRODUCT_SPEC.md`](docs/PRODUCT_SPEC.md)。

## 已实现

- 自适应导航：手机底部导航，桌面侧边导航，兼容 375–1440+ 宽度；
- 本地音频导入、在线播放、播放/暂停、进度、上一首/下一首、随机、循环和音量；
- 歌曲海公开搜索页的表格解析：完整保留序号、歌名、歌手和原详情页；
- iTunes Search 的公开 30 秒试听；
- Internet Archive 开放授权音乐搜索、在线播放和合规下载；
- 对授权音频的 0–50 首 LRU 临时缓存，同曲再播不重复下载；
- 收藏、本地音乐、授权下载和播放行为的设备端持久化；
- 流派、情绪、能量、年代、语言、场景、来源多标签；
- 完播、早退、收藏等行为加权，并按 45 天半衰期衰减；
- “至少 8 个有效行为 + 6.0 置信度”的个性化启用阈值；
- 标签匹配、新鲜度、重复惩罚、艺术家多样性和可读推荐原因；
- 深色/浅色主题、44×44 最小触控目标、键盘焦点、读屏语义和 reduced motion；
- 单元测试、静态检查及四平台 CI 构建配置；
- 随机播放与循环模式统一为播放模式组，窄屏自适应独立成行。

## 在线来源与版权边界

| 来源 | 搜索 | 在线播放 | 永久下载 | 说明 |
| --- | --- | --- | --- | --- |
| 歌曲海 | 是，解析公开结果表 | 应用内匹配授权来源 | 否 | 点击播放不跳转；不调用私有 `/api/music`、不抓取媒体或完整歌词 |
| iTunes Search | 是 | 是 | 否 | 仅播放 Apple 返回的试听 URL |
| Internet Archive | 是 | 是 | 仅开放许可证 | 只有 CC BY、公共领域或 CC0 条目显示下载入口 |
| 本地文件 | — | 是 | — | 用户自行选择且应确保有权使用 |

歌曲海搜索使用 `https://www.gequhai.com/s/<用户关键词>`，并仅解析 `#myTables` 中的公开元数据。点击播放会按“歌名 + 歌手”在 iTunes Preview 和 Internet Archive 中进行严格匹配，全程留在应用内；只有独立的“查看原页”按钮会由用户主动打开网页。项目不会固化其私有媒体解析端点、抓取完整歌词或将许可不明的内容加入缓存/下载。

## 架构

```text
presentation (adaptive Flutter UI)
        ↓
application (AppController / use cases)
        ↓
domain (Song / tags / preference / recommendation)
        ↑
data & infrastructure (sources / persistence / audioplayers / LRU cache / downloads)
```

主要目录：

```text
lib/
├── app/                          # 主题、响应式壳、页面和控制器
├── features/catalog/             # Song、标签器、在线来源端口与适配器
├── features/library/             # 收藏/历史持久化、授权下载
├── features/playback/            # PlayerService 与 audioplayers 联邦实现
└── features/recommendations/     # 行为、偏好向量、阈值与推荐排序
```

详细边界和推荐公式见 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)。视觉 token 与交互规范见 [`design-system/resonance-music/MASTER.md`](design-system/resonance-music/MASTER.md)。

## 环境

- Flutter 3.47.0 stable
- Dart 3.13.0
- Windows：Visual Studio 2022 + Desktop development with C++
- Ubuntu：`clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev`
- Android：Android Studio / SDK 35、JDK 17+
- iOS：macOS、最新稳定 Xcode、CocoaPods；真机发布还需 Apple Developer 签名

验证环境：

```bash
flutter doctor -v
flutter pub get
```

Windows 首次解析原生插件时需要创建符号链接。如果 Flutter 提示 `Building with plugins requires symlink support`，请运行 `start ms-settings:developers`，开启系统“开发者模式”后重新执行 `flutter pub get`。这是 Flutter Windows 插件构建的系统前置条件。

## 运行

```bash
# Windows
flutter run -d windows

# Ubuntu
flutter run -d linux

# Android
flutter run -d android

# iOS（必须在 macOS）
flutter run -d ios
```

首次启动会搜索“流行”以生成冷启动候选。网络失败不会影响本地音乐库；可在搜索页重试或直接导入本地音频。

## 质量检查与构建

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

flutter build windows --release
flutter build linux --release
flutter build apk --release
flutter build ios --release --no-codesign
```

Windows 只能构建 Windows/Android；Ubuntu 构建需要 Linux；iOS 必须在 macOS/Xcode 上完成。仓库的 GitHub Actions 将这些任务分配到相应宿主机。

### 本次验收证据

2026-08-14 在 Windows 10 22H2、Flutter 3.47.0、Dart 3.13.0、Visual Studio Community 2026 环境完成：

- `flutter analyze --no-pub`：0 问题；
- `flutter test --no-pub`：17 项测试全部通过；
- 覆盖 375×812、812×375、768×1024、1440×900、深浅主题、2×系统字体和 reduced motion；
- `flutter build windows --release --no-pub`：成功；
- 产物：`build/windows/x64/runner/Release/resonance_music.exe`；
- release 可执行文件冷启动冒烟测试通过，进程保持运行且窗口线程可响应。
- 歌曲海“稻香”联网冒烟验证解析出 10 条结果，首条为“稻香 · 周杰伦 · `/play/333`”；点击播放的真实匹配链路在应用内命中“iTunes Preview · 稻香 · 周杰伦”。

## 推荐如何工作

1. 来源元数据和轻量规则为歌曲生成多个带置信度的标签。
2. 曝光、打开、播放、完播、早退、收藏、取消收藏、入库、不喜欢映射为不同权重。
3. 权重按 45 天半衰期衰减并投影到标签向量。
4. 未达到阈值时使用新鲜度、开放来源和多样性排序。
5. 达到阈值后使用标签匹配，并对最近播放和同艺术家过度集中进行惩罚。
6. 每个结果展示贡献最大的标签，例如“因为你偏爱流行 · 高能量”。

用户可以在“设置”页查看学习进度与标签分值、设置缓存上限，并重置行为数据。重置不会删除收藏、本地文件或授权下载。

## 隐私

- 行为、偏好、收藏和路径默认仅保存在设备本地；
- 项目不要求账号，也不会上传听歌历史；
- 不提交或分发用户媒体；
- 设备存储目前使用 `shared_preferences` 的版本化 JSON，后续跨设备同步应独立实现并明确征得用户同意。

## 已知限制

- iTunes 结果是约 30 秒试听，不是完整曲目；
- 歌曲海条目的音频/完整歌词许可无法验证；客户端会尝试匹配合规来源，但不保证每个结果都有可播放版本；
- Internet Archive 元数据质量不一致，部分条目可能没有可解析 MP3；
- iOS 使用 `--no-codesign` 构建；Android 当前沿用 Flutter 模板的调试签名生成 release APK，仅用于 CI 验证，正式上架前必须配置发行方密钥；
- 本地文件元数据目前从文件名生成，后续可增加跨平台 ID3 解析器；
- 下载任务当前串行执行，尚未提供批量队列、暂停和断点续传；
- 播放器目前以前台播放为验收范围，系统媒体通知与抗进程回收的后台服务尚未接入；
- 当前是单设备偏好，不含账号或云同步。

## 参考

- [AlgerMusicPlayer](https://github.com/algerkong/AlgerMusicPlayer)：参考功能分区和播放器信息架构，不复用其第三方解锁逻辑；
- [SmartRecom](https://github.com/LRH1993/SmartRecom)：参考行为识别的产品概念；其 README 明确个性化功能未完成，因此本项目使用独立、可测试的隐式反馈模型；
- [UI/UX Pro Max Skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)：用于设计系统、响应式、无障碍和交付检查；
- [Flutter 官方文档](https://docs.flutter.dev/)；
- [iTunes Search API](https://performance-partners.apple.com/search-api)；
- [Internet Archive Metadata API](https://archive.org/developers/md-read.html)。
