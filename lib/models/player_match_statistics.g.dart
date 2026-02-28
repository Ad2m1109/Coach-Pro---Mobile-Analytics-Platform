// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_match_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayerMatchStatistics _$PlayerMatchStatisticsFromJson(
  Map<String, dynamic> json,
) => PlayerMatchStatistics(
  id: json['id'] as String,
  matchId: json['match_id'] as String,
  playerId: json['player_id'] as String,
  minutesPlayed: (json['minutes_played'] as num?)?.toInt(),
  shots: (json['shots'] as num?)?.toInt(),
  shotsOnTarget: (json['shots_on_target'] as num?)?.toInt(),
  passes: (json['passes'] as num?)?.toInt(),
  accuratePasses: (json['accurate_passes'] as num?)?.toInt(),
  tackles: (json['tackles'] as num?)?.toInt(),
  interceptions: (json['interceptions'] as num?)?.toInt(),
  clearances: (json['clearances'] as num?)?.toInt(),
  saves: (json['saves'] as num?)?.toInt(),
  foulsCommitted: (json['fouls_committed'] as num?)?.toInt(),
  foulsSuffered: (json['fouls_suffered'] as num?)?.toInt(),
  offsides: (json['offsides'] as num?)?.toInt(),
  distanceCoveredKm: _toDouble(json['distance_covered_km']),
  playerXg: _toDouble(json['player_xg']),
  keyPasses: (json['key_passes'] as num?)?.toInt(),
  progressiveCarries: (json['progressive_carries'] as num?)?.toInt(),
  pressResistanceSuccessRate: _toDouble(json['press_resistance_success_rate']),
  defensiveCoverageKm: _toDouble(json['defensive_coverage_km']),
  notes: json['notes'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  sprintCount: (json['sprint_count'] as num?)?.toInt(),
  sprintDistanceM: _toDouble(json['sprint_distance_m']),
  avgSpeedKmh: _toDouble(json['avg_speed_kmh']),
  maxSpeedKmh: _toDouble(json['max_speed_kmh']),
);

Map<String, dynamic> _$PlayerMatchStatisticsToJson(
  PlayerMatchStatistics instance,
) => <String, dynamic>{
  'id': instance.id,
  'match_id': instance.matchId,
  'player_id': instance.playerId,
  'minutes_played': instance.minutesPlayed,
  'shots': instance.shots,
  'shots_on_target': instance.shotsOnTarget,
  'passes': instance.passes,
  'accurate_passes': instance.accuratePasses,
  'tackles': instance.tackles,
  'interceptions': instance.interceptions,
  'clearances': instance.clearances,
  'saves': instance.saves,
  'fouls_committed': instance.foulsCommitted,
  'fouls_suffered': instance.foulsSuffered,
  'offsides': instance.offsides,
  'distance_covered_km': instance.distanceCoveredKm,
  'player_xg': instance.playerXg,
  'key_passes': instance.keyPasses,
  'progressive_carries': instance.progressiveCarries,
  'press_resistance_success_rate': instance.pressResistanceSuccessRate,
  'defensive_coverage_km': instance.defensiveCoverageKm,
  'sprint_count': instance.sprintCount,
  'sprint_distance_m': instance.sprintDistanceM,
  'avg_speed_kmh': instance.avgSpeedKmh,
  'max_speed_kmh': instance.maxSpeedKmh,
  'notes': instance.notes,
  'rating': instance.rating,
};
