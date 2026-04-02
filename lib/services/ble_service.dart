import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/ble_device.dart';
import '../models/cylinder_type.dart';
import 'local_storage_service.dart';

/// UUIDs matching the ESP32 firmware
class GasPulseUuids {
  // Custom GasPulse service: 0000aa00-7890-1234-5678-aabbccddeeff
  static final Guid service = Guid('0000aa00-7890-1234-5678-aabbccddeeff');
  // Weight characteristic: float LE (grams), read + notify
  static final Guid weight = Guid('0000aa01-7890-1234-5678-aabbccddeeff');
  // Alert characteristic: uint8 (1 = cylinder lifted), read + notify
  static final Guid alert = Guid('0000aa02-7890-1234-5678-aabbccddeeff');
  // Calibration characteristic: write float LE (grams). 0.0 = tare only.
  static final Guid calibration = Guid('0000aa03-7890-1234-5678-aabbccddeeff');
  // Standard Battery Service
  static final Guid batteryService = Guid('0000180f-0000-1000-8000-00805f9b34fb');
  // Standard Battery Level characteristic
  static final Guid batteryLevel = Guid('00002a19-0000-1000-8000-00805f9b34fb');
}

class BleService {
  final LocalStorageService _storage;

  final _devicesController = StreamController<Map<String, BleScaleDevice>>.broadcast();
  final Map<String, BleScaleDevice> _discoveredDevices = {};
  final Map<String, BluetoothDevice> _btDevices = {};
  final Map<String, List<StreamSubscription>> _subscriptions = {};
  final Map<String, BluetoothCharacteristic> _calChars = {};

  bool _isScanning = false;

  BleService(this._storage);

  Stream<Map<String, BleScaleDevice>> get devicesStream => _devicesController.stream;
  Map<String, BleScaleDevice> get discoveredDevices => Map.unmodifiable(_discoveredDevices);
  bool get isScanning => _isScanning;

