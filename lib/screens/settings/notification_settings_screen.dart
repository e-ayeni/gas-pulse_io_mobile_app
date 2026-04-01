import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _lowGasAlert = true;
  bool _criticalGasAlert = true;
  bool _batteryLowAlert = true;
  bool _gatewayOfflineAlert = true;
  bool _cylinderRemovedAlert = true;
  bool _pushEnabled = true;
  int _lowGasThreshold = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Push notifications master toggle
          Card(
            child: SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive alerts on your device'),
              value: _pushEnabled,
              activeTrackColor: AppColors.primary,
              secondary: const Icon(Icons.notifications_active),
              onChanged: (v) => setState(() => _pushEnabled = v),
            ),
          ),
          const SizedBox(height: 20),

          // Alert types
          const Text('Alert Types', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Low Gas'),
                  subtitle: Text('When gas drops below $_lowGasThreshold%'),
                  value: _lowGasAlert,
                  activeTrackColor: AppColors.gasMedium,
                  secondary: const Icon(Icons.propane_tank, color: AppColors.gasMedium),
                  onChanged: _pushEnabled ? (v) => setState(() => _lowGasAlert = v) : null,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Critical Gas'),
                  subtitle: const Text('When gas drops below 10%'),
                  value: _criticalGasAlert,
                  activeTrackColor: AppColors.gasCritical,
                  secondary: const Icon(Icons.warning_amber, color: AppColors.gasCritical),
                  onChanged: _pushEnabled ? (v) => setState(() => _criticalGasAlert = v) : null,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Battery Low'),
                  subtitle: const Text('When scale battery drops below 15%'),
                  value: _batteryLowAlert,
                  activeTrackColor: Colors.orange,
                  secondary: const Icon(Icons.battery_alert, color: Colors.orange),
                  onChanged: _pushEnabled ? (v) => setState(() => _batteryLowAlert = v) : null,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Gateway Offline'),
                  subtitle: const Text('When a gateway loses connection'),
                  value: _gatewayOfflineAlert,
                  activeTrackColor: Colors.grey,
                  secondary: const Icon(Icons.cloud_off, color: Colors.grey),
                  onChanged: _pushEnabled ? (v) => setState(() => _gatewayOfflineAlert = v) : null,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Cylinder Removed'),
                  subtitle: const Text('When a cylinder is taken off the scale'),
                  value: _cylinderRemovedAlert,
                  activeTrackColor: AppColors.gasEmpty,
                  secondary: const Icon(Icons.remove_circle_outline, color: AppColors.gasEmpty),
                  onChanged: _pushEnabled ? (v) => setState(() => _cylinderRemovedAlert = v) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Low gas threshold
          const Text('Thresholds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Low Gas Alert Threshold: $_lowGasThreshold%',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You\'ll be notified when any cylinder drops below this level',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Slider(
                    value: _lowGasThreshold.toDouble(),
                    min: 10,
                    max: 50,
                    divisions: 8,
                    label: '$_lowGasThreshold%',
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _lowGasThreshold = v.round()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
