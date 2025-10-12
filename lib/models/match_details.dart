import 'package:json_annotation/json_annotation.dart';
import './match.dart';
import './match_lineup.dart';
import './player_match_statistics.dart';
import './match_team_statistics.dart';
import './match_event.dart';
import './formation.dart';
import './player.dart';

part 'match_details.g.dart';

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

@JsonSerializable(explicitToJson: true)
class PlayerWithPosition extends Player {
  @JsonKey(name: 'position_in_formation')
  final String? positionInFormation;

  PlayerWithPosition({
    required super.id,
    required super.name,
    super.teamId,
    super.position,
    super.jerseyNumber,
    super.birthDate,
    super.dominantFoot,
    super.heightCm,
    super.weightKg,
    super.nationality,
    super.countryCode,
    super.imageUrl,
    super.marketValue,
    this.positionInFormation,
  });

  factory PlayerWithPosition.fromJson(Map<String, dynamic> json) =>
      _$PlayerWithPositionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PlayerWithPositionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TeamLineup {
  @JsonKey(name: 'team_id')
  final String teamId;
  @JsonKey(name: 'team_name')
  final String teamName;
  final Formation? formation;
  final List<PlayerWithPosition> players;

  TeamLineup({
    required this.teamId,
    required this.teamName,
    this.formation,
    required this.players,
  });

  factory TeamLineup.fromJson(Map<String, dynamic> json) =>
      _$TeamLineupFromJson(json);

  Map<String, dynamic> toJson() => _$TeamLineupToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MatchDetails {
  @JsonKey(name: 'match_info')
  final Match matchInfo;
  @JsonKey(name: 'home_lineup')
  final TeamLineup homeLineup;
  @JsonKey(name: 'away_lineup')
  final TeamLineup awayLineup;
  final List<MatchEvent> events;
  @JsonKey(name: 'player_stats')
  final List<PlayerMatchStatistics> playerStats;
  @JsonKey(name: 'team_stats')
  final List<MatchTeamStatistics> teamStats;

  MatchDetails({
    required this.matchInfo,
    required this.homeLineup,
    required this.awayLineup,
    required this.events,
    required this.playerStats,
    required this.teamStats,
  });

  factory MatchDetails.fromJson(Map<String, dynamic> json) =>
      _$MatchDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$MatchDetailsToJson(this);
}