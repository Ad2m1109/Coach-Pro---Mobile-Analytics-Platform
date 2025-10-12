import 'package:json_annotation/json_annotation.dart';

part 'match_event.g.dart';

@JsonSerializable()
class MatchEvent {
  final String id;
  @JsonKey(name: 'match_id')
  final String? matchId;
  @JsonKey(name: 'player_id')
  final String? playerId;
  @JsonKey(name: 'event_type')
  final String eventType;
  final int minute;
  @JsonKey(name: 'video_timestamp')
  final double? videoTimestamp;
  final String? coordinates;

  MatchEvent({
    required this.id,
    this.matchId,
    this.playerId,
    required this.eventType,
    required this.minute,
    this.videoTimestamp,
    this.coordinates,
  });

  factory MatchEvent.fromJson(Map<String, dynamic> json) =>
      _$MatchEventFromJson(json);

  Map<String, dynamic> toJson() => _$MatchEventToJson(this);
}
