class AppUser {
  AppUser({
    required this.id,
    required this.code,
    required this.name,
    required this.role,
    required this.paidLeaveDaysLeft,
    required this.mustChangePassword,
  });

  final String id;
  final String code;
  final String name;
  final String role;
  final num paidLeaveDaysLeft;
  final bool mustChangePassword;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        paidLeaveDaysLeft: (json['paidLeaveDaysLeft'] as num?) ?? 0,
        mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      );

  AppUser copyWith({bool? mustChangePassword}) => AppUser(
        id: id,
        code: code,
        name: name,
        role: role,
        paidLeaveDaysLeft: paidLeaveDaysLeft,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      );
}
