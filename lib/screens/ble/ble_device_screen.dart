import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cylinder_type.dart';
import '../../providers/ble_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/liquid_cylinder.dart';

class BleDeviceScreen extends StatefulWidget {
  final String deviceId;
  const BleDeviceScreen({super.key, required this.deviceId});

  @override
  State<BleDeviceScreen> createState() => _BleDeviceScreenState();
}

class _BleDeviceScreenState extends State<BleDeviceScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleProvider>();
    final device = ble.devices[widget.deviceId];

    if (device == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scale')),
        body: const Center(child: Text('Device not found or out of range')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(device.displayName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Large cylinder visualization ──
            Center(
              child: LiquidCylinder(
                fillPercent: device.gasRemainingPercent,
                width: 160,
                height: 240,
                label: device.gasRemainingPercent != null
                    ? '${device.gasRemainingPercent!.toStringAsFixed(1)}%'
                    : '${device.rawWeightKg.toStringAsFixed(2)} kg',
                subtitle: device.gasRemainingKg != null
                    ? '${device.gasRemainingKg!.toStringAsFixed(2)} kg gas remaining'
                    : 'Configure cylinder type for gas %',
              ),
            ),
            const SizedBox(height: 32),

            // ── Info cards ──
            Row(
              children: [
                _InfoCard(
                  icon: Icons.scale,
                  label: 'Raw Weight',
                  value: '${device.rawWeightKg.toStringAsFixed(2)} kg',
                ),
                const SizedBox(width: 12),
                _InfoCard(
                  icon: Icons.battery_std,
                  label: 'Battery',
                  value: '${device.batteryPercent}%',
                  valueColor: device.batteryPercent > 20 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                _InfoCard(
                  icon: Icons.signal_cellular_alt,
                  label: 'Signal',
                  value: '${device.rssi} dBm',
                  valueColor: device.rssi > -70 ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Configuration ──
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Configuration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),

            // Friendly name
            TextField(
              controller: _nameCtrl..text = device.friendlyName ?? '',
              decoration: InputDecoration(
                labelText: 'Name this scale',
                hintText: 'e.g. Kitchen Gas',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    context.read<BleProvider>().configureDevice(
                          widget.deviceId,
                          friendlyName: _nameCtrl.text.trim(),
                          cylinderType: device.cylinderType,
                        );
                    FocusScope.of(context).unfocus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name saved')),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cylinder type selector
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Cylinder Type', style: TextStyle(fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 8),
            ...CylinderType.defaults.map((type) {
              final isSelected = device.cylinderType?.id == type.id;
              return Card(
                color: isSelected ? AppColors.primary.withAlpha(20) : null,
                child: ListTile(
                  leading: Icon(
                    Icons.propane_tank,
                    color: isSelected ? AppColors.primary : Colors.grey,
                  ),
                  title: Text(type.name),
                  subtitle: Text(
                    'Gas: ${type.fullGasWeightKg} kg  |  Tare: ${type.tareWeightKg} kg',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    context.read<BleProvider>().configureDevice(
                          widget.deviceId,
                          friendlyName: device.friendlyName,
                          cylinderType: type,
                        );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade600),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
