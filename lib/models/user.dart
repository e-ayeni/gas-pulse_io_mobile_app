class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String role;
  final String? companyId;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.role,
    this.companyId,
  });

  String get fullName => '$firstName $lastName';
  bool get isSystemAdmin => role == 'SystemAdmin';
  bool get isCompanyAdmin => role == 'CompanyAdmin';
  bool get isPrivateConsumer => role == 'PrivateConsumer';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        role: json['role'] as String,
        companyId: json['companyId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'role': role,
        'companyId': companyId,
      };
}
