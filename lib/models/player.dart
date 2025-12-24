import 'package:json_annotation/json_annotation.dart';

part 'player.g.dart';

double? toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

@JsonSerializable()
class Player {
  final String id;
  @JsonKey(name: 'team_id')
  final String? teamId;
  final String name;
  final String? position;
  @JsonKey(name: 'jersey_number')
  final int? jerseyNumber;
  @JsonKey(name: 'birth_date')
  final DateTime? birthDate;
  @JsonKey(name: 'dominant_foot')
  final String? dominantFoot;
  @JsonKey(name: 'height_cm')
  final int? heightCm;
  @JsonKey(name: 'weight_kg')
  final int? weightKg;
  final String? nationality;
  @JsonKey(name: 'country_code')
  final String? countryCode;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'market_value', fromJson: toDouble)
  final double? marketValue;

  Player({
    required this.id,
    this.teamId,
    required this.name,
    this.position,
    this.jerseyNumber,
    this.birthDate,
    this.dominantFoot,
    this.heightCm,
    this.weightKg,
    this.nationality,
    this.countryCode,
    this.imageUrl,
    this.marketValue,
  });

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerToJson(this);
}
