import 'package:flutter/material.dart';

import '../../features/catalog/domain/song.dart';
import '../../features/recommendations/domain/recommendation_engine.dart';
import '../app_controller.dart';
import '../app_scope.dart';
import '../widgets/song_artwork.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final recommendations = controller.recommendations;
    final profile = controller.profile;

    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          sliver: SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: _DiscoverHero(
                progress: profile.progress,
                isReady: profile.isReady,
                onSearch: () => controller.selectSection(AppSection.search),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              title: profile.isReady ? '为你推荐' : '从这里开始',
              subtitle: profile.isReady
                  ? '在设备上根据你的标签偏好排序'
                  : '还需一些真实收听行为，当前使用多样性精选',
            ),
          ),
        ),
        if (controller.isSearching && recommendations.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (recommendations.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyDiscover(
              onSearch: () => controller.selectSection(AppSection.search),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = width >= 1180
                    ? 4
                    : width >= 760
                    ? 3
                    : width >= 500
                    ? 2
                    : 1;
                return SliverGrid.builder(
                  itemCount: recommendations.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: columns == 1 ? 124 : 268,
                  ),
                  itemBuilder: (context, index) => _RecommendationCard(
                    item: recommendations[index],
                    queue: recommendations.map((item) => item.song).toList(),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _DiscoverHero extends StatelessWidget {
  const _DiscoverHero({
    required this.progress,
    required this.isReady,
    required this.onSearch,
  });

  final double progress;
  final bool isReady;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 680;
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF3F3AB8), Color(0xFF706AEF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 24 : 36),
          child: Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: compact ? 0 : 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      '你的声音，\n由你慢慢定义。',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isReady
                          ? '个性化推荐已开启，所有偏好仅保存在这台设备。'
                          : '收藏、完整播放或跳过都会帮助建立你的本地偏好。',
                      style: const TextStyle(
                        color: Color(0xFFE8E7FF),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: onSearch,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF3530A3),
                      ),
                      icon: const Icon(Icons.search),
                      label: const Text('搜索音乐'),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 0 : 48, height: compact ? 28 : 0),
              Expanded(
                flex: compact ? 0 : 2,
                child: _LearningProgress(progress: progress, ready: isReady),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _LearningProgress extends StatelessWidget {
  const _LearningProgress({required this.progress, required this.ready});

  final double progress;
  final bool ready;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                ready ? Icons.auto_awesome : Icons.insights_outlined,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                ready ? '偏好已就绪' : '偏好学习中',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF64E5AE),
            backgroundColor: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 10),
          Text(
            '${(progress * 100).round()}% · ${ready ? '持续随收听变化' : '至少需要 8 个有效行为'}',
            style: const TextStyle(color: Color(0xFFE8E7FF)),
          ),
        ],
      ),
    ),
  );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item, required this.queue});

  final Recommendation item;
  final List<Song> queue;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final song = item.song;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => controller.playSong(song, queue: queue),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth > constraints.maxHeight * 2;
            final artwork = SongArtwork(
              url: song.artworkUrl,
              size: horizontal ? 96 : constraints.maxWidth,
              borderRadius: horizontal ? 16 : 0,
            );
            final details = Expanded(
              child: Padding(
                padding: horizontal
                    ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
                    : const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SizedBox(height: horizontal ? 4 : 8),
                    Text(
                      item.reason,
                      maxLines: horizontal ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
            if (horizontal) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: <Widget>[artwork, details]),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: artwork),
                details,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 4),
      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}

class _EmptyDiscover extends StatelessWidget {
  const _EmptyDiscover({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.music_note_outlined, size: 56),
          const SizedBox(height: 14),
          Text('还没有候选音乐', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('搜索或导入歌曲后，这里会生成推荐。'),
          const SizedBox(height: 18),
          FilledButton(onPressed: onSearch, child: const Text('去搜索')),
        ],
      ),
    ),
  );
}
