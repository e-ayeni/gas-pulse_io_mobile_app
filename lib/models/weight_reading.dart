class WeightReading {
  final String id;
  final int rawWeightGrams;
  final int gasRemainingGrams;
  final double gasRemainingPercent;
  final int? batteryPercent;
  final DateTime readAt;
  final DateTime receivedAt;

  WeightReading({
    required this.id,
    required this.rawWeightGrams,
    required this.gasRemainingGrams,
    required this.gasRemainingPercent,
    this.batteryPercent,
    required this.readAt,
    required this.receivedAt,
  });

  double get rawWeightKg => rawWeightGrams / 1000.0;
  double get gasRemainingKg => gasRemainingGrams / 1000.0;

  factory WeightReading.fromJson(Map<String, dynamic> json) => WeightReading(
        id: json['id'] as String,
        rawWeightGrams: json['rawWeightGrams'] as int,
        gasRemainingGrams: json['gasRemainingGrams'] as int,
        gasRemainingPercent: (json['gasRemainingPercent'] as num).toDouble(),
        batteryPercent: json['batteryPercent'] as int?,
        readAt: DateTime.parse(json['readAt'] as String),
        receivedAt: DateTime.parse(json['receivedAt'] as String),
      );
}
