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
  final _calWeightCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ble = context.read<BleProvider>();
      final device = ble.devices[widget.deviceId];
      if (device != null) {
        // Initialize name controller once
        _nameCtrl.text = device.friendlyName ?? '';
        // Auto-connect if not already connected
        if (!device.connected && !ble.useDemoData) {
          ble.connectDevice(widget.deviceId);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calWeightCtrl.dispose();
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
        actions: [
          if (!ble.useDemoData)
            TextButton.icon(
              onPressed: () {
                if (device.connected) {
                  ble.disconnectDevice(widget.deviceId);
                } else {
                  ble.connectDevice(widget.deviceId);
                }
              },
              icon: Icon(
                device.connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                size: 18,
              ),
              label: Text(device.connected ? 'Disconnect' : 'Connect'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Cylinder lifted alert banner
            if (device.cylinderLifted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cylinder has been lifted off the scale!',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Connection status
            if (!device.connected && !ble.useDemoData)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bluetooth_disabled, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Not connected — weight data may be stale',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Weight sanity warning — only when type is set and reading is below tare
            if (device.cylinderType != null &&
                device.rawWeightGrams > 0 &&
                device.rawWeightGrams < device.cylinderType!.tareWeightGrams)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Reading looks wrong. ',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                              text:
                                  'Scale reads ${device.rawWeightKg.toStringAsFixed(2)} kg but a '
                                  '${device.cylinderType!.name} empty cylinder weighs '
                                  '${device.cylinderType!.tareWeightKg.toStringAsFixed(1)} kg. '
                                  'Check the cylinder type is correct, or re-tare the scale.',
                            ),
                          ],
                        ),
                        style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),

            // Large cylinder visualization
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

            // Info cards
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

            // Configuration
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
              controller: _nameCtrl,
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

            // ── Scale Calibration ──
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Scale Calibration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tare resets the zero point (scale must be empty). '
              'Calibrate sets the scale factor using a known weight.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (device.cylinderType == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select a cylinder type above before calibrating.',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: device.connected && device.cylinderType != null
                          ? () async {
                              final ble = context.read<BleProvider>();
                              final messenger = ScaffoldMessenger.of(context);
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Tare Scale'),
                                  content: const Text(
                                    'Make sure the scale is completely empty, then tap Tare.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Tare'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                final ok = await ble.tare(widget.deviceId);
                                messenger.showSnackBar(
                                  SnackBar(content: Text(ok ? 'Tare successful' : 'Tare failed')),
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Tare (Zero)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _calWeightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Known weight (grams)',
                        hintText: 'e.g. 1000',
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: device.connected && device.cylinderType != null
                          ? () async {
                              final ble = context.read<BleProvider>();
                              final messenger = ScaffoldMessenger.of(context);
                              final grams = double.tryParse(_calWeightCtrl.text.trim());
                              if (grams == null || grams <= 0) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Enter a valid weight in grams')),
                                );
                                return;
                              }
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Calibrate Scale'),
                                  content: Text(
                                    'Place exactly ${grams.toStringAsFixed(0)}g on the scale, then tap Calibrate.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Calibrate'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                final ok = await ble.calibrate(widget.deviceId, grams);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(ok ? 'Calibration successful' : 'Calibration failed'),
                                  ),
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.tune),
                      label: const Text('Calibrate'),
                    ),
                    if (!device.connected || device.cylinderType == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          !device.connected
                              ? 'Connect to the scale to calibrate'
                              : 'Select a cylinder type to enable calibration',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
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
