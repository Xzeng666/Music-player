import 'package:flutter_test/flutter_test.dart';
import 'package:resonance_music/features/catalog/data/composite_music_source.dart';
import 'package:resonance_music/features/catalog/domain/music_source.dart';
import 'package:resonance_music/features/catalog/domain/song.dart';

void main() {
  test('主搜索源的全部结果在可播放补充来源之前保留', () async {
    final source = CompositeMusicSource(<MusicSource>[
      _FakeSource('primary', <Song>[
        _song('web-1', MusicSourceKind.gequhaiWeb),
        _song('web-2', MusicSourceKind.gequhaiWeb),
        _song('web-3', MusicSourceKind.gequhaiWeb),
      ]),
      _FakeSource('playable', <Song>[
        _song('audio-1', MusicSourceKind.itunesPreview),
        _song('audio-2', MusicSourceKind.itunesPreview),
        _song('audio-3', MusicSourceKind.itunesPreview),
      ]),
    ], primarySourceId: 'primary');

    final results = await source.search('稻香', limit: 5);

    expect(results.map((song) => song.id), <String>[
      'web-1',
      'web-2',
      'web-3',
      'audio-1',
      'audio-2',
    ]);
  });

  test('歌曲海结果在应用内匹配同名同歌手的可播放来源', () async {
    const requested = Song(
      id: 'gequhai:333',
      title: '稻香',
      artist: '周杰伦',
      source: MusicSourceKind.gequhaiWeb,
      externalPageUrl: 'https://www.gequhai.com/play/333',
    );
    const playable = Song(
      id: 'itunes:333',
      title: '稻香',
      artist: '周杰伦',
      source: MusicSourceKind.itunesPreview,
      audioUrl: 'https://example.com/preview.mp3',
    );
    final source = CompositeMusicSource(<MusicSource>[
      const _FakeSource('gequhai-web', <Song>[requested]),
      const _FakeSource('itunes-preview', <Song>[playable]),
    ], primarySourceId: 'gequhai-web');

    final resolved = await source.resolve(requested);

    expect(resolved.id, playable.id);
    expect(resolved.audioUrl, playable.audioUrl);
  });
}

class _FakeSource implements MusicSource {
  const _FakeSource(this.id, this.songs);

  @override
  final String id;
  final List<Song> songs;

  @override
  String get displayName => id;

  @override
  Future<Song> resolve(Song song) async => song;

  @override
  Future<List<Song>> search(String query, {int limit = 20}) async => songs;
}

Song _song(String id, MusicSourceKind source) =>
    Song(id: id, title: id, artist: 'artist', source: source);
