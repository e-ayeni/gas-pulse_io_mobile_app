import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/alert.dart';
import '../models/ble_device.dart';
import '../models/cylinder_type.dart';
import '../services/ble_service.dart';
import '../services/local_storage_service.dart';

class BleProvider extends ChangeNotifier {
  final BleService _ble;
  final LocalStorageService _storage;

  Map<String, BleScaleDevice> _devices = {};
  bool _scanning = false;
  StreamSubscription? _sub;
  bool _useDemoData = false;
  // Tracks which alert conditions are currently active to avoid re-firing
  final Set<String> _firedAlerts = {};

  BleProvider(this._ble, this._storage) {
    _sub = _ble.devicesStream.listen(_mergeDevices);
    _initDemoIfNeeded();
  }

  /// Merge incoming service data with locally-set config (name, cylinder type).
  void _mergeDevices(Map<String, BleScaleDevice> incoming) {
    for (final entry in incoming.entries) {
      final existing = _devices[entry.key];
      if (existing != null) {
        _devices[entry.key] = entry.value.copyWith(
          friendlyName: existing.friendlyName,
          cylinderType: existing.cylinderType,
        );
      } else {
        _devices[entry.key] = entry.value;
      }
    }
    _devices.removeWhere((key, _) => !incoming.containsKey(key));
    _recordDailySnapshot();
    _checkAlerts();
    notifyListeners();
  }

  void _recordDailySnapshot() {
    final totalKg = _devices.values
        .where((d) => d.gasRemainingKg != null)
        .fold(0.0, (sum, d) => sum + d.gasRemainingKg!);
    if (totalKg == 0) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    _storage.saveDailySnapshot(LocalDailySnapshot(date: today, totalGasKg: totalKg));
  }

  void _checkAlerts() {
    for (final device in _devices.values) {
      final pct = device.gasRemainingPercent;

      // Critical gas (≤ 10%)
      final critKey = '${device.deviceId}:critical';
      if (pct != null && pct <= 10 && !_firedAlerts.contains(critKey)) {
        _firedAlerts.add(critKey);
        _storage.saveLocalAlert(Alert(
          id: '${device.deviceId}-crit-${DateTime.now().millisecondsSinceEpoch}',
          cylinderId: device.deviceId,
          alertType: AlertType.criticalGas,
          message: '${device.displayName} is critically low at ${pct.toStringAsFixed(0)}%',
          isRead: false,
          createdAt: DateTime.now(),
        ));
      } else if (pct != null && pct > 15) {
        _firedAlerts.remove(critKey);
      }

      // Low gas (≤ 20%, above critical)
      final lowKey = '${device.deviceId}:low';
      if (pct != null && pct <= 20 && pct > 10 && !_firedAlerts.contains(lowKey)) {
        _firedAlerts.add(lowKey);
        _storage.saveLocalAlert(Alert(
          id: '${device.deviceId}-low-${DateTime.now().millisecondsSinceEpoch}',
          cylinderId: device.deviceId,
          alertType: AlertType.lowGas,
          message: '${device.displayName} is running low at ${pct.toStringAsFixed(0)}%',
          isRead: false,
          createdAt: DateTime.now(),
        ));
      } else if (pct != null && pct > 25) {
        _firedAlerts.remove(lowKey);
      }

      // Low battery (≤ 15%)
      final battKey = '${device.deviceId}:battery';
      if (device.batteryPercent > 0 &&
          device.batteryPercent <= 15 &&
          !_firedAlerts.contains(battKey)) {
        _firedAlerts.add(battKey);
        _storage.saveLocalAlert(Alert(
          id: '${device.deviceId}-batt-${DateTime.now().millisecondsSinceEpoch}',
          cylinderId: device.deviceId,
          alertType: AlertType.batteryLow,
          message: '${device.displayName} scale battery is at ${device.batteryPercent}%',
          isRead: false,
          createdAt: DateTime.now(),
        ));
      } else if (device.batteryPercent > 20) {
        _firedAlerts.remove(battKey);
      }
    }
  }

  List<Alert> get localAlerts => _storage.getLocalAlerts();

  void markLocalAlertRead(String alertId) {
    _storage.markLocalAlertRead(alertId);
    notifyListeners();
  }

  Future<void> _initDemoIfNeeded() async {
    try {
      final isAvailable = await _ble.isAvailable;
      if (!isAvailable) loadDemoData();
    } catch (_) {
      loadDemoData();
    }
  }

