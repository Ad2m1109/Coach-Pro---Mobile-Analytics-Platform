// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_lineup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchLineup _$MatchLineupFromJson(Map<String, dynamic> json) => MatchLineup(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      teamId: json['team_id'] as String,
      formationId: json['formation_id'] as String?,
      isStarting: json['is_starting'] as bool,
      playerId: json['player_id'] as String,
      positionInFormation: json['position_in_formation'] as String?,
    );

Map<String, dynamic> _$MatchLineupToJson(MatchLineup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'match_id': instance.matchId,
      'team_id': instance.teamId,
      'formation_id': instance.formationId,
      'is_starting': instance.isStarting,
      'player_id': instance.playerId,
      'position_in_formation': instance.positionInFormation,
    };
