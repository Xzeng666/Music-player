import '../../catalog/domain/song.dart';
import '../../recommendations/domain/listening_event.dart';

class LibrarySnapshot {
  const LibrarySnapshot({
    this.knownSongs = const <String, Song>{},
    this.localSongIds = const <String>{},
    this.favoriteSongIds = const <String>{},
    this.events = const <ListeningEvent>[],
    this.downloadPaths = const <String, String>{},
    this.playbackCacheLimit = 20,
  });

  final Map<String, Song> knownSongs;
  final Set<String> localSongIds;
  final Set<String> favoriteSongIds;
  final List<ListeningEvent> events;
  final Map<String, String> downloadPaths;
  final int playbackCacheLimit;

  LibrarySnapshot copyWith({
    Map<String, Song>? knownSongs,
    Set<String>? localSongIds,
    Set<String>? favoriteSongIds,
    List<ListeningEvent>? events,
    Map<String, String>? downloadPaths,
    int? playbackCacheLimit,
  }) => LibrarySnapshot(
    knownSongs: knownSongs ?? this.knownSongs,
    localSongIds: localSongIds ?? this.localSongIds,
    favoriteSongIds: favoriteSongIds ?? this.favoriteSongIds,
    events: events ?? this.events,
    downloadPaths: downloadPaths ?? this.downloadPaths,
    playbackCacheLimit: playbackCacheLimit ?? this.playbackCacheLimit,
  );
}

abstract interface class LibraryRepository {
  Future<LibrarySnapshot> load();
  Future<void> save(LibrarySnapshot snapshot);
  Future<void> clearPreferences();
}
