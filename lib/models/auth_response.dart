/// Resposta do endpoint POST /auth/login
class AuthResponse {
  AuthResponse({
    required this.message,
    required this.user,
    this.organization,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] as String? ?? '',
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      organization: json['organization'] != null
          ? Organization.fromJson(json['organization'] as Map<String, dynamic>)
          : null,
      token: json['token'] as String? ?? '',
    );
  }

  final String message;
  final User user;
  final Organization? organization;
  final String token;
}

class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.organizationId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'USER',
      organizationId: json['organizationId'] as String?,
    );
  }

  final String id;
  final String name;
  final String email;
  final String role;
  final String? organizationId;
}

class Organization {
  Organization({required this.id, required this.name});

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  final String id;
  final String name;
}
