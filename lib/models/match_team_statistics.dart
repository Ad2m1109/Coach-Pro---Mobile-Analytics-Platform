import 'package:json_annotation/json_annotation.dart';

part 'match_team_statistics.g.dart';

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

@JsonSerializable(explicitToJson: true)
class MatchTeamStatistics {
  final String id;
  @JsonKey(name: 'match_id')
  final String matchId;
  @JsonKey(name: 'team_id')
  final String teamId;
  @JsonKey(name: 'possession_percentage', fromJson: _toDouble)
  final double? possessionPercentage;
  @JsonKey(name: 'total_shots')
  final int? totalShots;
  @JsonKey(name: 'shots_on_target')
  final int? shotsOnTarget;
  @JsonKey(name: 'expected_goals', fromJson: _toDouble)
  final double? expectedGoals;
  final int? pressures;
  @JsonKey(name: 'final_third_passes')
  final int? finalThirdPasses;
  @JsonKey(name: 'high_turnover_zones_data')
  final Map<String, dynamic>? highTurnoverZonesData;
  @JsonKey(name: 'set_piece_xg_breakdown_data')
  final Map<String, dynamic>? setPieceXgBreakdownData;
  @JsonKey(name: 'transition_speed_data')
  final Map<String, dynamic>? transitionSpeedData;
  @JsonKey(name: 'build_up_patterns')
  final Map<String, dynamic>? buildUpPatterns;
  @JsonKey(name: 'defensive_block_patterns')
  final Map<String, dynamic>? defensiveBlockPatterns;

  MatchTeamStatistics({
    required this.id,
    required this.matchId,
    required this.teamId,
    this.possessionPercentage,
    this.totalShots,
    this.shotsOnTarget,
    this.expectedGoals,
    this.pressures,
    this.finalThirdPasses,
    this.highTurnoverZonesData,
    this.setPieceXgBreakdownData,
    this.transitionSpeedData,
    this.buildUpPatterns,
    this.defensiveBlockPatterns,
  });

  factory MatchTeamStatistics.fromJson(Map<String, dynamic> json) =>
      _$MatchTeamStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$MatchTeamStatisticsToJson(this);
}
