import 'song.dart';

class SongTagger {
  const SongTagger();

  List<SongTag> fromMetadata({
    required MusicSourceKind source,
    required String title,
    required String artist,
    String? genre,
    DateTime? releaseDate,
    Iterable<String> subjects = const <String>[],
  }) {
    final scores = <String, double>{'source:${source.name}': 1};

    final corpus = <String>[
      title,
      artist,
      genre ?? '',
      ...subjects,
    ].join(' ').toLowerCase();

    _addGenre(scores, genre ?? corpus);
    _addMoodAndScene(scores, corpus);
    _addLanguage(scores, '$title $artist');

    if (releaseDate != null) {
      final decade = (releaseDate.year ~/ 10) * 10;
      scores['decade:$decade'] = 1;
    }

    return scores.entries
        .map((entry) => SongTag(name: entry.key, confidence: entry.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _addGenre(Map<String, double> scores, String value) {
    const aliases = <String, List<String>>{
      'pop': <String>['pop', '流行'],
      'rock': <String>['rock', '摇滚', 'metal', 'punk'],
      'electronic': <String>['electronic', 'dance', 'edm', 'house', 'techno'],
      'classical': <String>['classical', '古典', 'orchestra', 'symphony'],
      'jazz': <String>['jazz', '爵士', 'blues'],
      'hip-hop': <String>['hip-hop', 'hip hop', 'rap', '说唱'],
      'folk': <String>['folk', '民谣', 'country'],
      'soundtrack': <String>['soundtrack', '影视原声', 'anime', 'game'],
      'r&b': <String>['r&b', 'rnb', 'soul'],
    };

    final normalized = value.toLowerCase();
    var matched = false;
    for (final entry in aliases.entries) {
      if (entry.value.any(normalized.contains)) {
        scores['genre:${entry.key}'] = 0.95;
        matched = true;
      }
    }
    if (!matched && normalized.trim().isNotEmpty) {
      scores['genre:other'] = 0.45;
    }
  }

  void _addMoodAndScene(Map<String, double> scores, String corpus) {
    const rules = <String, List<String>>{
      'mood:calm': <String>['calm', 'ambient', 'sleep', 'relax', '轻音乐'],
      'mood:uplifting': <String>['happy', 'dance', 'party', 'upbeat', '快乐'],
      'mood:melancholic': <String>['sad', 'blues', '悲伤', '失恋'],
      'mood:romantic': <String>['love', 'romance', '浪漫', '情歌'],
      'mood:intense': <String>['metal', 'hardcore', 'epic', '激昂'],
      'scene:focus': <String>['focus', 'study', 'classical', 'ambient', '专注'],
      'scene:workout': <String>['workout', 'dance', 'edm', '跑步'],
      'scene:relax': <String>['relax', 'acoustic', 'calm', '放松'],
    };
    for (final entry in rules.entries) {
      if (entry.value.any(corpus.contains)) {
        scores[entry.key] = 0.7;
      }
    }

    if (corpus.contains(RegExp('metal|hardcore|edm|dance|rock'))) {
      scores['energy:high'] = 0.75;
    } else if (corpus.contains(RegExp('ambient|sleep|calm|classical'))) {
      scores['energy:low'] = 0.75;
    } else {
      scores['energy:medium'] = 0.45;
    }
  }

  void _addLanguage(Map<String, double> scores, String value) {
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(value)) {
      scores['language:zh'] = 0.85;
    } else if (RegExp(r'[\u3040-\u30ff]').hasMatch(value)) {
      scores['language:ja'] = 0.85;
    } else if (RegExp(r'[\uac00-\ud7af]').hasMatch(value)) {
      scores['language:ko'] = 0.85;
    } else if (RegExp('[A-Za-z]').hasMatch(value)) {
      scores['language:en'] = 0.55;
    } else {
      scores['language:unknown'] = 0.3;
    }
  }
}
