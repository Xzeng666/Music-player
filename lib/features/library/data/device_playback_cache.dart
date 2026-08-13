import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../catalog/domain/song.dart';
import '../domain/playback_cache.dart';

typedef CacheDirectoryProvider = Future<Directory> Function();

class DevicePlaybackCache implements PlaybackCache {
  DevicePlaybackCache({Dio? dio, CacheDirectoryProvider? directoryProvider})
    : _dio = dio ?? Dio(),
      _directoryProvider = directoryProvider ?? _defaultDirectory;

  final Dio _dio;
  final CacheDirectoryProvider _directoryProvider;

  @override
  Future<Song> prepare(
    Song song, {
    required int maxEntries,
    PlaybackCacheProgress? onProgress,
  }) async {
    if (maxEntries <= 0 ||
        song.localPath != null ||
        !song.downloadAllowed ||
        song.audioUrl == null ||
        song.audioUrl!.isEmpty) {
      return song;
    }

    final directory = await _ensureDirectory();
    final key = sha256.convert(utf8.encode(song.id)).toString();
    final destination = File(
      '${directory.path}${Platform.pathSeparator}$key.mp3',
    );
    if (await destination.exists() && await destination.length() > 0) {
      await destination.setLastModified(DateTime.now());
      await enforceLimit(maxEntries);
      return song.copyWith(localPath: destination.path);
    }

    final temporary = File('${destination.path}.part');
    try {
      if (await temporary.exists()) await temporary.delete();
      await _dio.download(
        song.audioUrl!,
        temporary.path,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      if (await destination.exists()) await destination.delete();
      await temporary.rename(destination.path);
      await destination.setLastModified(DateTime.now());
      await enforceLimit(maxEntries);
      return song.copyWith(localPath: destination.path);
    } on Object catch (error) {
      if (await temporary.exists()) await temporary.delete();
      throw PlaybackCacheException('音频缓存失败，已回退为在线播放。', cause: error);
    }
  }

  @override
  Future<int> count() async => (await _cacheFiles()).length;

  @override
  Future<int> enforceLimit(int maxEntries) async {
    final files = await _cacheFiles();
    files.sort((a, b) {
      return a.lastModifiedSync().compareTo(b.lastModifiedSync());
    });
    final keep = maxEntries.clamp(0, 50).toInt();
    final removeCount = (files.length - keep).clamp(0, files.length).toInt();
    for (final file in files.take(removeCount)) {
      await file.delete();
    }
    return files.length - removeCount;
  }

  @override
  Future<void> clear() async {
    for (final file in await _cacheFiles()) {
      await file.delete();
    }
    final directory = await _directoryProvider();
    if (await directory.exists()) {
      for (final entity in directory.listSync()) {
        if (entity is File && entity.path.endsWith('.part')) {
          await entity.delete();
        }
      }
    }
  }

  Future<Directory> _ensureDirectory() async {
    final directory = await _directoryProvider();
    await directory.create(recursive: true);
    return directory;
  }

  Future<List<File>> _cacheFiles() async {
    final directory = await _directoryProvider();
    if (!await directory.exists()) return <File>[];
    return directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.mp3'))
        .toList();
  }

  static Future<Directory> _defaultDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(
      '${support.path}${Platform.pathSeparator}Resonance Music'
      '${Platform.pathSeparator}playback-cache',
    );
  }
}
