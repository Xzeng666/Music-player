import '../domain/music_source.dart';
import '../domain/song.dart';

class CompositeMusicSource implements MusicSource {
  CompositeMusicSource(this.sources);

  final List<MusicSource> sources;

  @override
  String get displayName => '全部在线来源';

  @override
  String get id => 'composite';

  @override
  Future<List<Song>> search(String query, {int limit = 20}) async {
    final results = await Future.wait(
      sources.map((source) async {
        try {
          return await source.search(query, limit: limit);
        } on CatalogException {
          return const <Song>[];
        }
      }),
    );
    final merged = <Song>[];
    final seen = <String>{};
    var index = 0;
    while (merged.length < limit &&
        results.any((group) => index < group.length)) {
      for (final group in results) {
        if (index >= group.length) continue;
        final song = group[index];
        if (seen.add(song.id)) merged.add(song);
        if (merged.length >= limit) break;
      }
      index++;
    }
    return List<Song>.unmodifiable(merged);
  }

  @override
  Future<Song> resolve(Song song) {
    final source = sources.where((candidate) {
      return switch (song.source) {
        MusicSourceKind.itunesPreview => candidate.id == 'itunes-preview',
        MusicSourceKind.internetArchive => candidate.id == 'internet-archive',
        MusicSourceKind.local => false,
      };
    }).firstOrNull;
    return source?.resolve(song) ?? Future<Song>.value(song);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
