import '../../catalog/domain/song.dart';

typedef PlaybackCacheProgress = void Function(double progress);

abstract interface class PlaybackCache {
  Future<Song> prepare(
    Song song, {
    required int maxEntries,
    PlaybackCacheProgress? onProgress,
  });

  Future<int> count();

  Future<int> enforceLimit(int maxEntries);

  Future<void> clear();
}

class PlaybackCacheException implements Exception {
  const PlaybackCacheException(this.message, {this.cause});

  final String message;
  final Object? cause;
}
