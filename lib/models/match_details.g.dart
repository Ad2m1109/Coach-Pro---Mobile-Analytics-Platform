// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayerWithPosition _$PlayerWithPositionFromJson(Map<String, dynamic> json) =>
    PlayerWithPosition(
      id: json['id'] as String,
      name: json['name'] as String,
      teamId: json['team_id'] as String?,
      position: json['position'] as String?,
      jerseyNumber: (json['jersey_number'] as num?)?.toInt(),
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String),
      dominantFoot: json['dominant_foot'] as String?,
      heightCm: (json['height_cm'] as num?)?.toInt(),
      weightKg: (json['weight_kg'] as num?)?.toInt(),
      nationality: json['nationality'] as String?,
      countryCode: json['country_code'] as String?,
      imageUrl: json['image_url'] as String?,
      marketValue: toDouble(json['market_value']),
      positionInFormation: json['position_in_formation'] as String?,
    );

Map<String, dynamic> _$PlayerWithPositionToJson(PlayerWithPosition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'team_id': instance.teamId,
      'name': instance.name,
      'position': instance.position,
      'jersey_number': instance.jerseyNumber,
      'birth_date': instance.birthDate?.toIso8601String(),
      'dominant_foot': instance.dominantFoot,
      'height_cm': instance.heightCm,
      'weight_kg': instance.weightKg,
      'nationality': instance.nationality,
      'country_code': instance.countryCode,
      'image_url': instance.imageUrl,
      'market_value': instance.marketValue,
      'position_in_formation': instance.positionInFormation,
    };

TeamLineup _$TeamLineupFromJson(Map<String, dynamic> json) => TeamLineup(
  teamId: json['team_id'] as String,
  teamName: json['team_name'] as String,
  formation: json['formation'] == null
      ? null
      : Formation.fromJson(json['formation'] as Map<String, dynamic>),
  players: (json['players'] as List<dynamic>)
      .map((e) => PlayerWithPosition.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TeamLineupToJson(TeamLineup instance) =>
    <String, dynamic>{
      'team_id': instance.teamId,
      'team_name': instance.teamName,
      'formation': instance.formation?.toJson(),
      'players': instance.players.map((e) => e.toJson()).toList(),
    };

MatchDetails _$MatchDetailsFromJson(Map<String, dynamic> json) => MatchDetails(
  matchInfo: Match.fromJson(json['match_info'] as Map<String, dynamic>),
  homeLineup: TeamLineup.fromJson(json['home_lineup'] as Map<String, dynamic>),
  awayLineup: TeamLineup.fromJson(json['away_lineup'] as Map<String, dynamic>),
  events: (json['events'] as List<dynamic>)
      .map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
      .toList(),
  playerStats: (json['player_stats'] as List<dynamic>)
      .map((e) => PlayerMatchStatistics.fromJson(e as Map<String, dynamic>))
      .toList(),
  teamStats: (json['team_stats'] as List<dynamic>)
      .map((e) => MatchTeamStatistics.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MatchDetailsToJson(MatchDetails instance) =>
    <String, dynamic>{
      'match_info': instance.matchInfo.toJson(),
      'home_lineup': instance.homeLineup.toJson(),
      'away_lineup': instance.awayLineup.toJson(),
      'events': instance.events.map((e) => e.toJson()).toList(),
      'player_stats': instance.playerStats.map((e) => e.toJson()).toList(),
      'team_stats': instance.teamStats.map((e) => e.toJson()).toList(),
    };
