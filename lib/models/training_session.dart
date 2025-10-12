import 'package:flutter/material.dart';

class TrainingSession {
  final String id;
  final String title;
  final DateTime date;
  final String focus;
  final String iconName;

  TrainingSession({
    required this.id,
    required this.title,
    required this.date,
    required this.focus,
    required this.iconName,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      focus: json['focus'],
      iconName: json['icon_name'],
    );
  }

  IconData get icon {
    switch (iconName) {
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'shield':
        return Icons.shield;
      case 'flag':
        return Icons.flag;
      case 'fitness_center':
        return Icons.fitness_center;
      default:
        return Icons.run_circle;
    }
  }
}
