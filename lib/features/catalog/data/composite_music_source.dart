import '../domain/music_source.dart';
import '../domain/song.dart';

class CompositeMusicSource implements MusicSource {
  CompositeMusicSource(this.sources, {this.primarySourceId});

  final List<MusicSource> sources;
  final String? primarySourceId;

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
    final primaryIndex = sources.indexWhere(
      (source) => source.id == primarySourceId,
    );
    if (primaryIndex >= 0) {
      for (final song in results[primaryIndex]) {
        if (seen.add(song.id)) merged.add(song);
        if (merged.length >= limit) return List<Song>.unmodifiable(merged);
      }
    }

    final secondaryResults = <List<Song>>[
      for (var sourceIndex = 0; sourceIndex < results.length; sourceIndex++)
        if (sourceIndex != primaryIndex) results[sourceIndex],
    ];
    var index = 0;
    while (merged.length < limit &&
        secondaryResults.any((group) => index < group.length)) {
      for (final group in secondaryResults) {
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
  Future<Song> resolve(Song song) async {
    if (song.source == MusicSourceKind.gequhaiWeb) {
      return _resolveGequhaiMatch(song);
    }
    final source = sources.where((candidate) {
      return switch (song.source) {
        MusicSourceKind.itunesPreview => candidate.id == 'itunes-preview',
        MusicSourceKind.internetArchive => candidate.id == 'internet-archive',
        MusicSourceKind.gequhaiWeb => false,
        MusicSourceKind.local => false,
      };
    }).firstOrNull;
    if (source == null) return song;
    return source.resolve(song);
  }

  Future<Song> _resolveGequhaiMatch(Song song) async {
    final providers = sources.where((item) => item.id != 'gequhai-web');
    final groups = await Future.wait(
      providers.map((source) async {
        try {
          final matches = await source.search(song.title, limit: 20);
          return <({MusicSource source, Song song, int score})>[
            for (final match in matches)
              if (_matchScore(song, match) >= 6)
                (source: source, song: match, score: _matchScore(song, match)),
          ];
        } on CatalogException {
          // One unavailable provider must not prevent matching another one.
          return <({MusicSource source, Song song, int score})>[];
        }
      }),
    );
    final candidates = groups.expand((group) => group).toList();
    candidates.sort((a, b) => b.score.compareTo(a.score));
    for (final candidate in candidates) {
      try {
        final resolved = await candidate.source.resolve(candidate.song);
        if (resolved.isPlayable) return resolved;
      } on CatalogException {
        // Try the next sufficiently close, authorized candidate.
      }
    }
    throw const CatalogException('未找到可在应用内合规播放的匹配版本。');
  }

  int _matchScore(Song requested, Song candidate) {
    final requestedTitle = _normalized(requested.title);
    final candidateTitle = _normalized(candidate.title);
    final requestedArtist = _normalized(requested.artist);
    final candidateArtist = _normalized(candidate.artist);
    var score = 0;
    if (requestedTitle == candidateTitle) {
      score += 4;
    } else if (requestedTitle.contains(candidateTitle) ||
        candidateTitle.contains(requestedTitle)) {
      score += 2;
    }
    if (requestedArtist == candidateArtist) {
      score += 4;
    } else if (requestedArtist.contains(candidateArtist) ||
        candidateArtist.contains(requestedArtist)) {
      score += 2;
    }
    if (candidate.downloadAllowed) score += 1;
    return score;
  }

  String _normalized(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]'), '');
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
