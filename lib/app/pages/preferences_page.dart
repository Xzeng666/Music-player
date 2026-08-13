import 'package:flutter/material.dart';

import '../../features/recommendations/domain/preference_profile.dart';
import '../app_scope.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final profile = controller.profile;
    final entries =
        profile.tagScores.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(12).toList();
    final maxScore = topEntries.isEmpty ? 1.0 : topEntries.first.value;

    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('偏好与隐私', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                const Text('所有行为与标签分值默认只保存在当前设备。'),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(child: _ReadinessCard(profile: profile)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          sliver: SliverToBoxAdapter(
            child: Text(
              '当前偏好标签',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
        if (topEntries.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Text('完成播放、收藏或跳过歌曲后，这里会显示偏好变化。'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList.separated(
              itemCount: topEntries.length,
              itemBuilder: (context, index) {
                final entry = topEntries[index];
                return _PreferenceBar(
                  label: _friendlyLabel(entry.key),
                  value: entry.value / maxScore,
                  score: entry.value,
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 12),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          sliver: SliverToBoxAdapter(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 18,
                  runSpacing: 14,
                  children: <Widget>[
                    const SizedBox(
                      width: 560,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '重置推荐数据',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text('删除本地行为和偏好分值；不会删除收藏、本地文件或下载内容。'),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _confirmReset(context),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('重置偏好'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final controller = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置偏好数据？'),
        content: const Text('行为历史和推荐标签分值会被清空，此操作无法撤销。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.resetPreferences();
  }

  String _friendlyLabel(String tag) {
    const labels = <String, String>{
      'genre:pop': '流行',
      'genre:rock': '摇滚',
      'genre:electronic': '电子',
      'genre:classical': '古典',
      'genre:jazz': '爵士',
      'genre:hip-hop': '说唱',
      'genre:folk': '民谣',
      'genre:soundtrack': '原声',
      'mood:calm': '平静',
      'mood:uplifting': '明亮',
      'mood:melancholic': '感性',
      'mood:romantic': '浪漫',
      'mood:intense': '强烈',
      'energy:high': '高能量',
      'energy:medium': '适中能量',
      'energy:low': '低能量',
      'scene:focus': '专注',
      'scene:workout': '运动',
      'scene:relax': '放松',
      'language:zh': '华语',
      'language:en': '英语',
      'language:ja': '日语',
      'language:ko': '韩语',
    };
    return labels[tag] ?? tag.split(':').last;
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.profile});

  final PreferenceProfile profile;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(profile.isReady ? Icons.verified : Icons.insights),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  profile.isReady ? '个性化推荐已开启' : '正在学习你的偏好',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text('${(profile.progress * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: profile.progress,
            minHeight: 9,
            borderRadius: BorderRadius.circular(9),
          ),
          const SizedBox(height: 12),
          Text(
            '${profile.meaningfulEventCount}/${PreferenceProfile.minimumMeaningfulEvents} 个有效行为'
            ' · 置信度 ${profile.confidence.toStringAsFixed(1)}/${PreferenceProfile.minimumConfidence.toStringAsFixed(1)}',
          ),
        ],
      ),
    ),
  );
}

class _PreferenceBar extends StatelessWidget {
  const _PreferenceBar({
    required this.label,
    required this.value,
    required this.score,
  });

  final String label;
  final double value;
  final double score;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      SizedBox(
        width: 92,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      Expanded(
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 10,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      const SizedBox(width: 12),
      SizedBox(
        width: 44,
        child: Text(score.toStringAsFixed(1), textAlign: TextAlign.end),
      ),
    ],
  );
}
