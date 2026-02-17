// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalysisReport _$AnalysisReportFromJson(Map<String, dynamic> json) =>
    AnalysisReport(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      reportType: json['reportType'] as String?,
      reportData: json['reportData'] as Map<String, dynamic>?,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      generatedBy: json['generatedBy'] as String?,
    );

Map<String, dynamic> _$AnalysisReportToJson(AnalysisReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'matchId': instance.matchId,
      'reportType': instance.reportType,
      'reportData': instance.reportData,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'generatedBy': instance.generatedBy,
    };