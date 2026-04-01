class CylinderType {
  final String id;
  final String name;
  final int fullGasWeightGrams;
  final int tareWeightGrams;

  CylinderType({
    required this.id,
    required this.name,
    required this.fullGasWeightGrams,
    required this.tareWeightGrams,
  });

  double get fullGasWeightKg => fullGasWeightGrams / 1000.0;
  double get tareWeightKg => tareWeightGrams / 1000.0;

  factory CylinderType.fromJson(Map<String, dynamic> json) => CylinderType(
        id: json['id'] as String,
        name: json['name'] as String,
        fullGasWeightGrams: json['fullGasWeightGrams'] as int,
        tareWeightGrams: json['tareWeightGrams'] as int,
      );

  static final List<CylinderType> defaults = [
    CylinderType(id: 'local-3kg', name: '3kg Mini', fullGasWeightGrams: 3000, tareWeightGrams: 5200),
    CylinderType(id: 'local-6kg', name: '6kg Camping', fullGasWeightGrams: 6000, tareWeightGrams: 7500),
    CylinderType(id: 'local-12.5kg', name: '12.5kg Standard', fullGasWeightGrams: 12500, tareWeightGrams: 15000),
    CylinderType(id: 'local-25kg', name: '25kg Medium', fullGasWeightGrams: 25000, tareWeightGrams: 22000),
    CylinderType(id: 'local-50kg', name: '50kg Commercial', fullGasWeightGrams: 50000, tareWeightGrams: 38000),
  ];
}
