import 'package:dio/dio.dart';

import '../domain/music_source.dart';
import '../domain/song.dart';
import '../domain/song_tagger.dart';

class ItunesMusicSource implements MusicSource {
  ItunesMusicSource({Dio? dio, SongTagger tagger = const SongTagger()})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://itunes.apple.com',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
            ),
          ),
      _tagger = tagger;

  final Dio _dio;
  final SongTagger _tagger;

  @override
  String get displayName => 'iTunes 试听';

  @override
  String get id => 'itunes-preview';

  @override
  Future<Song> resolve(Song song) async => song;

  @override
  Future<List<Song>> search(String query, {int limit = 20}) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const <Song>[];

    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/search',
        queryParameters: <String, Object>{
          'term': normalized,
          'entity': 'song',
          'media': 'music',
          'limit': limit.clamp(1, 50),
          'country': 'CN',
          'lang': 'zh_cn',
          'explicit': 'No',
        },
      );
      final results =
          response.data?['results'] as List<Object?>? ?? const <Object?>[];
      return results
          .whereType<Map<String, Object?>>()
          .map(_fromJson)
          .where((song) => song.isPlayable)
          .toList(growable: false);
    } on DioException catch (error) {
      throw CatalogException('在线搜索暂时不可用，请检查网络后重试。', cause: error);
    } on FormatException catch (error) {
      throw CatalogException('在线来源返回了无法识别的数据。', cause: error);
    }
  }

  Song _fromJson(Map<String, Object?> json) {
    final title = json['trackName'] as String? ?? '未知歌曲';
    final artist = json['artistName'] as String? ?? '未知艺术家';
    final releaseDate = DateTime.tryParse(json['releaseDate'] as String? ?? '');
    final genre = json['primaryGenreName'] as String?;
    final artwork = (json['artworkUrl100'] as String?)?.replaceFirst(
      '100x100bb',
      '600x600bb',
    );

    return Song(
      id: 'itunes:${json['trackId']}',
      title: title,
      artist: artist,
      album: json['collectionName'] as String?,
      artworkUrl: artwork,
      audioUrl: json['previewUrl'] as String?,
      duration: json['trackTimeMillis'] == null
          ? null
          : Duration(milliseconds: json['trackTimeMillis']! as int),
      releaseDate: releaseDate,
      tags: _tagger.fromMetadata(
        source: MusicSourceKind.itunesPreview,
        title: title,
        artist: artist,
        genre: genre,
        releaseDate: releaseDate,
      ),
      source: MusicSourceKind.itunesPreview,
      downloadAllowed: false,
      licenseLabel: 'Apple 提供的 30 秒试听，仅用于流式播放',
    );
  }
}
