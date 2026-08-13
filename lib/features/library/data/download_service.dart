import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../catalog/domain/song.dart';

typedef DownloadProgress = void Function(double progress);

class DownloadService {
  DownloadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<String> download(Song song, {DownloadProgress? onProgress}) async {
    if (!song.downloadAllowed) {
      throw const DownloadException('此来源只允许在线播放，不能永久下载。');
    }
    if (song.audioUrl == null || song.audioUrl!.isEmpty) {
      throw const DownloadException('歌曲还没有可下载的媒体地址。');
    }

    final baseDirectory = await getApplicationDocumentsDirectory();
    final musicDirectory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}Resonance Music',
    );
    await musicDirectory.create(recursive: true);
    final safeName = _safeFilename('${song.artist} - ${song.title}');
    final destination =
        '${musicDirectory.path}${Platform.pathSeparator}$safeName.mp3';

    try {
      await _dio.download(
        song.audioUrl!,
        destination,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      return destination;
    } on DioException catch (error) {
      throw DownloadException('下载失败，请稍后重试。', cause: error);
    }
  }

  String _safeFilename(String value) {
    final safe = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (safe.isEmpty) return 'track';
    return safe.length <= 80 ? safe : safe.substring(0, 80);
  }
}

class DownloadException implements Exception {
  const DownloadException(this.message, {this.cause});

  final String message;
  final Object? cause;
}
