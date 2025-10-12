import 'package:json_annotation/json_annotation.dart';

part 'match_lineup.g.dart';

@JsonSerializable()
class MatchLineup {
  final String id;
  @JsonKey(name: 'match_id')
  final String matchId;
  @JsonKey(name: 'team_id')
  final String teamId;
  @JsonKey(name: 'formation_id')
  final String? formationId;
  @JsonKey(name: 'is_starting')
  final bool isStarting;
  @JsonKey(name: 'player_id')
  final String playerId;
  @JsonKey(name: 'position_in_formation')
  final String? positionInFormation;

  MatchLineup({
    required this.id,
    required this.matchId,
    required this.teamId,
    this.formationId,
    required this.isStarting,
    required this.playerId,
    this.positionInFormation,
  });

  factory MatchLineup.fromJson(Map<String, dynamic> json) =>
      _$MatchLineupFromJson(json);

  Map<String, dynamic> toJson() => _$MatchLineupToJson(this);
}
