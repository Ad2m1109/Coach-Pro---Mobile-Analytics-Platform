// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchEvent _$MatchEventFromJson(Map<String, dynamic> json) => MatchEvent(
      id: json['id'] as String,
      matchId: json['match_id'] as String?,
      playerId: json['player_id'] as String?,
      eventType: json['event_type'] as String,
      minute: (json['minute'] as num).toInt(),
      videoTimestamp: (json['video_timestamp'] as num?)?.toDouble(),
      coordinates: json['coordinates'] as String?,
    );

Map<String, dynamic> _$MatchEventToJson(MatchEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'match_id': instance.matchId,
      'player_id': instance.playerId,
      'event_type': instance.eventType,
      'minute': instance.minute,
      'video_timestamp': instance.videoTimestamp,
      'coordinates': instance.coordinates,
    };
