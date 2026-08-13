import '../../catalog/domain/song.dart';

enum PlaybackRepeatMode { all, one, off }

abstract interface class PlayerService {
  Stream<bool> get playingStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<Object?> get errorStream;
  Stream<void> get completedStream;

  bool get isPlaying;
  Duration get position;
  Song? get currentSong;

  Future<void> play(Song song);
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setRepeatMode(PlaybackRepeatMode mode);
  Future<void> dispose();
}
