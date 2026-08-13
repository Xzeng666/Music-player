import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:resonance_music/features/catalog/domain/song.dart';
import 'package:resonance_music/features/library/data/device_playback_cache.dart';

void main() {
  late Directory directory;
  late HttpServer server;
  var requestCount = 0;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('resonance-cache-test-');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requestCount++;
      request.response.headers.contentType = ContentType('audio', 'mpeg');
      request.response.add(List<int>.generate(64, (index) => index));
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    if (await directory.exists()) await directory.delete(recursive: true);
    requestCount = 0;
  });

  test('同一授权歌曲重复播放命中缓存', () async {
    final cache = DevicePlaybackCache(directoryProvider: () async => directory);
    final song = _licensedSong(server, 'one');

    final first = await cache.prepare(song, maxEntries: 10);
    final second = await cache.prepare(song, maxEntries: 10);

    expect(first.localPath, isNotNull);
    expect(second.localPath, first.localPath);
    expect(requestCount, 1);
    expect(await cache.count(), 1);
  });

  test('按最近使用顺序裁剪到设置上限', () async {
    final cache = DevicePlaybackCache(directoryProvider: () async => directory);
    await cache.prepare(_licensedSong(server, 'one'), maxEntries: 5);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final newest = await cache.prepare(
      _licensedSong(server, 'two'),
      maxEntries: 1,
    );

    expect(await cache.count(), 1);
    expect(await File(newest.localPath!).exists(), isTrue);
  });

  test('许可不明的音频不写入缓存', () async {
    final cache = DevicePlaybackCache(directoryProvider: () async => directory);
    final source = _licensedSong(server, 'blocked');
    final blocked = Song(
      id: source.id,
      title: source.title,
      artist: source.artist,
      source: source.source,
      audioUrl: source.audioUrl,
    );

    final result = await cache.prepare(blocked, maxEntries: 10);

    expect(result.localPath, isNull);
    expect(requestCount, 0);
    expect(await cache.count(), 0);
  });
}

Song _licensedSong(HttpServer server, String id) => Song(
  id: id,
  title: id,
  artist: 'artist',
  source: MusicSourceKind.internetArchive,
  audioUrl: 'http://${server.address.host}:${server.port}/$id.mp3',
  downloadAllowed: true,
);
