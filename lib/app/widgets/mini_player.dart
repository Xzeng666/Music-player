import 'package:flutter/material.dart';

import '../../features/playback/domain/player_service.dart';
import '../app_controller.dart';
import '../app_scope.dart';
import '../app_shell.dart';
import 'song_artwork.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({required this.compact, super.key});

  final bool compact;

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  double volume = 0.8;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final song = controller.currentSong!;
    final playbackBusy = controller.isResolving || controller.isCaching;
    final durationMs = controller.duration?.inMilliseconds ?? 0;
    final positionMs = controller.position.inMilliseconds.clamp(0, durationMs);

    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            widget.compact ? 12 : 24,
            8,
            widget.compact ? 12 : 24,
            10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Slider(
                value: durationMs <= 0 ? 0 : positionMs.toDouble(),
                max: durationMs <= 0 ? 1 : durationMs.toDouble(),
                onChanged: durationMs <= 0
                    ? null
                    : (value) => controller.seek(
                        Duration(milliseconds: value.round()),
                      ),
              ),
              Row(
                children: <Widget>[
                  SongArtwork(
                    url: song.artworkUrl,
                    size: widget.compact ? 48 : 56,
                  ),
                  const SizedBox(width: 12),
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
                        Text(
                          '${song.artist} · ${sourceLabel(song.source)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '上一首',
                    onPressed: playbackBusy ? null : controller.previous,
                    icon: const Icon(Icons.skip_previous_rounded),
                  ),
                  Semantics(
                    button: true,
                    label: controller.isPlaying ? '暂停' : '播放',
                    child: IconButton.filled(
                      onPressed: controller.togglePlayPause,
                      icon: Icon(
                        controller.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '下一首',
                    onPressed: playbackBusy ? null : controller.next,
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                  if (!widget.compact) ...<Widget>[
                    const SizedBox(width: 8),
                    _PlaybackModeGroup(controller: controller),
                    const SizedBox(width: 6),
                    const Icon(Icons.volume_down_rounded, size: 20),
                    SizedBox(
                      width: 96,
                      child: Slider(
                        value: volume,
                        onChanged: (value) {
                          setState(() => volume = value);
                          controller.setVolume(value);
                        },
                      ),
                    ),
                  ],
                ],
              ),
              if (widget.compact)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        '播放模式',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(width: 10),
                      _PlaybackModeGroup(controller: controller),
                    ],
                  ),
                ),
              if (controller.playbackError != null)
                Semantics(
                  liveRegion: true,
                  child: _StatusLine(
                    icon: Icons.error_outline,
                    text: controller.playbackError!,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaybackModeGroup extends StatelessWidget {
  const _PlaybackModeGroup({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          tooltip: controller.shuffle ? '关闭随机播放' : '开启随机播放',
          onPressed: controller.toggleShuffle,
          icon: Icon(
            Icons.shuffle_rounded,
            color: controller.shuffle
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        ),
        SizedBox(
          height: 32,
          child: VerticalDivider(
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        IconButton(
          tooltip: '${repeatModeLabel(controller.repeatMode)}，点击切换',
          onPressed: controller.cycleRepeatMode,
          icon: Icon(
            repeatIcon(controller.repeatMode),
            color: controller.repeatMode == PlaybackRepeatMode.off
                ? null
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ),
  );
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(color: color)),
        ),
      ],
    ),
  );
}
