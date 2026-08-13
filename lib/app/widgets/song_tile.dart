import 'package:flutter/material.dart';

import '../../features/catalog/domain/song.dart';
import '../app_scope.dart';
import '../app_shell.dart';
import 'song_artwork.dart';

class SongTile extends StatelessWidget {
  const SongTile({required this.song, this.queue, this.subtitle, super.key});

  final Song song;
  final List<Song>? queue;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isFavorite = controller.favoriteSongIds.contains(song.id);
    final isCurrent = controller.currentSong?.id == song.id;
    return Semantics(
      button: true,
      label: '播放 ${song.title}，${song.artist}',
      child: Card(
        color: isCurrent
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.5)
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => controller.playSong(song, queue: queue),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                SongArtwork(url: song.artworkUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle ??
                            '${song.artist} · ${sourceLabel(song.source)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isFavorite ? '取消收藏' : '收藏',
                  onPressed: () => controller.toggleFavorite(song),
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                ),
                IconButton(
                  tooltip: '播放',
                  onPressed: () => controller.playSong(song, queue: queue),
                  icon: Icon(
                    isCurrent && controller.isPlaying
                        ? Icons.equalizer_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: '更多操作',
                  onSelected: (value) {
                    if (value == 'download') controller.downloadSong(song);
                    if (value == 'dislike') controller.dislikeSong(song);
                  },
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    if (song.downloadAllowed)
                      PopupMenuItem<String>(
                        value: 'download',
                        enabled: !controller.isDownloading,
                        child: const ListTile(
                          leading: Icon(Icons.download_outlined),
                          title: Text('下载开放授权音频'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    const PopupMenuItem<String>(
                      value: 'dislike',
                      child: ListTile(
                        leading: Icon(Icons.thumb_down_outlined),
                        title: Text('减少此类推荐'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
