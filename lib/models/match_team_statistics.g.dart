// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_team_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchTeamStatistics _$MatchTeamStatisticsFromJson(Map<String, dynamic> json) =>
    MatchTeamStatistics(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      teamId: json['team_id'] as String,
      possessionPercentage: _toDouble(json['possession_percentage']),
      totalShots: (json['total_shots'] as num?)?.toInt(),
      shotsOnTarget: (json['shots_on_target'] as num?)?.toInt(),
      expectedGoals: _toDouble(json['expected_goals']),
      pressures: (json['pressures'] as num?)?.toInt(),
      finalThirdPasses: (json['final_third_passes'] as num?)?.toInt(),
      highTurnoverZonesData:
          json['high_turnover_zones_data'] as Map<String, dynamic>?,
      setPieceXgBreakdownData:
          json['set_piece_xg_breakdown_data'] as Map<String, dynamic>?,
      transitionSpeedData:
          json['transition_speed_data'] as Map<String, dynamic>?,
      buildUpPatterns: json['build_up_patterns'] as Map<String, dynamic>?,
      defensiveBlockPatterns:
          json['defensive_block_patterns'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$MatchTeamStatisticsToJson(
        MatchTeamStatistics instance) =>
    <String, dynamic>{
      'id': instance.id,
      'match_id': instance.matchId,
      'team_id': instance.teamId,
      'possession_percentage': instance.possessionPercentage,
      'total_shots': instance.totalShots,
      'shots_on_target': instance.shotsOnTarget,
      'expected_goals': instance.expectedGoals,
      'pressures': instance.pressures,
      'final_third_passes': instance.finalThirdPasses,
      'high_turnover_zones_data': instance.highTurnoverZonesData,
      'set_piece_xg_breakdown_data': instance.setPieceXgBreakdownData,
      'transition_speed_data': instance.transitionSpeedData,
      'build_up_patterns': instance.buildUpPatterns,
      'defensive_block_patterns': instance.defensiveBlockPatterns,
    };
