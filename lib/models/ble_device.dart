import 'cylinder_type.dart';

/// A GasPulse scale discovered via BLE advertisement
class BleScaleDevice {
  final String deviceId;
  final String? localName;
  final int rawWeightGrams;
  final int batteryPercent;
  final int rssi;
  final DateTime lastSeen;
  final String? friendlyName;
  final CylinderType? cylinderType;

  BleScaleDevice({
    required this.deviceId,
    this.localName,
    required this.rawWeightGrams,
    required this.batteryPercent,
    required this.rssi,
    required this.lastSeen,
    this.friendlyName,
    this.cylinderType,
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
    int? rawWeightGrams,
    int? batteryPercent,
    int? rssi,
    DateTime? lastSeen,
    String? friendlyName,
    CylinderType? cylinderType,
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
      );
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
