class Gateway {
  final String id;
  final String deviceId;
  final String? name;
  final String siteId;
  final DateTime? lastSeenAt;
  final String? firmwareVersion;
  final bool isActive;

  Gateway({
    required this.id,
    required this.deviceId,
    this.name,
    required this.siteId,
    this.lastSeenAt,
    this.firmwareVersion,
    required this.isActive,
  });

  bool get isOnline {
    if (lastSeenAt == null) return false;
    return DateTime.now().difference(lastSeenAt!).inHours < 2;
  }

  factory Gateway.fromJson(Map<String, dynamic> json) => Gateway(
        id: json['id'] as String,
        deviceId: json['deviceId'] as String,
        name: json['name'] as String?,
        siteId: json['siteId'] as String,
        lastSeenAt: json['lastSeenAt'] != null
            ? DateTime.parse(json['lastSeenAt'] as String)
            : null,
        firmwareVersion: json['firmwareVersion'] as String?,
        isActive: json['isActive'] as bool? ?? true,
      );
}

class RegisterGatewayRequest {
  final String deviceId;
  final String? name;

  RegisterGatewayRequest({required this.deviceId, this.name});

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        if (name != null) 'name': name,
      };
}