  Future<bool> get isAvailable async {
    try {
      return await FlutterBluePlus.isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      return statuses.values.every((s) => s.isGranted);
    }
    if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }
    return true;
  }

  Future<void> startScan() async {
    if (_isScanning) return;

    final supported = await FlutterBluePlus.isSupported;
    if (!supported) {
      debugPrint('BLE not supported on this device');
      return;
    }

    final granted = await _requestPermissions();
    if (!granted) {
      debugPrint('BLE permissions not granted');
      return;
    }

    // Wait for adapter to be on
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      debugPrint('Bluetooth adapter is off');
      return;
    }

    _isScanning = true;

    // Listen for scan results — filter by "GasPulse_" name prefix
    final scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        final name = result.advertisementData.advName;
        if (name.startsWith('GasPulse_')) {
          _onDeviceDiscovered(result);
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: true,
    );

    scanSub.cancel();
    _isScanning = false;
  }

  void _onDeviceDiscovered(ScanResult result) {
    final id = result.device.remoteId.str;
    final name = result.advertisementData.advName;

    // Load saved config
    final config = _storage.getScaleConfig(id);
    CylinderType? cylType;
    if (config?.cylinderTypeId != null) {
      try {
        cylType = CylinderType.defaults.firstWhere((t) => t.id == config!.cylinderTypeId);
      } catch (_) {}
    }

    // Add/update discovered device (not yet connected)
    final existing = _discoveredDevices[id];
    _discoveredDevices[id] = BleScaleDevice(
      deviceId: id,
      localName: name,
      rawWeightGrams: existing?.rawWeightGrams ?? 0,
      batteryPercent: existing?.batteryPercent ?? 0,
      rssi: result.rssi,
      lastSeen: DateTime.now(),
      friendlyName: config?.friendlyName ?? existing?.friendlyName,
      cylinderType: cylType ?? existing?.cylinderType,
      connected: existing?.connected ?? false,
      cylinderLifted: existing?.cylinderLifted ?? false,
    );
    _btDevices[id] = result.device;

    _devicesController.add(Map.from(_discoveredDevices));
  }

  /// Connect to a GasPulse device and subscribe to weight, alert, and battery notifications.
  Future<void> connectToDevice(String deviceId) async {
    final btDevice = _btDevices[deviceId];
    if (btDevice == null) return;

    try {
      await btDevice.connect(autoConnect: false, timeout: const Duration(seconds: 10));

      _updateDevice(deviceId, (d) => d.copyWith(connected: true));

      final services = await btDevice.discoverServices();
      final subs = <StreamSubscription>[];

      for (final service in services) {
        // GasPulse custom service
        if (service.uuid == GasPulseUuids.service) {
          for (final char in service.characteristics) {
            if (char.uuid == GasPulseUuids.weight && char.properties.notify) {
              await char.setNotifyValue(true);
              subs.add(char.lastValueStream.listen((value) {
                if (value.length >= 4) {
                  final bytes = ByteData.sublistView(Uint8List.fromList(value));
                  final grams = bytes.getFloat32(0, Endian.little);
                  _updateDevice(deviceId, (d) => d.copyWith(
                    rawWeightGrams: grams.toDouble(),
                    lastSeen: DateTime.now(),
                  ));
                }
              }));
            }
            if (char.uuid == GasPulseUuids.calibration && char.properties.write) {
              _calChars[deviceId] = char;
            }
            if (char.uuid == GasPulseUuids.alert && char.properties.notify) {
              await char.setNotifyValue(true);
              subs.add(char.lastValueStream.listen((value) {
                if (value.isNotEmpty && value[0] == 1) {
                  _updateDevice(deviceId, (d) => d.copyWith(cylinderLifted: true));
                  // Reset after 5 seconds
                  Future.delayed(const Duration(seconds: 5), () {
                    _updateDevice(deviceId, (d) => d.copyWith(cylinderLifted: false));
                  });
                }
              }));
            }
          }
        }

        // Standard Battery Service (0x180F)
        if (service.uuid == GasPulseUuids.batteryService) {
          for (final char in service.characteristics) {
            if (char.uuid == GasPulseUuids.batteryLevel && char.properties.notify) {
              await char.setNotifyValue(true);
              subs.add(char.lastValueStream.listen((value) {
                if (value.isNotEmpty) {
                  _updateDevice(deviceId, (d) => d.copyWith(batteryPercent: value[0]));
                }
              }));
            }
            // Also do an initial read
            if (char.uuid == GasPulseUuids.batteryLevel && char.properties.read) {
              final value = await char.read();
              if (value.isNotEmpty) {
                _updateDevice(deviceId, (d) => d.copyWith(batteryPercent: value[0]));
              }
            }
          }
        }
      }

      _subscriptions[deviceId] = subs;

      // Listen for disconnection
      btDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _onDeviceDisconnected(deviceId);
        }
      });
    } catch (e) {
      debugPrint('Failed to connect to $deviceId: $e');
      _updateDevice(deviceId, (d) => d.copyWith(connected: false));
    }
  }

  void _onDeviceDisconnected(String deviceId) {
    for (final sub in _subscriptions[deviceId] ?? []) {
      sub.cancel();
    }
    _subscriptions.remove(deviceId);
    _calChars.remove(deviceId);
    _updateDevice(deviceId, (d) => d.copyWith(connected: false));
  }

  Future<void> disconnectDevice(String deviceId) async {
    final btDevice = _btDevices[deviceId];
    if (btDevice == null) return;
    await btDevice.disconnect();
  }

  /// Send tare command (re-zero the scale). Scale must be empty.
  Future<bool> tare(String deviceId) async {
    return _writeCalibration(deviceId, 0.0);
  }

  /// Send calibrate command with a known reference weight in grams.
  Future<bool> calibrate(String deviceId, double knownWeightGrams) async {
    return _writeCalibration(deviceId, knownWeightGrams);
  }

  Future<bool> _writeCalibration(String deviceId, double grams) async {
    final char = _calChars[deviceId];
    if (char == null) {
      debugPrint('Calibration characteristic not found for $deviceId');
      return false;
    }
    try {
      final bytes = ByteData(4)..setFloat32(0, grams, Endian.little);
      await char.write(bytes.buffer.asUint8List(), withoutResponse: false);
      return true;
    } catch (e) {
      debugPrint('Failed to write calibration: $e');
      return false;
    }
  }

  void _updateDevice(String deviceId, BleScaleDevice Function(BleScaleDevice) updater) {
    final device = _discoveredDevices[deviceId];
    if (device == null) return;
    _discoveredDevices[deviceId] = updater(device);
    _devicesController.add(Map.from(_discoveredDevices));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
  }

  void dispose() {
    for (final subs in _subscriptions.values) {
      for (final sub in subs) {
        sub.cancel();
      }
    }
    _subscriptions.clear();
    // Disconnect all
    for (final device in _btDevices.values) {
      device.disconnect();
    }
    _devicesController.close();
  }
}
