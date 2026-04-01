import 'weight_reading.dart';

enum CylinderStatus { normal, low, critical, empty, noData }

CylinderStatus cylinderStatusFromString(String s) {
  switch (s.toLowerCase()) {
    case 'normal': return CylinderStatus.normal;
    case 'low': return CylinderStatus.low;
    case 'critical': return CylinderStatus.critical;
    case 'empty': return CylinderStatus.empty;
    default: return CylinderStatus.noData;
  }
}

class CylinderSummary {
  final String id;
  final String friendlyName;
  final String? cylinderTypeName;
  final double? gasRemainingPercent;
  final double? gasRemainingKg;
  final int? estimatedDaysRemaining;
  final DateTime? lastReadingAt;
  final int? batteryPercent;
  final CylinderStatus status;

  CylinderSummary({
    required this.id,
    required this.friendlyName,
    this.cylinderTypeName,
    this.gasRemainingPercent,
    this.gasRemainingKg,
    this.estimatedDaysRemaining,
    this.lastReadingAt,
    this.batteryPercent,
    required this.status,
  });

  factory CylinderSummary.fromJson(Map<String, dynamic> json) => CylinderSummary(
        id: json['id'] as String,
        friendlyName: json['friendlyName'] as String,
        cylinderTypeName: json['cylinderTypeName'] as String?,
        gasRemainingPercent: (json['gasRemainingPercent'] as num?)?.toDouble(),
        gasRemainingKg: (json['gasRemainingKg'] as num?)?.toDouble(),
        estimatedDaysRemaining: json['estimatedDaysRemaining'] as int?,
        lastReadingAt: json['lastReadingAt'] != null
            ? DateTime.parse(json['lastReadingAt'] as String)
            : null,
        batteryPercent: json['batteryPercent'] as int?,
        status: cylinderStatusFromString(json['status'] as String? ?? 'NoData'),
      );
}

class CylinderDetail {
  final String id;
  final String friendlyName;
  final String? cylinderTypeName;
  final String? scaleDeviceId;
  final int? customTareWeightGrams;
  final int alertThresholdPercent;
  final double? gasRemainingPercent;
  final double? gasRemainingKg;
  final int? estimatedDaysRemaining;
  final DateTime? lastReadingAt;
  final int? batteryPercent;
  final CylinderStatus status;
  final List<WeightReading> recentReadings;

  CylinderDetail({
    required this.id,
    required this.friendlyName,
    this.cylinderTypeName,
    this.scaleDeviceId,
    this.customTareWeightGrams,
    required this.alertThresholdPercent,
    this.gasRemainingPercent,
    this.gasRemainingKg,
    this.estimatedDaysRemaining,
    this.lastReadingAt,
    this.batteryPercent,
    required this.status,
    required this.recentReadings,
  });

  factory CylinderDetail.fromJson(Map<String, dynamic> json) => CylinderDetail(
        id: json['id'] as String,
        friendlyName: json['friendlyName'] as String,
        cylinderTypeName: json['cylinderTypeName'] as String?,
        scaleDeviceId: json['scaleDeviceId'] as String?,
        customTareWeightGrams: json['customTareWeightGrams'] as int?,
        alertThresholdPercent: json['alertThresholdPercent'] as int? ?? 20,
        gasRemainingPercent: (json['gasRemainingPercent'] as num?)?.toDouble(),
        gasRemainingKg: (json['gasRemainingKg'] as num?)?.toDouble(),
        estimatedDaysRemaining: json['estimatedDaysRemaining'] as int?,
        lastReadingAt: json['lastReadingAt'] != null
            ? DateTime.parse(json['lastReadingAt'] as String)
            : null,
        batteryPercent: json['batteryPercent'] as int?,
        status: cylinderStatusFromString(json['status'] as String? ?? 'NoData'),
        recentReadings: (json['recentReadings'] as List<dynamic>?)
                ?.map((e) => WeightReading.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class CreateCylinderRequest {
  final String friendlyName;
  final String cylinderTypeId;
  final int? customTareWeightGrams;
  final int? alertThresholdPercent;

  CreateCylinderRequest({
    required this.friendlyName,
    required this.cylinderTypeId,
    this.customTareWeightGrams,
    this.alertThresholdPercent,
  });

  Map<String, dynamic> toJson() => {
        'friendlyName': friendlyName,
        'cylinderTypeId': cylinderTypeId,
        if (customTareWeightGrams != null) 'customTareWeightGrams': customTareWeightGrams,
        if (alertThresholdPercent != null) 'alertThresholdPercent': alertThresholdPercent,
      };
}
