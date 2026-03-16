class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String employeeId;
  final String department;
  final String role;
  final bool isEmailVerified;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.employeeId,
    required this.department,
    this.role = 'teacher',
    this.isEmailVerified = false,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      employeeId: map['employee_id'] as String? ?? '',
      department: map['department'] as String? ?? '',
      role: map['role'] as String? ?? 'teacher',
      isEmailVerified: map['is_email_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'employee_id': employeeId,
      'department': department,
      'role': role,
      'is_email_verified': isEmailVerified,
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? employeeId,
    String? department,
    String? role,
    bool? isEmailVerified,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}
