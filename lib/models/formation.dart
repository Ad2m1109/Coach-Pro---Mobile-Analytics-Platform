import 'package:json_annotation/json_annotation.dart';

part 'formation.g.dart';

@JsonSerializable()
class Formation {
  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Formation({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory Formation.fromJson(Map<String, dynamic> json) =>
      _$FormationFromJson(json);

  Map<String, dynamic> toJson() => _$FormationToJson(this);
}
