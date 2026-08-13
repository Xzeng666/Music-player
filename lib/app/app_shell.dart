import 'package:flutter/material.dart';

import '../features/catalog/domain/song.dart';
import '../features/playback/domain/player_service.dart';
import 'app_controller.dart';
import 'app_scope.dart';
import 'pages/discover_page.dart';
import 'pages/library_page.dart';
import 'pages/preferences_page.dart';
import 'pages/search_page.dart';
import 'widgets/mini_player.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: '发现',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search),
      label: '搜索',
    ),
    NavigationDestination(
      icon: Icon(Icons.library_music_outlined),
      selectedIcon: Icon(Icons.library_music),
      label: '音乐库',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: '设置',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    if (!controller.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final index = controller.section.index;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final extended = constraints.maxWidth >= 1200;
        final content = Column(
          children: <Widget>[
            Expanded(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(controller.section),
                  child: switch (controller.section) {
                    AppSection.discover => const DiscoverPage(),
                    AppSection.search => const SearchPage(),
                    AppSection.library => const LibraryPage(),
                    AppSection.preferences => const PreferencesPage(),
                  },
                ),
              ),
            ),
            if (controller.isDownloading)
              Semantics(
                liveRegion: true,
                label: '正在下载，${(controller.downloadProgress * 100).round()}%',
                child: LinearProgressIndicator(
                  value: controller.downloadProgress == 0
                      ? null
                      : controller.downloadProgress,
                ),
              ),
            if (controller.isCaching)
              Semantics(
                liveRegion: true,
                label: '正在缓存授权音频，${(controller.cacheProgress * 100).round()}%',
                child: LinearProgressIndicator(
                  value: controller.cacheProgress == 0
                      ? null
                      : controller.cacheProgress,
                ),
              ),
            if (controller.isResolving)
              Semantics(
                liveRegion: true,
                label: '正在匹配可播放的授权版本',
                child: LinearProgressIndicator(),
              ),
            if (controller.transientMessage != null)
              _GlobalStatusBanner(
                message: controller.transientMessage!,
                onDismiss: controller.clearTransientMessage,
              ),
            if (controller.currentSong != null)
              MiniPlayer(compact: constraints.maxWidth < 700),
          ],
        );

        return Scaffold(
          body: SafeArea(
            bottom: wide,
            child: wide
                ? Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 4, 16),
                        child: NavigationRail(
                          extended: extended,
                          selectedIndex: index,
                          onDestinationSelected: (value) => controller
                              .selectSection(AppSection.values[value]),
                          leading: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _BrandMark(showLabel: extended),
                          ),
                          destinations: _destinations
                              .map(
                                (destination) => NavigationRailDestination(
                                  icon: destination.icon,
                                  selectedIcon: destination.selectedIcon,
                                  label: Text(destination.label),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: content),
                    ],
                  )
                : content,
          ),
          bottomNavigationBar: wide
              ? null
              : SafeArea(
                  top: false,
                  child: NavigationBar(
                    selectedIndex: index,
                    onDestinationSelected: (value) =>
                        controller.selectSection(AppSection.values[value]),
                    destinations: _destinations,
                  ),
                ),
        );
      },
    );
  }
}

class _GlobalStatusBanner extends StatelessWidget {
  const _GlobalStatusBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: ColoredBox(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: <Widget>[
            const Icon(Icons.info_outline, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            IconButton(
              tooltip: '关闭提示',
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.showLabel});

  final bool showLabel;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.graphic_eq_rounded, color: Colors.white),
        ),
      ),
      if (showLabel) ...<Widget>[
        const SizedBox(width: 12),
        Text('Resonance', style: Theme.of(context).textTheme.titleLarge),
      ],
    ],
  );
}

String sourceLabel(MusicSourceKind source) => switch (source) {
  MusicSourceKind.local => '本地',
  MusicSourceKind.gequhaiWeb => '歌曲海网页',
  MusicSourceKind.itunesPreview => '30 秒试听',
  MusicSourceKind.internetArchive => '开放音乐',
};

IconData repeatIcon(PlaybackRepeatMode mode) => switch (mode) {
  PlaybackRepeatMode.off => Icons.repeat,
  PlaybackRepeatMode.all => Icons.repeat_on,
  PlaybackRepeatMode.one => Icons.repeat_one_on,
};

String repeatModeLabel(PlaybackRepeatMode mode) => switch (mode) {
  PlaybackRepeatMode.off => '循环关闭',
  PlaybackRepeatMode.all => '列表循环',
  PlaybackRepeatMode.one => '单曲循环',
};
