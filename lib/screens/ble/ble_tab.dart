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

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Nearby Scales', style: TextStyle(fontWeight: FontWeight.bold)),
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
        if (ble.deviceList.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    ble.scanning ? 'Scanning...' : 'No scales found nearby',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  if (!ble.scanning) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ble.startScan(),
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Scan'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final device = ble.deviceList[index];
                final hasCylType = device.cylinderType != null;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                                Text(
                                  device.deviceId,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'monospace'),
                                ),
                                const SizedBox(height: 4),
                                if (!hasCylType)
                                  Text(
                                    'Tap to configure cylinder type',
                                    style: TextStyle(fontSize: 12, color: AppColors.accent, fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                hasCylType
                                    ? '${device.gasRemainingPercent?.toStringAsFixed(0) ?? "--"}%'
                                    : '${device.rawWeightKg.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: hasCylType
                                      ? AppColors.gasColor(device.gasRemainingPercent)
                                      : AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.signal_cellular_alt,
                                      size: 14,
                                      color: device.rssi > -70 ? Colors.green : Colors.orange),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.battery_std,
                                    size: 14,
                                    color: device.batteryPercent > 20 ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 2),
                                  Text('${device.batteryPercent}%',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: ble.deviceList.length,
            ),
          ),
      ],
    );
  }
}
