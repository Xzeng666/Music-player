import 'dart:math' as math;

import '../../catalog/domain/song.dart';
import 'preference_profile.dart';

class Recommendation {
  const Recommendation({
    required this.song,
    required this.score,
    required this.reason,
    required this.isPersonalized,
  });

  final Song song;
  final double score;
  final String reason;
  final bool isPersonalized;
}

class RecommendationEngine {
  const RecommendationEngine();

  List<Recommendation> rank({
    required Iterable<Song> candidates,
    required PreferenceProfile profile,
    Set<String> recentlyPlayedSongIds = const <String>{},
    int limit = 12,
    DateTime? now,
  }) {
    final referenceTime = now ?? DateTime.now();
    final scored =
        candidates
            .where((song) => !profile.dislikedSongIds.contains(song.id))
            .map((song) {
              if (!profile.isReady) {
                final freshness = _freshness(song, referenceTime);
                return Recommendation(
                  song: song,
                  score: freshness + _sourcePrior(song),
                  reason: song.source == MusicSourceKind.internetArchive
                      ? '开放授权音乐 · 探索新声音'
                      : '新用户精选 · 继续收听以优化推荐',
                  isPersonalized: false,
                );
              }

              final contributions = <MapEntry<String, double>>[];
              var matchScore = 0.0;
              for (final tag in song.tags) {
                final contribution =
                    (profile.tagScores[tag.name] ?? 0) * tag.confidence;
                matchScore += contribution;
                if (contribution > 0) {
                  contributions.add(MapEntry(tag.name, contribution));
                }
              }
              contributions.sort((a, b) => b.value.compareTo(a.value));
              final repetitionPenalty = recentlyPlayedSongIds.contains(song.id)
                  ? 2
                  : 0;
              final score =
                  matchScore +
                  _freshness(song, referenceTime) +
                  _sourcePrior(song) -
                  repetitionPenalty;
              final reasons = contributions
                  .take(2)
                  .map((entry) => _friendlyTag(entry.key))
                  .join(' · ');
              return Recommendation(
                song: song,
                score: score,
                reason: reasons.isEmpty ? '扩展你的音乐边界' : '因为你偏爱 $reasons',
                isPersonalized: true,
              );
            })
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

    final diversified = <Recommendation>[];
    final artistCounts = <String, int>{};
    for (final item in scored) {
      final normalizedArtist = item.song.artist.toLowerCase();
      final count = artistCounts[normalizedArtist] ?? 0;
      if (count >= 2 && scored.length > limit) continue;
      artistCounts[normalizedArtist] = count + 1;
      diversified.add(item);
      if (diversified.length >= math.max(0, limit)) break;
    }
    return diversified;
  }

  double _freshness(Song song, DateTime now) {
    final releaseDate = song.releaseDate;
    if (releaseDate == null) return 0.1;
    final ageDays = math.max(0, now.difference(releaseDate).inDays);
    return math.exp(-ageDays / 3650);
  }

  double _sourcePrior(Song song) => switch (song.source) {
    MusicSourceKind.local => 0.4,
    MusicSourceKind.internetArchive => 0.3,
    MusicSourceKind.itunesPreview => 0.2,
    MusicSourceKind.gequhaiWeb => 0.05,
  };

  String _friendlyTag(String tag) {
    const labels = <String, String>{
      'genre:pop': '流行',
      'genre:rock': '摇滚',
      'genre:electronic': '电子',
      'genre:classical': '古典',
      'genre:jazz': '爵士',
      'genre:hip-hop': '说唱',
      'genre:folk': '民谣',
      'genre:soundtrack': '原声',
      'genre:r&b': 'R&B',
      'mood:calm': '平静氛围',
      'mood:uplifting': '明亮情绪',
      'mood:melancholic': '感性情绪',
      'mood:romantic': '浪漫氛围',
      'mood:intense': '强烈氛围',
      'energy:high': '高能量',
      'energy:medium': '适中能量',
      'energy:low': '低能量',
      'scene:focus': '专注场景',
      'scene:workout': '运动场景',
      'scene:relax': '放松场景',
    };
    return labels[tag] ?? tag.split(':').last;
  }
}
