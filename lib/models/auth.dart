import 'user.dart';

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      };
}

class LoginResponse {
  final String token;
  final String refreshToken;
  final DateTime expiresAt;
  final User user;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        token: json['token'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
}