  Map<String, BleScaleDevice> get devices => _devices;
  List<BleScaleDevice> get deviceList => _devices.values.toList();
  bool get scanning => _scanning;
  bool get useDemoData => _useDemoData;

  void loadDemoData() {
    final std = CylinderType.defaults[2]; // 12.5kg Standard
    final mini = CylinderType.defaults[0]; // 3kg Mini
    final camp = CylinderType.defaults[1]; // 6kg Camping
    final med = CylinderType.defaults[3]; // 25kg Medium

    _devices = {
      'GasPulse_A1B2C3': BleScaleDevice(
        deviceId: 'GasPulse_A1B2C3',
        localName: 'GasPulse_A1B2C3',
        rawWeightGrams: 24200, // 15000 tare + 9200 gas = 73.6%
        batteryPercent: 87,
        rssi: -52,
        lastSeen: DateTime.now(),
        friendlyName: 'Kitchen Gas',
        cylinderType: std,
        connected: true,
      ),
      'GasPulse_D4E5F6': BleScaleDevice(
        deviceId: 'GasPulse_D4E5F6',
        localName: 'GasPulse_D4E5F6',
        rawWeightGrams: 6100, // 5200 tare + 900 gas = 30%
        batteryPercent: 42,
        rssi: -68,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
        friendlyName: 'Backup Cylinder',
        cylinderType: mini,
        connected: true,
      ),
      'GasPulse_G7H8I9': BleScaleDevice(
        deviceId: 'GasPulse_G7H8I9',
        localName: 'GasPulse_G7H8I9',
        rawWeightGrams: 8100, // 7500 tare + 600 gas = 10%
        batteryPercent: 15,
        rssi: -75,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 12)),
        friendlyName: 'Generator',
        cylinderType: camp,
        connected: true,
      ),
      'GasPulse_J0K1L2': BleScaleDevice(
        deviceId: 'GasPulse_J0K1L2',
        localName: 'GasPulse_J0K1L2',
        rawWeightGrams: 45500, // 22000 tare + 23500 gas = 94%
        batteryPercent: 96,
        rssi: -45,
        lastSeen: DateTime.now(),
        friendlyName: 'Workshop Tank',
        cylinderType: med,
        connected: true,
      ),
    };
    _useDemoData = true;
    notifyListeners();
  }

  Future<void> startScan() async {
    _scanning = true;
    notifyListeners();

    try {
      final isAvailable = await _ble.isAvailable;
      if (!isAvailable && !_useDemoData) {
        loadDemoData();
        _scanning = false;
        notifyListeners();
        return;
      }
      if (isAvailable) {
        await _ble.startScan();
      }
    } catch (_) {
      if (!_useDemoData) loadDemoData();
    }

    _scanning = false;
    notifyListeners();
  }

  Future<void> stopScan() async {
    await _ble.stopScan();
    _scanning = false;
    notifyListeners();
  }

  /// Connect to a discovered GasPulse scale
  Future<void> connectDevice(String deviceId) async {
    if (_useDemoData) return;
    await _ble.connectToDevice(deviceId);
  }

  /// Disconnect from a scale
  Future<void> disconnectDevice(String deviceId) async {
    if (_useDemoData) return;
    await _ble.disconnectDevice(deviceId);
  }

  /// Tare (re-zero) the scale. Must be empty.
  Future<bool> tare(String deviceId) async {
    if (_useDemoData) return true;
    return _ble.tare(deviceId);
  }

  /// Calibrate with a known reference weight in grams.
  Future<bool> calibrate(String deviceId, double knownWeightGrams) async {
    if (_useDemoData) return true;
    return _ble.calibrate(deviceId, knownWeightGrams);
  }

  Future<void> configureDevice(
    String deviceId, {
    String? friendlyName,
    CylinderType? cylinderType,
  }) async {
    final config = LocalScaleConfig(
      deviceId: deviceId,
      friendlyName: friendlyName,
      cylinderTypeId: cylinderType?.id,
    );
    await _storage.saveScaleConfig(config);

    if (_devices.containsKey(deviceId)) {
      _devices[deviceId] = _devices[deviceId]!.copyWith(
        friendlyName: friendlyName,
        cylinderType: cylinderType,
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ble.dispose();
    super.dispose();
  }
}
