import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../catalog/domain/song.dart';
import '../domain/player_service.dart';

class AudioplayersPlayerService implements PlayerService {
  AudioplayersPlayerService({AudioPlayer? player})
    : _player = player ?? AudioPlayer() {
    _positionSubscription = _player.onPositionChanged.listen((value) {
      _position = value;
    });
  }

  final AudioPlayer _player;
  final StreamController<Object?> _errors =
      StreamController<Object?>.broadcast();
  late final StreamSubscription<Duration> _positionSubscription;
  Song? _currentSong;
  Duration _position = Duration.zero;

  @override
  Stream<void> get completedStream => _player.onPlayerComplete;

  @override
  Song? get currentSong => _currentSong;

  @override
  Stream<Duration?> get durationStream =>
      _player.onDurationChanged.map<Duration?>((value) => value);

  @override
  Stream<Object?> get errorStream => _errors.stream;

  @override
  bool get isPlaying => _player.state == PlayerState.playing;

  @override
  Stream<bool> get playingStream =>
      _player.onPlayerStateChanged.map((state) => state == PlayerState.playing);

  @override
  Duration get position => _position;

  @override
  Stream<Duration> get positionStream => _player.onPositionChanged;

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> play(Song song) async {
    if (!song.isPlayable) {
      throw StateError('Song does not have a playable URI.');
    }
    try {
      _currentSong = song;
      _position = Duration.zero;
      final source = song.localPath != null
          ? DeviceFileSource(song.localPath!)
          : UrlSource(song.audioUrl!);
      await _player.play(source);
    } on Object catch (error) {
      _errors.add(error);
      rethrow;
    }
  }

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setRepeatMode(PlaybackRepeatMode mode) => _player.setReleaseMode(
    mode == PlaybackRepeatMode.one ? ReleaseMode.loop : ReleaseMode.release,
  );

  @override
  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0, 1));

  @override
  Future<void> dispose() async {
    await _positionSubscription.cancel();
    await _player.dispose();
    await _errors.close();
  }
}
