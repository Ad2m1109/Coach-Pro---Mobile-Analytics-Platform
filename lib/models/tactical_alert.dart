import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tactical_alert.g.dart';

@JsonSerializable()
class TacticalPlayerSnapshot {
  final int id;
  final double x;
  final double y;
  final String team;

  TacticalPlayerSnapshot({
    required this.id,
    required this.x,
    required this.y,
    required this.team,
  });

  factory TacticalPlayerSnapshot.fromJson(Map<String, dynamic> json) =>
      _$TacticalPlayerSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$TacticalPlayerSnapshotToJson(this);
}

@JsonSerializable()
class TacticalBallSnapshot {
  final double x;
  final double y;

  TacticalBallSnapshot({
    required this.x,
    required this.y,
  });

  factory TacticalBallSnapshot.fromJson(Map<String, dynamic> json) =>
      _$TacticalBallSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$TacticalBallSnapshotToJson(this);
}

@JsonSerializable()
class TacticalZoneSnapshot {
  @JsonKey(name: 'x_min')
  final double xMin;
  @JsonKey(name: 'x_max')
  final double xMax;
  @JsonKey(name: 'y_min')
  final double yMin;
  @JsonKey(name: 'y_max')
  final double yMax;

  TacticalZoneSnapshot({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  factory TacticalZoneSnapshot.fromJson(Map<String, dynamic> json) =>
      _$TacticalZoneSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$TacticalZoneSnapshotToJson(this);
}

@JsonSerializable()
class TacticalTag {
  final String tag;
  final String description;

  TacticalTag({required this.tag, required this.description});

  factory TacticalTag.fromJson(Map<String, dynamic> json) =>
      _$TacticalTagFromJson(json);
  Map<String, dynamic> toJson() => _$TacticalTagToJson(this);
}

@JsonSerializable()
class TacticalAlert {
  @JsonKey(name: 'alert_id')
  final String id;

  @JsonKey(name: 'decision_id')
  final String decisionId;

  @JsonKey(name: 'match_id')
  final String matchId;
  
  final String timestamp;

  @JsonKey(name: 'match_time')
  final double? matchTime;
  
  @JsonKey(name: 'severity_score')
  final double severityScore;
  
  @JsonKey(name: 'severity_label')
  final String severityLabel;
  
  final String category;
  
  @JsonKey(name: 'decision_type')
  final String decisionType;
  
  final String status;
  final String action;
  
  @JsonKey(name: 'review_countdown')
  final int reviewCountdown;

  @JsonKey(name: 'category_trigger_count')
  final int categoryTriggerCount;

  @JsonKey(name: 'trigger_metric')
  final String? triggerMetric;

  @JsonKey(name: 'recommended_action')
  final String? recommendedAction;

  final String feedback;

  @JsonKey(name: 'decision_effective')
  final bool? decisionEffective;

  @JsonKey(name: 'decision_failed')
  final bool? decisionFailed;

  final List<TacticalPlayerSnapshot>? players;
  final TacticalBallSnapshot? ball;
  final TacticalZoneSnapshot? zone;

  @JsonKey(name: 'team_a_tags')
  final List<TacticalTag>? teamATags;
  
  @JsonKey(name: 'team_b_tags')
  final List<TacticalTag>? teamBTags;

  @JsonKey(name: 'analysis')
  final Map<String, dynamic>? analysis;

  @JsonKey(name: 'tactical_outlier')
  final Map<String, dynamic>? tacticalOutlier;

  @JsonKey(name: 'flow_analysis')
  final Map<String, dynamic>? flowAnalysis;
  
  TacticalAlert({
    required this.id,
    required this.decisionId,
    required this.matchId,
    required this.timestamp,
    this.matchTime,
    required this.severityScore,
    required this.severityLabel,
    required this.category,
    required this.decisionType,
    required this.status,
    required this.action,
    required this.reviewCountdown,
    required this.categoryTriggerCount,
    this.triggerMetric,
    this.recommendedAction,
    this.feedback = 'none',
    this.decisionEffective,
    this.decisionFailed,
    this.players,
    this.ball,
    this.zone,
    this.teamATags,
    this.teamBTags,
    this.tacticalOutlier,
    this.flowAnalysis,
    this.analysis,
  });

  bool get isResponded => feedback != 'none';
  bool get isAccepted => feedback == 'accepted';
  bool get isDismissed => feedback == 'dismissed';
  bool get isEvaluated => decisionEffective == true || decisionFailed == true;

  factory TacticalAlert.fromJson(Map<String, dynamic> json) => _$TacticalAlertFromJson(json);
  Map<String, dynamic> toJson() => _$TacticalAlertToJson(this);

  Color get severityColor {
    switch (severityLabel.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MODERATE':
        return Colors.yellow;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
