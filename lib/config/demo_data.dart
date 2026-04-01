import '../models/alert.dart';
import '../models/cylinder.dart';
import '../models/gateway.dart';
import '../models/site.dart';
import '../models/weight_reading.dart';

class DemoData {
  static final List<Site> sites = [
    Site(
      id: 'demo-site-1',
      name: 'Home',
      address: NigerianAddress(
        street: '12 Admiralty Way',
        area: 'Lekki Phase 1',
        localGovernment: 'Eti-Osa',
        state: 'Lagos',
      ),
      latitude: 6.4281,
      longitude: 3.4219,
      userId: 'demo-user',
      cylinders: [
        CylinderSummary(
          id: 'demo-cyl-1',
          friendlyName: 'Kitchen Gas',
          cylinderTypeName: '12.5kg Standard',
          gasRemainingPercent: 73.6,
          gasRemainingKg: 9.2,
          estimatedDaysRemaining: 18,
          lastReadingAt: DateTime.now().subtract(const Duration(minutes: 15)),
          batteryPercent: 87,
          status: CylinderStatus.normal,
        ),
        CylinderSummary(
          id: 'demo-cyl-2',
          friendlyName: 'Backup Cylinder',
          cylinderTypeName: '3kg Mini',
          gasRemainingPercent: 30.0,
          gasRemainingKg: 0.9,
          estimatedDaysRemaining: 5,
          lastReadingAt: DateTime.now().subtract(const Duration(minutes: 5)),
          batteryPercent: 42,
          status: CylinderStatus.low,
        ),
      ],
      gateways: [
        Gateway(
          id: 'demo-gw-1',
          deviceId: 'GW-HOME-001',
          name: 'Kitchen Gateway',
          siteId: 'demo-site-1',
          lastSeenAt: DateTime.now().subtract(const Duration(minutes: 3)),
          firmwareVersion: '1.2.0',
          isActive: true,
        ),
      ],
    ),
    Site(
      id: 'demo-site-2',
      name: 'Office',
      address: NigerianAddress(
        street: '5 Adeola Odeku',
        area: 'Victoria Island',
        localGovernment: 'Eti-Osa',
        state: 'Lagos',
      ),
      latitude: 6.4311,
      longitude: 3.4157,
      userId: 'demo-user',
      cylinders: [
        CylinderSummary(
          id: 'demo-cyl-3',
          friendlyName: 'Generator',
          cylinderTypeName: '6kg Camping',
          gasRemainingPercent: 10.0,
          gasRemainingKg: 0.6,
          estimatedDaysRemaining: 1,
          lastReadingAt: DateTime.now().subtract(const Duration(minutes: 12)),
          batteryPercent: 15,
          status: CylinderStatus.critical,
        ),
        CylinderSummary(
          id: 'demo-cyl-4',
          friendlyName: 'Workshop Tank',
          cylinderTypeName: '25kg Medium',
          gasRemainingPercent: 94.0,
          gasRemainingKg: 23.5,
          estimatedDaysRemaining: 45,
          lastReadingAt: DateTime.now(),
          batteryPercent: 96,
          status: CylinderStatus.normal,
        ),
      ],
      gateways: [
        Gateway(
          id: 'demo-gw-2',
          deviceId: 'GW-OFFICE-001',
          name: 'Office Gateway',
          siteId: 'demo-site-2',
          lastSeenAt: DateTime.now().subtract(const Duration(hours: 3)),
          firmwareVersion: '1.1.0',
          isActive: true,
        ),
      ],
    ),
  ];

