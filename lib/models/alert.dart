enum AlertType { lowGas, criticalGas, cylinderRemoved, batteryLow, gatewayOffline }

AlertType alertTypeFromString(String s) {
  switch (s) {
    case 'LowGas': return AlertType.lowGas;
    case 'CriticalGas': return AlertType.criticalGas;
    case 'CylinderRemoved': return AlertType.cylinderRemoved;
    case 'BatteryLow': return AlertType.batteryLow;
    case 'GatewayOffline': return AlertType.gatewayOffline;
    default: return AlertType.lowGas;
  }
}

class Alert {
  final String id;
  final String? cylinderId;
  final String? siteId;
  final AlertType alertType;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  Alert({
    required this.id,
    this.cylinderId,
    this.siteId,
    required this.alertType,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
        id: json['id'] as String,
        cylinderId: json['cylinderId'] as String?,
        siteId: json['siteId'] as String?,
        alertType: alertTypeFromString(json['alertType'] as String),
        message: json['message'] as String,
        isRead: json['isRead'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
