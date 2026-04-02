import 'cylinder_type.dart';

/// A GasPulse scale discovered and connected via BLE
class BleScaleDevice {
  final String deviceId;
  final String? localName;
  final double rawWeightGrams;
  final int batteryPercent;
  final int rssi;
  final DateTime lastSeen;
  final String? friendlyName;
  final CylinderType? cylinderType;
  final bool connected;
  final bool cylinderLifted;

  BleScaleDevice({
    required this.deviceId,
    this.localName,
    this.rawWeightGrams = 0,
    this.batteryPercent = 0,
    required this.rssi,
    required this.lastSeen,
    this.friendlyName,
    this.cylinderType,
    this.connected = false,
    this.cylinderLifted = false,
  });

  String get displayName => friendlyName ?? localName ?? deviceId;

  double? get gasRemainingPercent {
    if (cylinderType == null) return null;
    final gasGrams = rawWeightGrams - cylinderType!.tareWeightGrams;
    if (gasGrams <= 0) return 0;
    return ((gasGrams / cylinderType!.fullGasWeightGrams) * 100).clamp(0, 100);
  }

  double? get gasRemainingKg {
    if (cylinderType == null) return null;
    final gasGrams = rawWeightGrams - cylinderType!.tareWeightGrams;
    return (gasGrams > 0 ? gasGrams : 0) / 1000.0;
  }

  double get rawWeightKg => rawWeightGrams / 1000.0;

  BleScaleDevice copyWith({
    String? deviceId,
    String? localName,
    double? rawWeightGrams,
    int? batteryPercent,
    int? rssi,
    DateTime? lastSeen,
    String? friendlyName,
    CylinderType? cylinderType,
    bool? connected,
    bool? cylinderLifted,
  }) =>
      BleScaleDevice(
        deviceId: deviceId ?? this.deviceId,
        localName: localName ?? this.localName,
        rawWeightGrams: rawWeightGrams ?? this.rawWeightGrams,
        batteryPercent: batteryPercent ?? this.batteryPercent,
        rssi: rssi ?? this.rssi,
        lastSeen: lastSeen ?? this.lastSeen,
        friendlyName: friendlyName ?? this.friendlyName,
        cylinderType: cylinderType ?? this.cylinderType,
        connected: connected ?? this.connected,
        cylinderLifted: cylinderLifted ?? this.cylinderLifted,
      );
}

/// A single day's total gas snapshot across all BLE devices (for guest chart)
class LocalDailySnapshot {
  final String date; // ISO date: "2026-04-02"
  final double totalGasKg;

  LocalDailySnapshot({required this.date, required this.totalGasKg});

  factory LocalDailySnapshot.fromJson(Map<String, dynamic> json) => LocalDailySnapshot(
        date: json['date'] as String,
        totalGasKg: (json['totalGasKg'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'date': date, 'totalGasKg': totalGasKg};
}

/// Persisted local scale config
class LocalScaleConfig {
  final String deviceId;
  final String? friendlyName;
  final String? cylinderTypeId;

  LocalScaleConfig({required this.deviceId, this.friendlyName, this.cylinderTypeId});

  factory LocalScaleConfig.fromJson(Map<String, dynamic> json) => LocalScaleConfig(
        deviceId: json['deviceId'] as String,
        friendlyName: json['friendlyName'] as String?,
        cylinderTypeId: json['cylinderTypeId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'friendlyName': friendlyName,
        'cylinderTypeId': cylinderTypeId,
      };
}
