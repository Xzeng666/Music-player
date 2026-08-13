import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../domain/music_source.dart';
import '../domain/song.dart';
import '../domain/song_tagger.dart';

class GequhaiMusicSource implements MusicSource {
  GequhaiMusicSource({Dio? dio, SongTagger tagger = const SongTagger()})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://www.gequhai.com',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 15),
              headers: const <String, String>{
                'Accept': 'text/html,application/xhtml+xml',
                'User-Agent':
                    'Mozilla/5.0 (compatible; ResonanceMusic/1.0; +https://github.com/Xzeng666/Music-player)',
              },
            ),
          ),
      _tagger = tagger;

  final Dio _dio;
  final SongTagger _tagger;

  @override
  String get displayName => '歌曲海网页搜索';

  @override
  String get id => 'gequhai-web';

  @override
  Future<Song> resolve(Song song) async => song;

  @override
  Future<List<Song>> search(String query, {int limit = 50}) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const <Song>[];

    try {
      final response = await _dio.get<String>(
        '/s/${Uri.encodeComponent(normalized)}',
        options: Options(responseType: ResponseType.plain),
      );
      return parseSearchHtml(response.data ?? '', limit: limit);
    } on DioException catch (error) {
      throw CatalogException('歌曲海网页搜索暂时不可用。', cause: error);
    } on FormatException catch (error) {
      throw CatalogException('歌曲海的搜索页结构已变更。', cause: error);
    }
  }

  List<Song> parseSearchHtml(String source, {int limit = 50}) {
    final document = html_parser.parse(source);
    final rows = document.querySelectorAll('#myTables tbody tr');
    final songs = <Song>[];
    final seenPaths = <String>{};
    for (final row in rows) {
      final anchor = row.querySelector('a[href^="/play/"]');
      if (anchor == null) continue;
      final path = anchor.attributes['href']?.trim() ?? '';
      final title = _normalizedText(anchor.text);
      final cells = row.querySelectorAll('td');
      final artist = cells.length >= 3 ? _normalizedText(cells[2].text) : '';
      if (path.isEmpty || title.isEmpty || !seenPaths.add(path)) continue;
      final pageUri = Uri.parse('https://www.gequhai.com').resolve(path);
      final playId = path.split('/').where((part) => part.isNotEmpty).last;
      final resolvedArtist = artist.isEmpty ? '未知歌手' : artist;
      songs.add(
        Song(
          id: 'gequhai:$playId',
          title: title,
          artist: resolvedArtist,
          externalPageUrl: pageUri.toString(),
          tags: _tagger.fromMetadata(
            source: MusicSourceKind.gequhaiWeb,
            title: title,
            artist: resolvedArtist,
          ),
          source: MusicSourceKind.gequhaiWeb,
          licenseLabel: '第三方网页索引；媒体与歌词许可未验证',
        ),
      );
      if (songs.length >= limit) break;
    }
    return List<Song>.unmodifiable(songs);
  }

  String _normalizedText(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
