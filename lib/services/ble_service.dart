import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ble_device.dart';
import '../models/cylinder_type.dart';
import 'local_storage_service.dart';

class BleService {
  final LocalStorageService _storage;

  final _devicesController = StreamController<Map<String, BleScaleDevice>>.broadcast();
  final Map<String, BleScaleDevice> _discoveredDevices = {};

  StreamSubscription? _scanSubscription;
  bool _isScanning = false;

  BleService(this._storage);

  Stream<Map<String, BleScaleDevice>> get devicesStream => _devicesController.stream;
  Map<String, BleScaleDevice> get discoveredDevices => Map.unmodifiable(_discoveredDevices);
  bool get isScanning => _isScanning;

  Future<bool> get isAvailable async => await FlutterBluePlus.isSupported;

  Future<void> startScan() async {
    if (_isScanning) return;

    final supported = await FlutterBluePlus.isSupported;
    if (!supported) {
      debugPrint('BLE not supported on this device');
      return;
    }

    _isScanning = true;

    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        _processResult(result);
      }
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 30),
      androidUsesFineLocation: true,
    );

    _isScanning = false;
  }

  void _processResult(ScanResult result) {
    final device = result.device;
    final advName = result.advertisementData.advName;

    // Filter for GasPulse scale devices by name prefix
    if (advName.isEmpty || !advName.startsWith('GP-')) return;

    // Parse manufacturer data from advertisement
    final mfgData = result.advertisementData.manufacturerData;
    int rawWeightGrams = 0;
    int batteryPercent = 0;

    if (mfgData.isNotEmpty) {
      // Manufacturer data format: [weightLow, weightHigh, weightUpper, battery]
      final data = mfgData.values.first;
      if (data.length >= 4) {
        rawWeightGrams = data[0] | (data[1] << 8) | (data[2] << 16);
        batteryPercent = data[3];
      }
    }

    // Load saved config for this device
    final config = _storage.getScaleConfig(device.remoteId.str);
    CylinderType? cylType;
    if (config?.cylinderTypeId != null) {
      try {
        cylType = CylinderType.defaults.firstWhere((t) => t.id == config!.cylinderTypeId);
      } catch (_) {}
    }

    _discoveredDevices[device.remoteId.str] = BleScaleDevice(
      deviceId: device.remoteId.str,
      localName: advName,
      rawWeightGrams: rawWeightGrams,
      batteryPercent: batteryPercent,
      rssi: result.rssi,
      lastSeen: DateTime.now(),
      friendlyName: config?.friendlyName,
      cylinderType: cylType,
    );

    _devicesController.add(Map.from(_discoveredDevices));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
  }

  void dispose() {
    _scanSubscription?.cancel();
    _devicesController.close();
  }
}
