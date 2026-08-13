import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_controller.dart';
import 'features/catalog/data/composite_music_source.dart';
import 'features/catalog/data/internet_archive_music_source.dart';
import 'features/catalog/data/itunes_music_source.dart';
import 'features/catalog/domain/music_source.dart';
import 'features/library/data/device_library_repository.dart';
import 'features/library/data/download_service.dart';
import 'features/playback/data/audioplayers_player_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(
    musicSource: CompositeMusicSource(<MusicSource>[
      ItunesMusicSource(),
      InternetArchiveMusicSource(),
    ]),
    player: AudioplayersPlayerService(),
    libraryRepository: DeviceLibraryRepository(),
    downloadService: DownloadService(),
  );
  runApp(ResonanceApp(controller: controller));
}
