import 'dart:math' as math;

import '../../catalog/domain/song.dart';
import 'listening_event.dart';

class PreferenceProfile {
  const PreferenceProfile({
    required this.tagScores,
    required this.meaningfulEventCount,
    required this.confidence,
    required this.dislikedSongIds,
  });

  static const minimumMeaningfulEvents = 8;
  static const minimumConfidence = 6.0;

  final Map<String, double> tagScores;
  final int meaningfulEventCount;
  final double confidence;
  final Set<String> dislikedSongIds;

  bool get isReady =>
      meaningfulEventCount >= minimumMeaningfulEvents &&
      confidence >= minimumConfidence;

  double get progress {
    final eventProgress = meaningfulEventCount / minimumMeaningfulEvents;
    final confidenceProgress = confidence / minimumConfidence;
    return math.min(1, math.min(eventProgress, confidenceProgress));
  }
}

class PreferenceProfileBuilder {
  const PreferenceProfileBuilder();

  PreferenceProfile build({
    required Iterable<ListeningEvent> events,
    required Map<String, Song> songsById,
    DateTime? now,
  }) {
    final referenceTime = now ?? DateTime.now();
    final tagScores = <String, double>{};
    final dislikedSongIds = <String>{};
    var meaningfulEvents = 0;
    var confidence = 0.0;

    for (final event in events) {
      final song = songsById[event.songId];
      if (song == null) continue;
      if (event.isMeaningful) meaningfulEvents++;

      if (event.type == ListeningEventType.dislike) {
        dislikedSongIds.add(event.songId);
      } else if (event.baseWeight > 0) {
        dislikedSongIds.remove(event.songId);
      }

      final ageDays = referenceTime.difference(event.occurredAt).inHours / 24;
      final decay = math.pow(0.5, math.max(0, ageDays) / 45).toDouble();
      final weightedEvidence = event.baseWeight * decay;
      confidence += event.isMeaningful ? weightedEvidence.abs() : 0;

      for (final tag in song.tags) {
        tagScores.update(
          tag.name,
          (score) => score + weightedEvidence * tag.confidence,
          ifAbsent: () => weightedEvidence * tag.confidence,
        );
      }
    }

    return PreferenceProfile(
      tagScores: Map<String, double>.unmodifiable(tagScores),
      meaningfulEventCount: meaningfulEvents,
      confidence: confidence,
      dislikedSongIds: Set<String>.unmodifiable(dislikedSongIds),
    );
  }
}
