/// A single day's computed gas consumption for the local guest chart
class LocalDayConsumption {
  final DateTime date;
  final double consumptionKg;

  LocalDayConsumption({required this.date, required this.consumptionKg});
}

enum AnomalyType { possibleLeak, fastConsumption, cylinderRemoved }

AnomalyType anomalyTypeFromString(String s) {
  switch (s) {
    case 'PossibleLeak':
      return AnomalyType.possibleLeak;
    case 'FastConsumption':
      return AnomalyType.fastConsumption;
    case 'CylinderRemoved':
      return AnomalyType.cylinderRemoved;
    default:
      return AnomalyType.fastConsumption;
  }
}

String anomalyTypeToString(AnomalyType type) {
  switch (type) {
    case AnomalyType.possibleLeak:
      return 'PossibleLeak';
    case AnomalyType.fastConsumption:
      return 'FastConsumption';
    case AnomalyType.cylinderRemoved:
      return 'CylinderRemoved';
  }
}

class CylinderAnomaly {
  final String cylinderId;
  final String friendlyName;
  final String siteName;
  final AnomalyType type;
  final double actualKg;
  final double? baselineKg;
  final DateTime detectedAt;
  final String description;

  CylinderAnomaly({
    required this.cylinderId,
    required this.friendlyName,
    required this.siteName,
    required this.type,
    required this.actualKg,
    this.baselineKg,
    required this.detectedAt,
    required this.description,
  });

  factory CylinderAnomaly.fromJson(Map<String, dynamic> json) =>
      CylinderAnomaly(
        cylinderId: json['cylinderId'] as String,
        friendlyName: json['friendlyName'] as String,
        siteName: json['siteName'] as String,
        type: anomalyTypeFromString(json['type'] as String? ?? 'FastConsumption'),
        actualKg: (json['actualKg'] as num).toDouble(),
        baselineKg: (json['baselineKg'] as num?)?.toDouble(),
        detectedAt: DateTime.parse(json['detectedAt'] as String),
        description: json['description'] as String,
      );
}

class DayOfWeekConsumption {
  final int day;
  final String dayName;
  final double avgConsumptionKg;

  DayOfWeekConsumption({
    required this.day,
    required this.dayName,
    required this.avgConsumptionKg,
  });

  factory DayOfWeekConsumption.fromJson(Map<String, dynamic> json) =>
      DayOfWeekConsumption(
        day: json['day'] as int,
        dayName: json['dayName'] as String,
        avgConsumptionKg: (json['avgConsumptionKg'] as num).toDouble(),
      );
}

class ShiftConsumption {
  final String shiftName;
  final String shiftHours;
  final double avgConsumptionKg;

  ShiftConsumption({
    required this.shiftName,
    required this.shiftHours,
    required this.avgConsumptionKg,
  });

  factory ShiftConsumption.fromJson(Map<String, dynamic> json) =>
      ShiftConsumption(
        shiftName: json['shiftName'] as String,
        shiftHours: json['shiftHours'] as String,
        avgConsumptionKg: (json['avgConsumptionKg'] as num).toDouble(),
      );
}

class MonthlyConsumption {
  final int year;
  final int month;
  final String label;
  final double totalConsumptionKg;

  MonthlyConsumption({
    required this.year,
    required this.month,
    required this.label,
    required this.totalConsumptionKg,
  });

  factory MonthlyConsumption.fromJson(Map<String, dynamic> json) =>
      MonthlyConsumption(
        year: json['year'] as int,
        month: json['month'] as int,
        label: json['label'] as String,
        totalConsumptionKg: (json['totalConsumptionKg'] as num).toDouble(),
      );
}

class ConsumptionAnalytics {
  final List<DayOfWeekConsumption> byDayOfWeek;
  final List<ShiftConsumption> byShift;
  final List<MonthlyConsumption> byMonth;

  ConsumptionAnalytics({
    required this.byDayOfWeek,
    required this.byShift,
    required this.byMonth,
  });

  factory ConsumptionAnalytics.fromJson(Map<String, dynamic> json) =>
      ConsumptionAnalytics(
        byDayOfWeek: (json['byDayOfWeek'] as List)
            .map((e) => DayOfWeekConsumption.fromJson(e as Map<String, dynamic>))
            .toList(),
        byShift: (json['byShift'] as List)
            .map((e) => ShiftConsumption.fromJson(e as Map<String, dynamic>))
            .toList(),
        byMonth: (json['byMonth'] as List)
            .map((e) => MonthlyConsumption.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}