import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/liquid_cylinder.dart';

class BleTab extends StatelessWidget {
  const BleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleProvider>();
    final devices = ble.deviceList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cylinders', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Scale'),
      ),
      body: devices.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.propane_tank_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No cylinders yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a GasPulse scale to start\nmonitoring your gas cylinders',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/scan'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Scale'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(180, 44)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                final hasCylType = device.cylinderType != null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push('/bluetooth/${device.deviceId}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          LiquidCylinder(
                            fillPercent: device.gasRemainingPercent,
                            width: 50,
                            height: 72,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.displayName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                if (hasCylType)
                                  Text(
                                    device.cylinderType!.name,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      device.connected
                                          ? Icons.bluetooth_connected
                                          : Icons.bluetooth_disabled,
                                      size: 14,
                                      color: device.connected ? Colors.blue : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      device.connected ? 'Connected' : 'Disconnected',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: device.connected ? Colors.blue : Colors.grey.shade500,
                                      ),
                                    ),
                                    if (device.connected && device.batteryPercent > 0) ...[
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.battery_std,
                                        size: 14,
                                        color: device.batteryPercent > 20 ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${device.batteryPercent}%',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ],
                                ),
                                if (device.cylinderLifted) ...[
                                  const SizedBox(height: 4),
                                  const Row(
                                    children: [
                                      Icon(Icons.warning_amber, size: 14, color: Colors.red),
                                      SizedBox(width: 4),
                                      Text(
                                        'Cylinder lifted!',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                hasCylType
                                    ? '${device.gasRemainingPercent?.toStringAsFixed(0) ?? "--"}%'
                                    : device.connected
                                        ? '${device.rawWeightKg.toStringAsFixed(1)} kg'
                                        : '--',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: hasCylType
                                      ? AppColors.gasColor(device.gasRemainingPercent)
                                      : AppColors.primaryDark,
                                ),
                              ),
                              if (hasCylType && device.gasRemainingKg != null)
                                Text(
                                  '${device.gasRemainingKg!.toStringAsFixed(1)} kg',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}