enum SubscriptionTier { free, basic, pro }

SubscriptionTier subscriptionTierFromString(String s) {
  switch (s) {
    case 'Basic':
      return SubscriptionTier.basic;
    case 'Pro':
      return SubscriptionTier.pro;
    default:
      return SubscriptionTier.free;
  }
}

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String role;
  final String? companyId;
  final SubscriptionTier subscriptionTier;
  final DateTime? subscriptionExpiresAt;
  final bool isSubscriptionActive;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.role,
    this.companyId,
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionExpiresAt,
    this.isSubscriptionActive = false,
  });

  String get fullName => '$firstName $lastName';
  bool get isSystemAdmin => role == 'SystemAdmin';
  bool get isCompanyAdmin => role == 'CompanyAdmin';
  bool get isPrivateConsumer => role == 'PrivateConsumer';

  /// True if the user can access analytics and anomaly detection.
  /// CompanyAdmins always can; PrivateConsumers need an active Pro subscription.
  bool get hasProAccess =>
      isCompanyAdmin || isSystemAdmin || (subscriptionTier == SubscriptionTier.pro && isSubscriptionActive);

  /// True if the user can access cloud alerts and predictions.
  /// CompanyAdmins always can; PrivateConsumers need Basic or Pro.
  bool get hasBasicAccess =>
      isCompanyAdmin ||
      isSystemAdmin ||
      (subscriptionTier != SubscriptionTier.free && isSubscriptionActive);

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        role: json['role'] as String,
        companyId: json['companyId'] as String?,
        subscriptionTier: subscriptionTierFromString(
            json['subscriptionTier'] as String? ?? 'Free'),
        subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
            ? DateTime.parse(json['subscriptionExpiresAt'] as String)
            : null,
        isSubscriptionActive: json['isSubscriptionActive'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'role': role,
        'companyId': companyId,
        'subscriptionTier': subscriptionTier.name,
        'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
        'isSubscriptionActive': isSubscriptionActive,
      };
}