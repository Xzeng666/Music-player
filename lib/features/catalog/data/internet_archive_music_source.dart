import 'package:dio/dio.dart';

import '../domain/music_source.dart';
import '../domain/song.dart';
import '../domain/song_tagger.dart';

class InternetArchiveMusicSource implements MusicSource {
  InternetArchiveMusicSource({Dio? dio, SongTagger tagger = const SongTagger()})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 15),
            ),
          ),
      _tagger = tagger;

  final Dio _dio;
  final SongTagger _tagger;

  @override
  String get displayName => 'Internet Archive 开放音乐';

  @override
  String get id => 'internet-archive';

  @override
  Future<List<Song>> search(String query, {int limit = 12}) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const <Song>[];

    final escaped = normalized.replaceAll('"', r'\"');
    final q =
        'mediatype:audio AND (title:"$escaped" OR creator:"$escaped") '
        'AND licenseurl:*';
    try {
      final response = await _dio.get<Map<String, Object?>>(
        'https://archive.org/advancedsearch.php',
        queryParameters: <String, Object>{
          'q': q,
          'fl[]': <String>[
            'identifier',
            'title',
            'creator',
            'date',
            'subject',
            'licenseurl',
          ],
          'rows': limit.clamp(1, 20),
          'page': 1,
          'output': 'json',
        },
      );
      final body = response.data?['response'] as Map<String, Object?>?;
      final docs = body?['docs'] as List<Object?>? ?? const <Object?>[];
      return docs
          .whereType<Map<String, Object?>>()
          .map(_fromSearchDocument)
          .toList(growable: false);
    } on DioException catch (error) {
      throw CatalogException('开放音乐来源暂时不可用。', cause: error);
    }
  }

  @override
  Future<Song> resolve(Song song) async {
    if (song.source != MusicSourceKind.internetArchive) return song;
    final identifier = song.id.replaceFirst('archive:', '');
    try {
      final response = await _dio.get<Map<String, Object?>>(
        'https://archive.org/metadata/$identifier',
      );
      final files =
          response.data?['files'] as List<Object?>? ?? const <Object?>[];
      final candidates = files.whereType<Map<String, Object?>>().where((file) {
        final name = (file['name'] as String? ?? '').toLowerCase();
        final format = (file['format'] as String? ?? '').toLowerCase();
        return name.endsWith('.mp3') &&
            !name.contains('_spectrogram') &&
            (format.contains('mp3') || format.isEmpty);
      }).toList();
      if (candidates.isEmpty) {
        throw const CatalogException('此开放音乐条目没有可播放的 MP3 文件。');
      }
      candidates.sort((a, b) {
        final aSize = int.tryParse('${a['size']}') ?? 0;
        final bSize = int.tryParse('${b['size']}') ?? 0;
        return bSize.compareTo(aSize);
      });
      final filename = candidates.first['name']! as String;
      final encoded = filename.split('/').map(Uri.encodeComponent).join('/');
      return song.copyWith(
        audioUrl: 'https://archive.org/download/$identifier/$encoded',
      );
    } on DioException catch (error) {
      throw CatalogException('无法解析开放音乐的播放地址。', cause: error);
    }
  }

  Song _fromSearchDocument(Map<String, Object?> json) {
    final identifier = '${json['identifier']}';
    final title = _stringValue(json['title'], fallback: identifier);
    final artist = _stringValue(json['creator'], fallback: 'Internet Archive');
    final license = _stringValue(json['licenseurl']);
    final releaseDate = DateTime.tryParse(_stringValue(json['date']));
    final subjects = _stringList(json['subject']);
    final downloadAllowed = _isOpenLicense(license);
    return Song(
      id: 'archive:$identifier',
      title: title,
      artist: artist,
      artworkUrl: 'https://archive.org/services/img/$identifier',
      releaseDate: releaseDate,
      tags: _tagger.fromMetadata(
        source: MusicSourceKind.internetArchive,
        title: title,
        artist: artist,
        releaseDate: releaseDate,
        subjects: subjects,
      ),
      source: MusicSourceKind.internetArchive,
      downloadAllowed: downloadAllowed,
      licenseLabel: license.isEmpty ? '授权信息未提供' : license,
    );
  }

  bool _isOpenLicense(String license) {
    final normalized = license.toLowerCase();
    return normalized.contains('creativecommons.org/licenses/by/') ||
        normalized.contains('creativecommons.org/licenses/by-sa/') ||
        normalized.contains('creativecommons.org/publicdomain') ||
        normalized.contains('creativecommons.org/zero');
  }

  String _stringValue(Object? value, {String fallback = ''}) {
    if (value is String) return value;
    if (value is List<Object?> && value.isNotEmpty) return '${value.first}';
    if (value == null) return fallback;
    return '$value';
  }

  List<String> _stringList(Object? value) {
    if (value is List<Object?>) return value.map((item) => '$item').toList();
    if (value is String) return <String>[value];
    return const <String>[];
  }
}
