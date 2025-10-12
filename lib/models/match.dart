import 'package:flutter/material.dart';

class Match {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String homeTeamId; // Added
  final String awayTeamId; // Added
  final int homeScore;
  final int awayScore;
  final DateTime date;
  final String status; // e.g., "LIVE", "COMPLETED"
  final String? eventId;
  final String? eventName;
  final String? venue;

  Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeTeamId, // Added
    required this.awayTeamId, // Added
    required this.homeScore,
    required this.awayScore,
    required this.date,
    required this.status,
    this.eventId,
    this.eventName,
    this.venue,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      homeTeam: json['home_team_name'] ?? 'N/A',
      awayTeam: json['away_team_name'] ?? 'N/A',
      homeTeamId: json['home_team_id'], // Populated from JSON
      awayTeamId: json['away_team_id'], // Populated from JSON
      homeScore: json['home_score'] ?? 0,
      awayScore: json['away_score'] ?? 0,
      date: DateTime.parse(json['date_time']),
      status: json['status'],
      eventId: json['event_id'],
      eventName: json['event_name'],
      venue: json['venue'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'home_team_name': homeTeam,
        'away_team_name': awayTeam,
        'home_team_id': homeTeamId, // Added to toJson
        'away_team_id': awayTeamId, // Added to toJson
        'home_score': homeScore,
        'away_score': awayScore,
        'date_time': date.toIso8601String(),
        'status': status,
        'event_id': eventId,
        'event_name': eventName,
        'venue': venue,
      };
}
