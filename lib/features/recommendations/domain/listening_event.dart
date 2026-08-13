enum ListeningEventType {
  impression,
  searchOpen,
  playStarted,
  playCompleted,
  earlySkip,
  favorite,
  unfavorite,
  addToLibrary,
  dislike,
}

class ListeningEvent {
  const ListeningEvent({
    required this.songId,
    required this.type,
    required this.occurredAt,
  });

  final String songId;
  final ListeningEventType type;
  final DateTime occurredAt;

  double get baseWeight => switch (type) {
    ListeningEventType.impression => 0.05,
    ListeningEventType.searchOpen => 0.35,
    ListeningEventType.playStarted => 0.4,
    ListeningEventType.playCompleted => 1.4,
    ListeningEventType.earlySkip => -1.2,
    ListeningEventType.favorite => 2.5,
    ListeningEventType.unfavorite => -1.5,
    ListeningEventType.addToLibrary => 1.7,
    ListeningEventType.dislike => -3,
  };

  bool get isMeaningful => switch (type) {
    ListeningEventType.impression => false,
    _ => true,
  };

  Map<String, Object> toJson() => <String, Object>{
    'songId': songId,
    'type': type.name,
    'occurredAt': occurredAt.toIso8601String(),
  };

  factory ListeningEvent.fromJson(Map<String, Object?> json) => ListeningEvent(
    songId: json['songId']! as String,
    type: ListeningEventType.values.byName(json['type']! as String),
    occurredAt: DateTime.parse(json['occurredAt']! as String),
  );
}
