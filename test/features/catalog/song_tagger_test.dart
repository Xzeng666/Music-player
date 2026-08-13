import 'package:flutter_test/flutter_test.dart';
import 'package:resonance_music/features/catalog/domain/song.dart';
import 'package:resonance_music/features/catalog/domain/song_tagger.dart';

void main() {
  const tagger = SongTagger();

  test('creates multiple normalized tags from metadata', () {
    final tags = tagger.fromMetadata(
      source: MusicSourceKind.itunesPreview,
      title: '快乐舞曲',
      artist: '测试歌手',
      genre: 'Electronic Dance',
      releaseDate: DateTime(2024),
    );
    final names = tags.map((tag) => tag.name).toSet();

    expect(names, contains('source:itunesPreview'));
    expect(names, contains('genre:electronic'));
    expect(names, contains('mood:uplifting'));
    expect(names, contains('energy:high'));
    expect(names, contains('language:zh'));
    expect(names, contains('decade:2020'));
  });

  test('falls back to medium energy for unknown metadata', () {
    final tags = tagger.fromMetadata(
      source: MusicSourceKind.local,
      title: 'Track 01',
      artist: 'Unknown',
    );

    expect(tags.map((tag) => tag.name), contains('energy:medium'));
  });
}
