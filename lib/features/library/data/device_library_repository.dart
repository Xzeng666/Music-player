import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../catalog/domain/song.dart';
import '../../recommendations/domain/listening_event.dart';
import '../domain/library_repository.dart';

class DeviceLibraryRepository implements LibraryRepository {
  DeviceLibraryRepository({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  static const _snapshotKey = 'resonance.library.v1';
  final Future<SharedPreferences> _preferences;

  @override
  Future<LibrarySnapshot> load() async {
    final preferences = await _preferences;
    final encoded = preferences.getString(_snapshotKey);
    if (encoded == null || encoded.isEmpty) return const LibrarySnapshot();

    try {
      final json = jsonDecode(encoded) as Map<String, Object?>;
      final songs = (json['songs'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map(Song.fromJson);
      return LibrarySnapshot(
        knownSongs: <String, Song>{for (final song in songs) song.id: song},
        localSongIds:
            (json['localSongIds'] as List<Object?>? ?? const <Object?>[])
                .map((value) => '$value')
                .toSet(),
        favoriteSongIds:
            (json['favoriteSongIds'] as List<Object?>? ?? const <Object?>[])
                .map((value) => '$value')
                .toSet(),
        events: (json['events'] as List<Object?>? ?? const <Object?>[])
            .whereType<Map<String, Object?>>()
            .map(ListeningEvent.fromJson)
            .toList(),
        downloadPaths:
            (json['downloadPaths'] as Map<String, Object?>? ??
                    const <String, Object?>{})
                .map((key, value) => MapEntry(key, '$value')),
      );
    } on Object {
      return const LibrarySnapshot();
    }
  }

  @override
  Future<void> save(LibrarySnapshot snapshot) async {
    final preferences = await _preferences;
    final json = <String, Object>{
      'songs': snapshot.knownSongs.values.map((song) => song.toJson()).toList(),
      'localSongIds': snapshot.localSongIds.toList(),
      'favoriteSongIds': snapshot.favoriteSongIds.toList(),
      'events': snapshot.events.map((event) => event.toJson()).toList(),
      'downloadPaths': snapshot.downloadPaths,
    };
    await preferences.setString(_snapshotKey, jsonEncode(json));
  }

  @override
  Future<void> clearPreferences() async {
    final current = await load();
    await save(current.copyWith(events: <ListeningEvent>[]));
  }
}
