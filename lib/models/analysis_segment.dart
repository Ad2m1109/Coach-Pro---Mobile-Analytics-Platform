class AnalysisSegment {
  final String id;
  final String? analysisId;
  final String matchId;
  final int segmentIndex;
  final double startSec;
  final double endSec;
  final double videoStartSec;
  final Map<String, dynamic>? analysisJson;
  final String? recommendation;
  final double severityScore;
  final String severityLabel;
  final String status;

  AnalysisSegment({
    required this.id,
    this.analysisId,
    required this.matchId,
    required this.segmentIndex,
    required this.startSec,
    required this.endSec,
    required this.videoStartSec,
    this.analysisJson,
    this.recommendation,
    required this.severityScore,
    required this.severityLabel,
    required this.status,
  });

  factory AnalysisSegment.fromJson(Map<String, dynamic> json) {
    return AnalysisSegment(
      id: json['id'] ?? '',
      analysisId: json['analysis_id'],
      matchId: json['match_id'] ?? '',
      segmentIndex: json['segment_index'] ?? 0,
      startSec: (json['start_sec'] ?? 0).toDouble(),
      endSec: (json['end_sec'] ?? 0).toDouble(),
      videoStartSec: (json['video_start_sec'] ?? 0).toDouble(),
      analysisJson: json['analysis_json'] ?? json['analysis'],
      recommendation: json['recommendation'],
      severityScore: (json['severity_score'] ?? 0).toDouble(),
      severityLabel: json['severity_label'] ?? 'LOW',
      status: json['status'] ?? 'PENDING',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'analysis_id': analysisId,
        'match_id': matchId,
        'segment_index': segmentIndex,
        'start_sec': startSec,
        'end_sec': endSec,
        'video_start_sec': videoStartSec,
        'analysis_json': analysisJson,
        'recommendation': recommendation,
        'severity_score': severityScore,
        'severity_label': severityLabel,
        'status': status,
      };
}
