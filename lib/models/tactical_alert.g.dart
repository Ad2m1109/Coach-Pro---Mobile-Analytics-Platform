// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tactical_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TacticalPlayerSnapshot _$TacticalPlayerSnapshotFromJson(
        Map<String, dynamic> json) =>
    TacticalPlayerSnapshot(
      id: (json['id'] as num).toInt(),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      team: json['team'] as String,
    );

Map<String, dynamic> _$TacticalPlayerSnapshotToJson(
        TacticalPlayerSnapshot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'x': instance.x,
      'y': instance.y,
      'team': instance.team,
    };

TacticalBallSnapshot _$TacticalBallSnapshotFromJson(Map<String, dynamic> json) =>
    TacticalBallSnapshot(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );

Map<String, dynamic> _$TacticalBallSnapshotToJson(
        TacticalBallSnapshot instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
    };

TacticalZoneSnapshot _$TacticalZoneSnapshotFromJson(Map<String, dynamic> json) =>
    TacticalZoneSnapshot(
      xMin: (json['x_min'] as num).toDouble(),
      xMax: (json['x_max'] as num).toDouble(),
      yMin: (json['y_min'] as num).toDouble(),
      yMax: (json['y_max'] as num).toDouble(),
    );

Map<String, dynamic> _$TacticalZoneSnapshotToJson(
        TacticalZoneSnapshot instance) =>
    <String, dynamic>{
      'x_min': instance.xMin,
      'x_max': instance.xMax,
      'y_min': instance.yMin,
      'y_max': instance.yMax,
    };

TacticalAlert _$TacticalAlertFromJson(Map<String, dynamic> json) =>
    TacticalAlert(
      id: json['alert_id'] as String,
      decisionId: (json['decision_id'] as String?) ?? (json['alert_id'] as String),
      matchId: (json['match_id'] as String?) ?? '',
      timestamp: json['timestamp'] as String,
      matchTime: (json['match_time'] as num?)?.toDouble(),
      severityScore: (json['severity_score'] as num).toDouble(),
      severityLabel: json['severity_label'] as String,
      category: json['category'] as String,
      decisionType: json['decision_type'] as String,
      status: json['status'] as String,
      action: json['action'] as String,
      reviewCountdown: (json['review_countdown'] as num).toInt(),
      categoryTriggerCount: (json['category_trigger_count'] as num).toInt(),
      triggerMetric: json['trigger_metric'] as String?,
      recommendedAction: json['recommended_action'] as String?,
      feedback: json['feedback'] as String? ?? 'none',
      decisionEffective: (json['decision_effective'] as num?) == 1 || json['decision_effective'] == true,
      decisionFailed: (json['decision_failed'] as num?) == 1 || json['decision_failed'] == true,
      players: (json['players'] as List<dynamic>?)
          ?.map((e) => TacticalPlayerSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      ball: json['ball'] == null ? null : TacticalBallSnapshot.fromJson(json['ball'] as Map<String, dynamic>),
      zone: json['zone'] == null ? null : TacticalZoneSnapshot.fromJson(json['zone'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TacticalAlertToJson(TacticalAlert instance) =>
    <String, dynamic>{
      'alert_id': instance.id,
      'decision_id': instance.decisionId,
      'match_id': instance.matchId,
      'timestamp': instance.timestamp,
      'match_time': instance.matchTime,
      'severity_score': instance.severityScore,
      'severity_label': instance.severityLabel,
      'category': instance.category,
      'decision_type': instance.decisionType,
      'trigger_metric': instance.triggerMetric,
      'recommended_action': instance.recommendedAction,
      'status': instance.status,
      'action': instance.action,
      'review_countdown': instance.reviewCountdown,
      'category_trigger_count': instance.categoryTriggerCount,
      'feedback': instance.feedback,
      'decision_effective': instance.decisionEffective,
      'decision_failed': instance.decisionFailed,
      'players': instance.players?.map((e) => e.toJson()).toList(),
      'ball': instance.ball?.toJson(),
      'zone': instance.zone?.toJson(),
    };
