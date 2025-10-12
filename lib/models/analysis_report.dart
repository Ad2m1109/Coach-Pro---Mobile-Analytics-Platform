import 'package:json_annotation/json_annotation.dart';

part 'analysis_report.g.dart';

@JsonSerializable()
class AnalysisReport {
  final String id;
  final String matchId;
  final String? reportType;
  final Map<String, dynamic>? reportData;
  final DateTime generatedAt;
  final String? generatedBy;

  AnalysisReport({
    required this.id,
    required this.matchId,
    this.reportType,
    this.reportData,
    required this.generatedAt,
    this.generatedBy,
  });

  factory AnalysisReport.fromJson(Map<String, dynamic> json) => _$AnalysisReportFromJson(json);
  Map<String, dynamic> toJson() => _$AnalysisReportToJson(this);
}
