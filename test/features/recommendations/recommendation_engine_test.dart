import 'package:flutter_test/flutter_test.dart';
import 'package:resonance_music/features/catalog/domain/song.dart';
import 'package:resonance_music/features/recommendations/domain/listening_event.dart';
import 'package:resonance_music/features/recommendations/domain/preference_profile.dart';
import 'package:resonance_music/features/recommendations/domain/recommendation_engine.dart';

void main() {
  final popSong = Song(
    id: 'pop',
    title: 'Pop Song',
    artist: 'Artist A',
    source: MusicSourceKind.itunesPreview,
    tags: const <SongTag>[
      SongTag(name: 'genre:pop', confidence: 1),
      SongTag(name: 'energy:high', confidence: 0.8),
    ],
  );
  final jazzSong = Song(
    id: 'jazz',
    title: 'Jazz Song',
    artist: 'Artist B',
    source: MusicSourceKind.internetArchive,
    tags: const <SongTag>[
      SongTag(name: 'genre:jazz', confidence: 1),
      SongTag(name: 'energy:low', confidence: 0.8),
    ],
  );

  test('keeps cold start until both thresholds are reached', () {
    final now = DateTime(2026, 8, 13);
    final events = List<ListeningEvent>.generate(
      7,
      (_) => ListeningEvent(
        songId: popSong.id,
        type: ListeningEventType.favorite,
        occurredAt: now,
      ),
    );
    final profile = const PreferenceProfileBuilder().build(
      events: events,
      songsById: <String, Song>{popSong.id: popSong},
      now: now,
    );

    expect(
      profile.confidence,
      greaterThan(PreferenceProfile.minimumConfidence),
    );
    expect(profile.meaningfulEventCount, 7);
    expect(profile.isReady, isFalse);
  });

  test('ranks matching tags first and explains the result', () {
    final now = DateTime(2026, 8, 13);
    final events = List<ListeningEvent>.generate(
      8,
      (_) => ListeningEvent(
        songId: popSong.id,
        type: ListeningEventType.favorite,
        occurredAt: now,
      ),
    );
    final profile = const PreferenceProfileBuilder().build(
      events: events,
      songsById: <String, Song>{popSong.id: popSong},
      now: now,
    );
    final ranked = const RecommendationEngine().rank(
      candidates: <Song>[jazzSong, popSong],
      profile: profile,
      now: now,
    );

    expect(profile.isReady, isTrue);
    expect(ranked.first.song.id, popSong.id);
    expect(ranked.first.reason, contains('流行'));
    expect(ranked.first.isPersonalized, isTrue);
  });

  test('excludes explicitly disliked songs', () {
    final now = DateTime(2026, 8, 13);
    final profile = const PreferenceProfileBuilder().build(
      events: <ListeningEvent>[
        ListeningEvent(
          songId: jazzSong.id,
          type: ListeningEventType.dislike,
          occurredAt: now,
        ),
      ],
      songsById: <String, Song>{jazzSong.id: jazzSong},
      now: now,
    );
    final ranked = const RecommendationEngine().rank(
      candidates: <Song>[jazzSong],
      profile: profile,
      now: now,
    );

    expect(ranked, isEmpty);
  });
}
