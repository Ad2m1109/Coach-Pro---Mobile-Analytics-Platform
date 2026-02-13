class AnalysisReport {
  final String id;
  final String? matchId;
  final String? inputVideoName;
  final String status;
  final double progress;
  final String? message;
  final Map<String, dynamic>? outputs;
  final DateTime? submittedAt;
  final DateTime? completedAt;

  AnalysisReport({
    required this.id,
    this.matchId,
    this.inputVideoName,
    required this.status,
    required this.progress,
    this.message,
    this.outputs,
    this.submittedAt,
    this.completedAt,
  });

  factory AnalysisReport.fromJson(Map<String, dynamic> json) {
    final rawOutputs = json['outputs'];
    Map<String, dynamic>? parsedOutputs;
    if (rawOutputs is Map<String, dynamic>) {
      parsedOutputs = rawOutputs;
    } else if (rawOutputs is Map) {
      parsedOutputs = rawOutputs.cast<String, dynamic>();
    }

    final submittedAtRaw = json['submitted_at'] ?? json['submittedAt'];
    final completedAtRaw = json['completed_at'] ?? json['completedAt'];

    return AnalysisReport(
      id: (json['analysis_id'] ?? json['id'] ?? '').toString(),
      matchId: (json['match_id'] ?? json['matchId'])?.toString(),
      inputVideoName: (json['input_video_name'] ?? json['inputVideoName'])?.toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      progress: ((json['progress'] ?? 0) as num).toDouble(),
      message: (json['message'])?.toString(),
      outputs: parsedOutputs,
      submittedAt: submittedAtRaw is String ? DateTime.parse(submittedAtRaw) : null,
      completedAt: completedAtRaw is String ? DateTime.parse(completedAtRaw) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'analysis_id': id,
    'match_id': matchId,
    'input_video_name': inputVideoName,
    'status': status,
    'progress': progress,
    'message': message,
    'outputs': outputs,
    'submitted_at': submittedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
  };
}
