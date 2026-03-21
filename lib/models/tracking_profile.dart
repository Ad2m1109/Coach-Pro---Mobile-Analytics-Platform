class CalibrationPoint {
  final double u; // pixel x
  final double v; // pixel y
  final double x; // pitch x (meters)
  final double y; // pitch y (meters)

  CalibrationPoint({
    required this.u,
    required this.v,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toJson() => {
    'u': u,
    'v': v,
    'x': x,
    'y': y,
  };

  factory CalibrationPoint.fromJson(Map<String, dynamic> json) => CalibrationPoint(
    u: (json['u'] as num).toDouble(),
    v: (json['v'] as num).toDouble(),
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
  );
}

class ROICoordinate {
  final double x;
  final double y;

  ROICoordinate({required this.x, required this.y});

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  factory ROICoordinate.fromJson(Map<String, dynamic> json) => ROICoordinate(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
  );
}

class ROIZone {
  final List<ROICoordinate> points;
  final String label;

  ROIZone({required this.points, required this.label});

  Map<String, dynamic> toJson() => {
    'points': points.map((e) => e.toJson()).toList(),
    'label': label,
  };

  factory ROIZone.fromJson(Map<String, dynamic> json) => ROIZone(
    points: (json['points'] as List).map((e) => ROICoordinate.fromJson(e)).toList(),
    label: json['label'] as String,
  );
}

class CameraConfig {
  final String? id;
  final String label;
  final String videoSource;
  final int syncOffsetMs;
  final List<CalibrationPoint> calibration;
  final List<ROIZone> roi;

  CameraConfig({
    this.id,
    required this.label,
    required this.videoSource,
    this.syncOffsetMs = 0,
    this.calibration = const [],
    this.roi = const [],
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'label': label,
    'video_source': videoSource,
    'sync_offset_ms': syncOffsetMs,
    'calibration': calibration.map((e) => e.toJson()).toList(),
    'roi': roi.map((e) => e.toJson()).toList(),
  };

  factory CameraConfig.fromJson(Map<String, dynamic> json) => CameraConfig(
    id: json['id'] as String?,
    label: json['label'] as String,
    videoSource: json['video_source'] as String,
    syncOffsetMs: json['sync_offset_ms'] as int? ?? 0,
    calibration: (json['calibration'] as List?)
            ?.map((e) => CalibrationPoint.fromJson(e))
            .toList() ??
        [],
    roi: (json['roi'] as List?)?.map((e) => ROIZone.fromJson(e)).toList() ?? [],
  );
}

class TrackingProfile {
  final String? id;
  final String? matchId;
  final String name;
  final Map<String, dynamic> engineSettings;
  final bool isActive;
  final List<CameraConfig> cameras;
  final DateTime? createdAt;

  TrackingProfile({
    this.id,
    this.matchId,
    required this.name,
    this.engineSettings = const {},
    this.isActive = true,
    this.cameras = const [],
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'match_id': matchId,
    'name': name,
    'engine_settings': engineSettings,
    'is_active': isActive,
    'cameras': cameras.map((e) => e.toJson()).toList(),
  };

  factory TrackingProfile.fromJson(Map<String, dynamic> json) => TrackingProfile(
    id: json['id'] as String?,
    matchId: json['match_id'] as String?,
    name: json['name'] as String,
    engineSettings: json['engine_settings'] as Map<String, dynamic>? ?? {},
    isActive: json['is_active'] as bool? ?? true,
    cameras: (json['cameras'] as List?)
            ?.map((e) => CameraConfig.fromJson(e))
            .toList() ??
        [],
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
  );
}
