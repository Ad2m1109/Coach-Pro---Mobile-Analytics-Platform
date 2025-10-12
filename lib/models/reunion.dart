import 'package:flutter/material.dart';

class Reunion {
  final String id;
  final String title;
  final DateTime date;
  final String location;
  final String iconName;

  Reunion({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.iconName,
  });

  factory Reunion.fromJson(Map<String, dynamic> json) {
    return Reunion(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      location: json['location'],
      iconName: json['icon_name'],
    );
  }

  IconData get icon {
    switch (iconName) {
      case 'group_work':
        return Icons.group_work;
      case 'analytics':
        return Icons.analytics;
      case 'restaurant':
        return Icons.restaurant;
      case 'family_restroom':
        return Icons.family_restroom;
      default:
        return Icons.event;
    }
  }
}
