// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'formation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Formation _$FormationFromJson(Map<String, dynamic> json) => Formation(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FormationToJson(Formation instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'created_at': instance.createdAt.toIso8601String(),
    };
