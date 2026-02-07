enum NoteType {
  preMatch,
  liveReaction,
  tactical,
}

extension NoteTypeExtension on NoteType {
  String get value {
    switch (this) {
      case NoteType.preMatch:
        return 'pre_match';
      case NoteType.liveReaction:
        return 'live_reaction';
      case NoteType.tactical:
        return 'tactical';
    }
  }

  static NoteType fromString(String value) {
    switch (value) {
      case 'pre_match':
        return NoteType.preMatch;
      case 'live_reaction':
        return NoteType.liveReaction;
      case 'tactical':
      default:
        return NoteType.tactical;
    }
  }

  String get displayName {
    switch (this) {
      case NoteType.preMatch:
        return 'Pre-Match';
      case NoteType.liveReaction:
        return 'Live Reaction';
      case NoteType.tactical:
        return 'Tactical';
    }
  }
}

class MatchNote {
  final String id;
  final String matchId;
  final String userId;
  final String content;
  final NoteType noteType;
  final double videoTimestamp;
  final DateTime createdAt;
  final String? authorName;
  final String? authorRole;

  MatchNote({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.content,
    required this.noteType,
    required this.videoTimestamp,
    required this.createdAt,
    this.authorName,
    this.authorRole,
  });

  factory MatchNote.fromJson(Map<String, dynamic> json) {
    return MatchNote(
      id: json['id'],
      matchId: json['match_id'],
      userId: json['user_id'],
      content: json['content'],
      noteType: NoteTypeExtension.fromString(json['note_type']),
      videoTimestamp: (json['video_timestamp'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      authorName: json['author_name'],
      authorRole: json['author_role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'content': content,
      'note_type': noteType.value,
      'video_timestamp': videoTimestamp,
    };
  }
}
