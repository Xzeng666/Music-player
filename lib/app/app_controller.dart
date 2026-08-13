import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/catalog/domain/music_source.dart';
import '../features/catalog/domain/song.dart';
import '../features/catalog/domain/song_tagger.dart';
import '../features/library/data/download_service.dart';
import '../features/library/domain/library_repository.dart';
import '../features/playback/domain/player_service.dart';
import '../features/recommendations/domain/listening_event.dart';
import '../features/recommendations/domain/preference_profile.dart';
import '../features/recommendations/domain/recommendation_engine.dart';

enum AppSection { discover, search, library, preferences }

class AppController extends ChangeNotifier {
  AppController({
    required MusicSource musicSource,
    required PlayerService player,
    required LibraryRepository libraryRepository,
    required DownloadService downloadService,
    SongTagger tagger = const SongTagger(),
    RecommendationEngine recommendationEngine = const RecommendationEngine(),
    PreferenceProfileBuilder profileBuilder = const PreferenceProfileBuilder(),
  }) : _musicSource = musicSource,
       _player = player,
       _libraryRepository = libraryRepository,
       _downloadService = downloadService,
       _tagger = tagger,
       _recommendationEngine = recommendationEngine,
       _profileBuilder = profileBuilder {
    _subscriptions.add(_player.playingStream.listen((_) => notifyListeners()));
    _subscriptions.add(
      _player.positionStream.listen((position) {
        _position = position;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _player.durationStream.listen((duration) {
        _duration = duration;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _player.errorStream.listen((error) {
        playbackError = '无法播放这首歌曲，请尝试其他来源。';
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _player.completedStream.listen((_) {
        unawaited(_handleCompleted());
      }),
    );
  }

  final MusicSource _musicSource;
  final PlayerService _player;
  final LibraryRepository _libraryRepository;
  final DownloadService _downloadService;
  final SongTagger _tagger;
  final RecommendationEngine _recommendationEngine;
  final PreferenceProfileBuilder _profileBuilder;
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  LibrarySnapshot _snapshot = const LibrarySnapshot();
  List<Song> _searchResults = const <Song>[];
  List<Song> _queue = const <Song>[];
  Duration _position = Duration.zero;
  Duration? _duration;
  int _queueIndex = -1;
  bool _completedForCurrent = false;

  bool isInitialized = false;
  bool isSearching = false;
  bool isImporting = false;
  bool isDownloading = false;
  double downloadProgress = 0;
  String searchQuery = '';
  String? searchError;
  String? playbackError;
  String? transientMessage;
  AppSection section = AppSection.discover;
  PlaybackRepeatMode repeatMode = PlaybackRepeatMode.off;
  bool shuffle = false;

  bool get isPlaying => _player.isPlaying;
  Song? get currentSong => _player.currentSong;
  Duration get position => _position;
  Duration? get duration => _duration;
  List<Song> get searchResults => List<Song>.unmodifiable(_searchResults);
  Set<String> get favoriteSongIds => _snapshot.favoriteSongIds;

  List<Song> get librarySongs {
    final ids = <String>{
      ..._snapshot.localSongIds,
      ..._snapshot.favoriteSongIds,
      ..._snapshot.downloadPaths.keys,
    };
    return ids
        .map((id) => _snapshot.knownSongs[id])
        .whereType<Song>()
        .toList(growable: false);
  }

  List<Song> get recentSongs {
    final seen = <String>{};
    return _snapshot.events.reversed
        .where((event) => event.type == ListeningEventType.playStarted)
        .map((event) => _snapshot.knownSongs[event.songId])
        .whereType<Song>()
        .where((song) => seen.add(song.id))
        .take(20)
        .toList(growable: false);
  }

  PreferenceProfile get profile => _profileBuilder.build(
    events: _snapshot.events,
    songsById: _snapshot.knownSongs,
  );

  List<Recommendation> get recommendations {
    final candidates = <String, Song>{
      for (final song in _searchResults) song.id: song,
      for (final song in _snapshot.knownSongs.values) song.id: song,
    }.values;
    final recentIds = _snapshot.events.reversed
        .where((event) => event.type == ListeningEventType.playStarted)
        .take(8)
        .map((event) => event.songId)
        .toSet();
    return _recommendationEngine.rank(
      candidates: candidates,
      profile: profile,
      recentlyPlayedSongIds: recentIds,
    );
  }

  Future<void> initialize() async {
    _snapshot = await _libraryRepository.load();
    isInitialized = true;
    notifyListeners();
    await search('流行');
  }

  void selectSection(AppSection value) {
    section = value;
    transientMessage = null;
    notifyListeners();
  }

  void clearTransientMessage() {
    transientMessage = null;
    notifyListeners();
  }

  Future<void> search(String query) async {
    final normalized = query.trim();
    searchQuery = normalized;
    searchError = null;
    if (normalized.isEmpty) {
      _searchResults = const <Song>[];
      notifyListeners();
      return;
    }

    isSearching = true;
    notifyListeners();
    try {
      _searchResults = await _musicSource.search(normalized, limit: 24);
      if (_searchResults.isEmpty) {
        searchError = '没有找到可播放结果，试试“歌名 + 歌手”。';
      }
      for (final song in _searchResults) {
        _rememberSong(song);
      }
      await _persist();
    } on CatalogException catch (error) {
      searchError = error.message;
      _searchResults = const <Song>[];
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  Future<void> playSong(Song song, {List<Song>? queue}) async {
    playbackError = null;
    transientMessage = null;
    await _recordEarlySkipIfNeeded();
    try {
      final resolved = await _musicSource.resolve(song);
      _rememberSong(resolved);
      _queue = queue ?? _searchResults;
      if (_queue.every((item) => item.id != resolved.id)) {
        _queue = <Song>[resolved, ..._queue];
      } else {
        _queue = _queue
            .map((item) => item.id == resolved.id ? resolved : item)
            .toList();
      }
      _queueIndex = _queue.indexWhere((item) => item.id == resolved.id);
      _completedForCurrent = false;
      _position = Duration.zero;
      await _player.play(resolved);
      await _addEvent(resolved, ListeningEventType.playStarted);
    } on Object {
      playbackError = '无法播放这首歌曲，请检查网络或文件权限。';
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (currentSong == null) return;
    if (isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
    notifyListeners();
  }

  Future<void> seek(Duration value) => _player.seek(value);

  Future<void> setVolume(double value) => _player.setVolume(value);

  Future<void> previous() async {
    if (_queue.isEmpty || _queueIndex < 0) return;
    if (_position > const Duration(seconds: 5)) {
      await seek(Duration.zero);
      return;
    }
    final nextIndex = (_queueIndex - 1 + _queue.length) % _queue.length;
    await playSong(_queue[nextIndex], queue: _queue);
  }

  Future<void> next() async {
    if (_queue.isEmpty || _queueIndex < 0) return;
    var nextIndex = (_queueIndex + 1) % _queue.length;
    if (shuffle && _queue.length > 1) {
      nextIndex = (DateTime.now().microsecondsSinceEpoch % _queue.length);
      if (nextIndex == _queueIndex) nextIndex = (nextIndex + 1) % _queue.length;
    }
    await playSong(_queue[nextIndex], queue: _queue);
  }

  Future<void> cycleRepeatMode() async {
    repeatMode = switch (repeatMode) {
      PlaybackRepeatMode.off => PlaybackRepeatMode.all,
      PlaybackRepeatMode.all => PlaybackRepeatMode.one,
      PlaybackRepeatMode.one => PlaybackRepeatMode.off,
    };
    await _player.setRepeatMode(repeatMode);
    notifyListeners();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  Future<void> toggleFavorite(Song song) async {
    final favorites = <String>{..._snapshot.favoriteSongIds};
    final isRemoving = favorites.remove(song.id);
    if (!isRemoving) favorites.add(song.id);
    _rememberSong(song);
    _snapshot = _snapshot.copyWith(favoriteSongIds: favorites);
    await _addEvent(
      song,
      isRemoving ? ListeningEventType.unfavorite : ListeningEventType.favorite,
    );
  }

  Future<void> dislikeSong(Song song) async {
    await _addEvent(song, ListeningEventType.dislike);
    transientMessage = '已降低“${song.title}”及相似标签的推荐权重。';
    notifyListeners();
  }

  Future<void> importLocalSongs() async {
    isImporting = true;
    transientMessage = null;
    notifyListeners();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (result == null) return;
      final localIds = <String>{..._snapshot.localSongIds};
      var imported = 0;
      for (final file in result.files) {
        final path = file.path;
        if (path == null || path.isEmpty) continue;
        final filename = path.split(RegExp(r'[\\/]')).last;
        final title = filename.replaceFirst(RegExp(r'\.[^.]+$'), '');
        final song = Song(
          id: 'local:${Uri.encodeComponent(path)}',
          title: title,
          artist: '本地音乐',
          localPath: path,
          tags: _tagger.fromMetadata(
            source: MusicSourceKind.local,
            title: title,
            artist: '本地音乐',
          ),
          source: MusicSourceKind.local,
          downloadAllowed: false,
          licenseLabel: '用户设备上的本地文件',
        );
        _rememberSong(song);
        if (localIds.add(song.id)) imported++;
        await _addEvent(song, ListeningEventType.addToLibrary, persist: false);
      }
      _snapshot = _snapshot.copyWith(localSongIds: localIds);
      await _persist();
      transientMessage = imported == 0 ? '没有新增歌曲。' : '已导入 $imported 首本地歌曲。';
    } finally {
      isImporting = false;
      notifyListeners();
    }
  }

  Future<void> downloadSong(Song song) async {
    isDownloading = true;
    downloadProgress = 0;
    transientMessage = null;
    notifyListeners();
    try {
      final resolved = await _musicSource.resolve(song);
      final path = await _downloadService.download(
        resolved,
        onProgress: (value) {
          downloadProgress = value;
          notifyListeners();
        },
      );
      final stored = resolved.copyWith(localPath: path);
      _rememberSong(stored);
      _snapshot = _snapshot.copyWith(
        downloadPaths: <String, String>{
          ..._snapshot.downloadPaths,
          stored.id: path,
        },
      );
      await _addEvent(stored, ListeningEventType.addToLibrary);
      transientMessage = '已保存到 Resonance Music 文件夹。';
    } on DownloadException catch (error) {
      transientMessage = error.message;
    } on CatalogException catch (error) {
      transientMessage = error.message;
    } on Object {
      transientMessage = '下载失败，请检查网络和存储权限后重试。';
    } finally {
      isDownloading = false;
      notifyListeners();
    }
  }

  Future<void> openGequbaoSearch([String? query]) async {
    final term = (query ?? searchQuery).trim();
    if (term.isEmpty) {
      transientMessage = '请先输入歌曲或歌手名称。';
      notifyListeners();
      return;
    }
    final uri = Uri.parse(
      'https://www.gequbao.com/s/${Uri.encodeComponent(term)}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      transientMessage = '无法打开系统浏览器。';
      notifyListeners();
    }
  }

  Future<void> resetPreferences() async {
    _snapshot = _snapshot.copyWith(events: <ListeningEvent>[]);
    await _libraryRepository.save(_snapshot);
    transientMessage = '偏好与行为记录已重置。';
    notifyListeners();
  }

  void _rememberSong(Song song) {
    _snapshot = _snapshot.copyWith(
      knownSongs: <String, Song>{..._snapshot.knownSongs, song.id: song},
    );
  }

  Future<void> _addEvent(
    Song song,
    ListeningEventType type, {
    bool persist = true,
  }) async {
    _rememberSong(song);
    final events = <ListeningEvent>[
      ..._snapshot.events,
      ListeningEvent(songId: song.id, type: type, occurredAt: DateTime.now()),
    ];
    _snapshot = _snapshot.copyWith(
      events: events.length > 1000
          ? events.sublist(events.length - 1000)
          : events,
    );
    if (persist) await _persist();
    notifyListeners();
  }

  Future<void> _recordEarlySkipIfNeeded() async {
    final song = currentSong;
    final duration = _duration;
    if (song == null || duration == null || _completedForCurrent) return;
    final thresholdMs = (duration.inMilliseconds * 0.25).clamp(
      0,
      const Duration(seconds: 30).inMilliseconds,
    );
    if (_position > const Duration(seconds: 3) &&
        _position.inMilliseconds < thresholdMs) {
      await _addEvent(song, ListeningEventType.earlySkip);
    }
  }

  Future<void> _handleCompleted() async {
    final song = currentSong;
    if (song == null || _completedForCurrent) return;
    _completedForCurrent = true;
    await _addEvent(song, ListeningEventType.playCompleted);
    if (repeatMode != PlaybackRepeatMode.one) await next();
  }

  Future<void> _persist() => _libraryRepository.save(_snapshot);

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player.dispose());
    super.dispose();
  }
}
