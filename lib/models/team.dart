import 'package:flutter/material.dart'; // For Color

class Team {
  final String id;
  final String name;
  final String? userId; // New: Link to user who owns this team
  final String? primaryColor; // Stored as hex string, e.g., '#RRGGBB'
  final String? secondaryColor; // Stored as hex string
  final String? logoUrl;

  Team({
    required this.id,
    required this.name,
    this.userId,
    this.primaryColor,
    this.secondaryColor,
    this.logoUrl,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      userId: json['user_id'],
      primaryColor: json['primary_color'],
      secondaryColor: json['secondary_color'],
      logoUrl: json['logo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'logo_url': logoUrl,
    };
  }

  // Helper to convert hex string to Color object
  Color? get primaryMaterialColor {
    if (primaryColor == null) return null;
    return Color(int.parse(primaryColor!.substring(1, 7), radix: 16) + 0xFF000000);
  }

  Color? get secondaryMaterialColor {
    if (secondaryColor == null) return null;
    return Color(int.parse(secondaryColor!.substring(1, 7), radix: 16) + 0xFF000000);
  }
}