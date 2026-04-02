import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_provider.dart';
import '../../theme/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BleProvider>().startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleProvider>();

    // Show devices not yet connected (or all if demo)
    final discoveredDevices = ble.useDemoData
        ? ble.deviceList
        : ble.deviceList.where((d) => !d.connected).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Scale', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (ble.scanning)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ble.startScan(),
            ),
        ],
      ),
      body: discoveredDevices.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    ble.scanning
                        ? 'Scanning for GasPulse scales...'
                        : 'No new scales found',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Make sure your GasPulse scale is\npowered on and nearby',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                  if (!ble.scanning) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => ble.startScan(),
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Scan Again'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(180, 44)),
                    ),
                  ],
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: discoveredDevices.length,
              itemBuilder: (context, index) {
                final device = discoveredDevices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.scale, color: AppColors.primary),
                    ),
                    title: Text(
                      device.localName ?? device.deviceId,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${device.deviceId}  |  ${device.rssi} dBm',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () async {
                      if (!ble.useDemoData) {
                        await ble.connectDevice(device.deviceId);
                      }
                      if (context.mounted) {
                        context.push('/bluetooth/${device.deviceId}');
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}