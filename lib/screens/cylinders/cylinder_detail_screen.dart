import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/cylinder_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/liquid_cylinder.dart';
import '../../widgets/reading_chart.dart';
import '../../widgets/status_badge.dart';

class CylinderDetailScreen extends StatefulWidget {
  final String siteId;
  final String cylinderId;

  const CylinderDetailScreen({
    super.key,
    required this.siteId,
    required this.cylinderId,
  });

  @override
  State<CylinderDetailScreen> createState() => _CylinderDetailScreenState();
}

class _CylinderDetailScreenState extends State<CylinderDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CylinderProvider>().loadCylinderDetail(widget.siteId, widget.cylinderId);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CylinderProvider>();
    final detail = prov.detail;

    return Scaffold(
      appBar: AppBar(
        title: Text(detail?.friendlyName ?? 'Cylinder'),
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? const Center(child: Text('Failed to load cylinder'))
              : RefreshIndicator(
                  onRefresh: () => prov.loadCylinderDetail(widget.siteId, widget.cylinderId),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // ── Hero cylinder ──
                        Center(
                          child: LiquidCylinder(
                            fillPercent: detail.gasRemainingPercent,
                            width: 160,
                            height: 240,
                            label: detail.gasRemainingPercent != null
                                ? '${detail.gasRemainingPercent!.toStringAsFixed(1)}%'
                                : '--',
                            subtitle: detail.gasRemainingKg != null
                                ? '${detail.gasRemainingKg!.toStringAsFixed(2)} kg remaining'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Status row ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StatusBadge(status: detail.status),
                            if (detail.cylinderTypeName != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  detail.cylinderTypeName!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Stats grid ──
                        Row(
                          children: [
                            _StatCard(
                              icon: Icons.timer_outlined,
                              label: 'Est. Days Left',
                              value: detail.estimatedDaysRemaining?.toString() ?? '--',
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              icon: Icons.battery_std,
                              label: 'Battery',
                              value: detail.batteryPercent != null ? '${detail.batteryPercent}%' : '--',
                              valueColor: (detail.batteryPercent ?? 100) > 20 ? null : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              icon: Icons.access_time,
                              label: 'Last Reading',
                              value: detail.lastReadingAt != null
                                  ? timeago.format(detail.lastReadingAt!)
                                  : 'Never',
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Chart ──
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Gas Level History',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                            child: ReadingChart(readings: detail.recentReadings),
                          ),
                        ),

                        // ── Scale info ──
                        if (detail.scaleDeviceId != null) ...[
                          const SizedBox(height: 24),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.bluetooth_connected, color: Colors.blue),
                              title: const Text('Paired Scale'),
                              subtitle: Text(
                                detail.scaleDeviceId!,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
