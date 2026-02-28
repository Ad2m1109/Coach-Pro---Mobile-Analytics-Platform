import 'package:json_annotation/json_annotation.dart';

part 'player_match_statistics.g.dart';

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

@JsonSerializable()
class PlayerMatchStatistics {
  final String id;
  @JsonKey(name: 'match_id')
  final String matchId;
  @JsonKey(name: 'player_id')
  final String playerId;
  @JsonKey(name: 'minutes_played')
  final int? minutesPlayed;
  final int? shots;
  @JsonKey(name: 'shots_on_target')
  final int? shotsOnTarget;
  final int? passes;
  @JsonKey(name: 'accurate_passes')
  final int? accuratePasses;
  final int? tackles;
  @JsonKey(name: 'interceptions')
  final int? interceptions;
  @JsonKey(name: 'clearances')
  final int? clearances;
  @JsonKey(name: 'saves')
  final int? saves;
  @JsonKey(name: 'fouls_committed')
  final int? foulsCommitted;
  @JsonKey(name: 'fouls_suffered')
  final int? foulsSuffered;
  final int? offsides;
  @JsonKey(name: 'distance_covered_km', fromJson: _toDouble)
  final double? distanceCoveredKm;
  @JsonKey(name: 'player_xg', fromJson: _toDouble)
  final double? playerXg;
  @JsonKey(name: 'key_passes')
  final int? keyPasses;
  @JsonKey(name: 'progressive_carries')
  final int? progressiveCarries;
  @JsonKey(name: 'press_resistance_success_rate', fromJson: _toDouble)
  final double? pressResistanceSuccessRate;
  @JsonKey(name: 'defensive_coverage_km', fromJson: _toDouble)
  final double? defensiveCoverageKm;
  @JsonKey(name: 'sprint_count')
  final int? sprintCount;
  @JsonKey(name: 'sprint_distance_m', fromJson: _toDouble)
  final double? sprintDistanceM;
  @JsonKey(name: 'avg_speed_kmh', fromJson: _toDouble)
  final double? avgSpeedKmh;
  @JsonKey(name: 'max_speed_kmh', fromJson: _toDouble)
  final double? maxSpeedKmh;
  final String? notes;
  final double? rating;

  PlayerMatchStatistics({
    required this.id,
    required this.matchId,
    required this.playerId,
    this.minutesPlayed,
    this.shots,
    this.shotsOnTarget,
    this.passes,
    this.accuratePasses,
    this.tackles,
    this.interceptions,
    this.clearances,
    this.saves,
    this.foulsCommitted,
    this.foulsSuffered,
    this.offsides,
    this.distanceCoveredKm,
    this.playerXg,
    this.keyPasses,
    this.progressiveCarries,
    this.pressResistanceSuccessRate,
    this.defensiveCoverageKm,
    this.sprintCount,
    this.sprintDistanceM,
    this.avgSpeedKmh,
    this.maxSpeedKmh,
    this.notes,
    this.rating,
  });

  factory PlayerMatchStatistics.fromJson(Map<String, dynamic> json) =>
      _$PlayerMatchStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerMatchStatisticsToJson(this);
}