  static CylinderDetail cylinderDetail(String cylinderId) {
    final now = DateTime.now();

    switch (cylinderId) {
      case 'demo-cyl-1':
        return CylinderDetail(
          id: 'demo-cyl-1',
          friendlyName: 'Kitchen Gas',
          cylinderTypeName: '12.5kg Standard',
          scaleDeviceId: 'GP-AA:BB:CC:01',
          alertThresholdPercent: 20,
          gasRemainingPercent: 73.6,
          gasRemainingKg: 9.2,
          estimatedDaysRemaining: 18,
          lastReadingAt: now.subtract(const Duration(minutes: 15)),
          batteryPercent: 87,
          status: CylinderStatus.normal,
          recentReadings: _generateReadings(
            startPercent: 98,
            endPercent: 73.6,
            days: 14,
          ),
        );
      case 'demo-cyl-2':
        return CylinderDetail(
          id: 'demo-cyl-2',
          friendlyName: 'Backup Cylinder',
          cylinderTypeName: '3kg Mini',
          scaleDeviceId: 'GP-AA:BB:CC:02',
          alertThresholdPercent: 20,
          gasRemainingPercent: 30.0,
          gasRemainingKg: 0.9,
          estimatedDaysRemaining: 5,
          lastReadingAt: now.subtract(const Duration(minutes: 5)),
          batteryPercent: 42,
          status: CylinderStatus.low,
          recentReadings: _generateReadings(
            startPercent: 85,
            endPercent: 30,
            days: 21,
          ),
        );
      case 'demo-cyl-3':
        return CylinderDetail(
          id: 'demo-cyl-3',
          friendlyName: 'Generator',
          cylinderTypeName: '6kg Camping',
          scaleDeviceId: 'GP-AA:BB:CC:03',
          alertThresholdPercent: 20,
          gasRemainingPercent: 10.0,
          gasRemainingKg: 0.6,
          estimatedDaysRemaining: 1,
          lastReadingAt: now.subtract(const Duration(minutes: 12)),
          batteryPercent: 15,
          status: CylinderStatus.critical,
          recentReadings: _generateReadings(
            startPercent: 100,
            endPercent: 10,
            days: 7,
          ),
        );
      case 'demo-cyl-4':
      default:
        return CylinderDetail(
          id: 'demo-cyl-4',
          friendlyName: 'Workshop Tank',
          cylinderTypeName: '25kg Medium',
          scaleDeviceId: 'GP-AA:BB:CC:04',
          alertThresholdPercent: 20,
          gasRemainingPercent: 94.0,
          gasRemainingKg: 23.5,
          estimatedDaysRemaining: 45,
          lastReadingAt: now,
          batteryPercent: 96,
          status: CylinderStatus.normal,
          recentReadings: _generateReadings(
            startPercent: 100,
            endPercent: 94,
            days: 3,
          ),
        );
    }
  }

  static List<WeightReading> _generateReadings({
    required double startPercent,
    required double endPercent,
    required int days,
  }) {
    final now = DateTime.now();
    final count = days * 4; // ~4 readings per day (every 6 hours)
    final readings = <WeightReading>[];

    for (int i = 0; i < count; i++) {
      final fraction = i / (count - 1);
      final pct = startPercent - (startPercent - endPercent) * fraction;
      // Add slight noise for realism
      final noise = (i.hashCode % 5) - 2;
      final finalPct = (pct + noise).clamp(0, 100).toDouble();
      final gasGrams = (finalPct / 100 * 12500).round();
      final readAt = now.subtract(Duration(hours: (count - 1 - i) * 6));

      readings.add(WeightReading(
        id: 'demo-reading-$i',
        rawWeightGrams: gasGrams + 15000,
        gasRemainingGrams: gasGrams,
        gasRemainingPercent: finalPct,
        batteryPercent: 90 - (i * 0.3).round(),
        readAt: readAt,
        receivedAt: readAt.add(const Duration(seconds: 30)),
      ));
    }

    return readings;
  }

  static List<Alert> alerts = [
    Alert(
      id: 'demo-alert-1',
      cylinderId: 'demo-cyl-3',
      siteId: 'demo-site-2',
      alertType: AlertType.criticalGas,
      message: 'Generator is critically low at 10%',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Alert(
      id: 'demo-alert-2',
      cylinderId: 'demo-cyl-3',
      siteId: 'demo-site-2',
      alertType: AlertType.batteryLow,
      message: 'Generator scale battery is at 15%',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Alert(
      id: 'demo-alert-3',
      cylinderId: 'demo-cyl-2',
      siteId: 'demo-site-1',
      alertType: AlertType.lowGas,
      message: 'Backup Cylinder is running low at 30%',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    Alert(
      id: 'demo-alert-4',
      siteId: 'demo-site-2',
      alertType: AlertType.gatewayOffline,
      message: 'Office Gateway has been offline for 3 hours',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Alert(
      id: 'demo-alert-5',
      cylinderId: 'demo-cyl-1',
      siteId: 'demo-site-1',
      alertType: AlertType.lowGas,
      message: 'Kitchen Gas dropped below 80%',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}
