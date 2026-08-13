import 'song.dart';

abstract interface class MusicSource {
  String get id;
  String get displayName;

  Future<List<Song>> search(String query, {int limit = 20});

  Future<Song> resolve(Song song) async => song;
}

class CatalogException implements Exception {
  const CatalogException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
