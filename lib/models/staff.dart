enum PermissionLevel {
  fullAccess('full_access', 'Full Access'),
  viewOnly('view_only', 'View Only'),
  notesOnly('notes_only', 'Notes Only');

  final String value;
  final String displayName;

  const PermissionLevel(this.value, this.displayName);

  static PermissionLevel fromString(String value) {
    return PermissionLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => PermissionLevel.viewOnly,
    );
  }
}

enum StaffRole {
  headCoach('head_coach', 'Head Coach'),
  assistantCoach('assistant_coach', 'Assistant Coach'),
  physio('physio', 'Physio'),
  analyst('analyst', 'Analyst'),
  player('player', 'Player');

  final String value;
  final String displayName;

  const StaffRole(this.value, this.displayName);

  static StaffRole fromString(String value) {
    return StaffRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => StaffRole.assistantCoach,
    );
  }
}

class Staff {
  final String id;
  final String? teamId;
  final String? userId;
  final String name;
  final StaffRole? role;
  final PermissionLevel permissionLevel;
  final String? email;

  Staff({
    required this.id,
    this.teamId,
    this.userId,
    required this.name,
    this.role,
    this.permissionLevel = PermissionLevel.viewOnly,
    this.email,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] as String,
      teamId: json['team_id'] as String?,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      role: json['role'] != null ? StaffRole.fromString(json['role']) : null,
      permissionLevel: json['permission_level'] != null
          ? PermissionLevel.fromString(json['permission_level'])
          : PermissionLevel.viewOnly,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'user_id': userId,
      'name': name,
      'role': role?.value,
      'permission_level': permissionLevel.value,
      'email': email,
    };
  }
}

class StaffCreateRequest {
  final String teamId;
  final String name;
  final StaffRole role;
  final String email;
  final String password;

  StaffCreateRequest({
    required this.teamId,
    required this.name,
    required this.role,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'name': name,
      'role': role.value,
      'email': email,
      'password': password,
    };
  }
}
