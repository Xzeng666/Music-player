enum MusicSourceKind { local, gequhaiWeb, itunesPreview, internetArchive }

class SongTag {
  const SongTag({required this.name, required this.confidence});

  final String name;
  final double confidence;

  Map<String, Object> toJson() => <String, Object>{
    'name': name,
    'confidence': confidence,
  };

  factory SongTag.fromJson(Map<String, Object?> json) => SongTag(
    name: json['name']! as String,
    confidence: (json['confidence']! as num).toDouble(),
  );
}

class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.source,
    this.album,
    this.artworkUrl,
    this.audioUrl,
    this.externalPageUrl,
    this.localPath,
    this.duration,
    this.releaseDate,
    this.tags = const <SongTag>[],
    this.downloadAllowed = false,
    this.licenseLabel,
  });

  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? artworkUrl;
  final String? audioUrl;
  final String? externalPageUrl;
  final String? localPath;
  final Duration? duration;
  final DateTime? releaseDate;
  final List<SongTag> tags;
  final MusicSourceKind source;
  final bool downloadAllowed;
  final String? licenseLabel;

  String get playableUri => localPath ?? audioUrl ?? '';
  bool get isPlayable => playableUri.isNotEmpty;

  Song copyWith({
    String? artworkUrl,
    String? audioUrl,
    String? externalPageUrl,
    String? localPath,
    Duration? duration,
    List<SongTag>? tags,
    bool? downloadAllowed,
    String? licenseLabel,
  }) => Song(
    id: id,
    title: title,
    artist: artist,
    album: album,
    artworkUrl: artworkUrl ?? this.artworkUrl,
    audioUrl: audioUrl ?? this.audioUrl,
    externalPageUrl: externalPageUrl ?? this.externalPageUrl,
    localPath: localPath ?? this.localPath,
    duration: duration ?? this.duration,
    releaseDate: releaseDate,
    tags: tags ?? this.tags,
    source: source,
    downloadAllowed: downloadAllowed ?? this.downloadAllowed,
    licenseLabel: licenseLabel ?? this.licenseLabel,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'artworkUrl': artworkUrl,
    'audioUrl': audioUrl,
    'externalPageUrl': externalPageUrl,
    'localPath': localPath,
    'durationMs': duration?.inMilliseconds,
    'releaseDate': releaseDate?.toIso8601String(),
    'tags': tags.map((tag) => tag.toJson()).toList(),
    'source': source.name,
    'downloadAllowed': downloadAllowed,
    'licenseLabel': licenseLabel,
  };

  factory Song.fromJson(Map<String, Object?> json) => Song(
    id: json['id']! as String,
    title: json['title']! as String,
    artist: json['artist']! as String,
    album: json['album'] as String?,
    artworkUrl: json['artworkUrl'] as String?,
    audioUrl: json['audioUrl'] as String?,
    externalPageUrl: json['externalPageUrl'] as String?,
    localPath: json['localPath'] as String?,
    duration: json['durationMs'] == null
        ? null
        : Duration(milliseconds: json['durationMs']! as int),
    releaseDate: json['releaseDate'] == null
        ? null
        : DateTime.parse(json['releaseDate']! as String),
    tags: (json['tags']! as List<Object?>)
        .map((value) => SongTag.fromJson(value! as Map<String, Object?>))
        .toList(),
    source: MusicSourceKind.values.byName(json['source']! as String),
    downloadAllowed: json['downloadAllowed']! as bool,
    licenseLabel: json['licenseLabel'] as String?,
  );
}
