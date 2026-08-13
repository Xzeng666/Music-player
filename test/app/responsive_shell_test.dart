import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance_music/app/app.dart';
import 'package:resonance_music/app/app_controller.dart';
import 'package:resonance_music/features/catalog/domain/music_source.dart';
import 'package:resonance_music/features/catalog/domain/song.dart';
import 'package:resonance_music/features/library/data/download_service.dart';
import 'package:resonance_music/features/library/domain/library_repository.dart';
import 'package:resonance_music/features/playback/domain/player_service.dart';

void main() {
  final cases =
      <
        ({
          Size size,
          double textScale,
          Brightness brightness,
          bool reducedMotion,
        })
      >[
        (
          size: const Size(375, 812),
          textScale: 1,
          brightness: Brightness.light,
          reducedMotion: false,
        ),
        (
          size: const Size(812, 375),
          textScale: 1,
          brightness: Brightness.light,
          reducedMotion: false,
        ),
        (
          size: const Size(768, 1024),
          textScale: 1,
          brightness: Brightness.dark,
          reducedMotion: false,
        ),
        (
          size: const Size(1440, 900),
          textScale: 1,
          brightness: Brightness.light,
          reducedMotion: false,
        ),
        (
          size: const Size(375, 812),
          textScale: 2,
          brightness: Brightness.dark,
          reducedMotion: true,
        ),
      ];
  for (final testCase in cases) {
    testWidgets(
      'renders ${testCase.size.width.toInt()}x${testCase.size.height.toInt()} '
      'at ${testCase.textScale}x text',
      (tester) async {
        tester.view.physicalSize = testCase.size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = testCase.textScale;
        tester.platformDispatcher.platformBrightnessTestValue =
            testCase.brightness;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(
              disableAnimations: testCase.reducedMotion,
              reduceMotion: testCase.reducedMotion,
            );
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );

        final controller = AppController(
          musicSource: _FakeSource(),
          player: _FakePlayer(),
          libraryRepository: _FakeRepository(),
          downloadService: DownloadService(),
        );
        await tester.pumpWidget(ResonanceApp(controller: controller));
        await tester.pumpAndSettle();

        expect(find.text('你的声音，\n由你慢慢定义。'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('搜索').last);
        await tester.pumpAndSettle();
        expect(find.text('搜索音乐'), findsOneWidget);
        expect(tester.takeException(), isNull);

        final searchScrollable = find
            .descendant(
              of: find.byType(CustomScrollView).last,
              matching: find.byType(Scrollable),
            )
            .first;
        for (
          var attempt = 0;
          attempt < 8 && find.text('测试歌曲').evaluate().isEmpty;
          attempt++
        ) {
          await tester.drag(searchScrollable, const Offset(0, -180));
          await tester.pump();
        }
        expect(find.text('测试歌曲'), findsWidgets);
        await tester.tap(find.text('测试歌曲').first);
        await tester.pumpAndSettle();
        expect(find.byTooltip('下一首'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('音乐库').last);
        await tester.pumpAndSettle();
        expect(find.text('我的音乐库'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('偏好').last);
        await tester.pumpAndSettle();
        expect(find.text('偏好与隐私'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _FakeSource implements MusicSource {
  @override
  String get displayName => 'Fake';

  @override
  String get id => 'fake';

  @override
  Future<Song> resolve(Song song) async => song;

  @override
  Future<List<Song>> search(String query, {int limit = 20}) async => <Song>[
    const Song(
      id: 'one',
      title: '测试歌曲',
      artist: '测试歌手',
      source: MusicSourceKind.itunesPreview,
      audioUrl: 'https://example.com/preview.mp3',
      tags: <SongTag>[SongTag(name: 'genre:pop', confidence: 1)],
    ),
  ];
}

class _FakeRepository implements LibraryRepository {
  LibrarySnapshot snapshot = const LibrarySnapshot();

  @override
  Future<void> clearPreferences() async {}

  @override
  Future<LibrarySnapshot> load() async => snapshot;

  @override
  Future<void> save(LibrarySnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}

class _FakePlayer implements PlayerService {
  Song? song;
  bool playing = false;

  @override
  Stream<void> get completedStream => const Stream<void>.empty();

  @override
  Song? get currentSong => song;

  @override
  Stream<Duration?> get durationStream => const Stream<Duration?>.empty();

  @override
  Stream<Object?> get errorStream => const Stream<Object?>.empty();

  @override
  bool get isPlaying => playing;

  @override
  Stream<bool> get playingStream => const Stream<bool>.empty();

  @override
  Duration get position => Duration.zero;

  @override
  Stream<Duration> get positionStream => const Stream<Duration>.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> pause() async {
    playing = false;
  }

  @override
  Future<void> play(Song song) async {
    this.song = song;
    playing = true;
  }

  @override
  Future<void> resume() async {
    playing = true;
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setRepeatMode(PlaybackRepeatMode mode) async {}

  @override
  Future<void> setVolume(double volume) async {}
}
