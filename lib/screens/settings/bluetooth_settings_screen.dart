import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_provider.dart';
import '../../theme/app_theme.dart';

class BluetoothSettingsScreen extends StatefulWidget {
  const BluetoothSettingsScreen({super.key});

  @override
  State<BluetoothSettingsScreen> createState() => _BluetoothSettingsScreenState();
}

class _BluetoothSettingsScreenState extends State<BluetoothSettingsScreen> {
  bool _autoScan = true;
  int _scanDurationSec = 30;

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BleProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          Card(
            color: bt.scanning ? Colors.blue.shade50 : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    bt.scanning ? Icons.bluetooth_searching : Icons.bluetooth,
                    color: bt.scanning ? Colors.blue : Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bt.scanning ? 'Scanning...' : 'Bluetooth Ready',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${bt.deviceList.length} scale${bt.deviceList.length != 1 ? 's' : ''} found',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: bt.scanning ? () => bt.stopScan() : () => bt.startScan(),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 40),
                      backgroundColor: bt.scanning ? Colors.red : AppColors.primary,
                    ),
                    child: Text(bt.scanning ? 'Stop' : 'Scan Now'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Scanning options
          const Text('Scanning', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto-scan on app open'),
                  subtitle: const Text('Automatically search for nearby scales'),
                  value: _autoScan,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _autoScan = v),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  title: const Text('Scan duration'),
                  subtitle: Text('$_scanDurationSec seconds'),
                  trailing: SizedBox(
                    width: 160,
                    child: Slider(
                      value: _scanDurationSec.toDouble(),
                      min: 10,
                      max: 60,
                      divisions: 5,
                      label: '${_scanDurationSec}s',
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _scanDurationSec = v.round()),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Found devices
          const Text('Discovered Devices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (bt.deviceList.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No devices found. Tap "Scan Now" to search.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
            )
          else
            ...bt.deviceList.map((device) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: Icon(
                      Icons.bluetooth_connected,
                      color: device.rssi > -70 ? Colors.blue : Colors.grey,
                    ),
                    title: Text(device.displayName),
                    subtitle: Text(
                      '${device.deviceId}  |  ${device.rssi} dBm',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                    trailing: Text(
                      '${device.rawWeightKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
