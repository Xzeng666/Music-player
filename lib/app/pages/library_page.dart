import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../widgets/song_tile.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final songs = controller.librarySongs;
    final recentSongs = controller.recentSongs;
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '我的音乐库',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 6),
                    Text('${songs.length} 首 · 收藏、本地文件和授权下载'),
                  ],
                ),
                FilledButton.icon(
                  onPressed: controller.isImporting
                      ? null
                      : controller.importLocalSongs,
                  icon: controller.isImporting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.library_add_outlined),
                  label: const Text('导入本地音乐'),
                ),
              ],
            ),
          ),
        ),
        if (songs.isEmpty && recentSongs.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.queue_music_rounded, size: 58),
                    const SizedBox(height: 14),
                    Text(
                      '音乐库还是空的',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('导入你有权使用的本地音频，或在搜索页收藏歌曲。'),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: controller.importLocalSongs,
                      icon: const Icon(Icons.add),
                      label: const Text('选择音频文件'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (songs.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverList.separated(
              itemCount: songs.length,
              itemBuilder: (context, index) =>
                  SongTile(song: songs[index], queue: songs),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
            ),
          ),
        if (recentSongs.isNotEmpty) ...<Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                '最近播放',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverList.separated(
              itemCount: recentSongs.length,
              itemBuilder: (context, index) =>
                  SongTile(song: recentSongs[index], queue: recentSongs),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
            ),
          ),
        ],
      ],
    );
  }
}
