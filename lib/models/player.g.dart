// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Player _$PlayerFromJson(Map<String, dynamic> json) => Player(
      id: json['id'] as String,
      teamId: json['team_id'] as String?,
      name: json['name'] as String,
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
      marketValue: (json['marketValue'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PlayerToJson(Player instance) => <String, dynamic>{
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
      'marketValue': instance.marketValue,
    };
