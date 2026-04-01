import 'dart:async';
import 'package:flutter/foundation.dart';
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

  BleProvider(this._ble, this._storage) {
    _sub = _ble.devicesStream.listen((devices) {
      _devices = devices;
      notifyListeners();
    });
    // Eagerly load demo data if BLE is unavailable (e.g. simulator)
    _initDemoIfNeeded();
  }

  Future<void> _initDemoIfNeeded() async {
    try {
      final isAvailable = await _ble.isAvailable;
      if (!isAvailable) loadDemoData();
    } catch (_) {
      // BLE not supported (e.g. simulator) — show demo data
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
      'GP-AA:BB:CC:01': BleScaleDevice(
        deviceId: 'GP-AA:BB:CC:01',
        localName: 'GP-Scale-01',
        rawWeightGrams: 24200, // 15000 tare + 9200 gas = 73.6%
        batteryPercent: 87,
        rssi: -52,
        lastSeen: DateTime.now(),
        friendlyName: 'Kitchen Gas',
        cylinderType: std,
      ),
      'GP-AA:BB:CC:02': BleScaleDevice(
        deviceId: 'GP-AA:BB:CC:02',
        localName: 'GP-Scale-02',
        rawWeightGrams: 6100, // 5200 tare + 900 gas = 30%
        batteryPercent: 42,
        rssi: -68,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
        friendlyName: 'Backup Cylinder',
        cylinderType: mini,
      ),
      'GP-AA:BB:CC:03': BleScaleDevice(
        deviceId: 'GP-AA:BB:CC:03',
        localName: 'GP-Scale-03',
        rawWeightGrams: 8100, // 7500 tare + 600 gas = 10%
        batteryPercent: 15,
        rssi: -75,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 12)),
        friendlyName: 'Generator',
        cylinderType: camp,
      ),
      'GP-AA:BB:CC:04': BleScaleDevice(
        deviceId: 'GP-AA:BB:CC:04',
        localName: 'GP-Scale-04',
        rawWeightGrams: 45500, // 22000 tare + 23500 gas = 94%
        batteryPercent: 96,
        rssi: -45,
        lastSeen: DateTime.now(),
        friendlyName: 'Workshop Tank',
        cylinderType: med,
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
