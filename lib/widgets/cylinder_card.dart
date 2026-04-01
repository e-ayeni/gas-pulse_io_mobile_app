import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/cylinder.dart';
import '../theme/app_theme.dart';
import 'liquid_cylinder.dart';
import 'status_badge.dart';

class CylinderCard extends StatelessWidget {
  final CylinderSummary cylinder;
  final VoidCallback? onTap;

  const CylinderCard({super.key, required this.cylinder, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = cylinder.gasRemainingPercent;
    final color = AppColors.gasColor(pct);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              LiquidCylinder(
                fillPercent: pct,
                width: 56,
                height: 80,
                animate: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cylinder.friendlyName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    if (cylinder.cylinderTypeName != null)
                      Text(
                        cylinder.cylinderTypeName!,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusBadge(status: cylinder.status),
                        const SizedBox(width: 8),
                        if (cylinder.batteryPercent != null)
                          _BatteryIndicator(percent: cylinder.batteryPercent!),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    pct != null ? '${pct.toStringAsFixed(0)}%' : '--',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (cylinder.gasRemainingKg != null)
                    Text(
                      '${cylinder.gasRemainingKg!.toStringAsFixed(1)} kg',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  if (cylinder.lastReadingAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(cylinder.lastReadingAt!),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatteryIndicator extends StatelessWidget {
  final int percent;
  const _BatteryIndicator({required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = percent > 20 ? Colors.green : Colors.red;
    final icon = percent > 75
        ? Icons.battery_full
        : percent > 50
            ? Icons.battery_5_bar
            : percent > 20
                ? Icons.battery_3_bar
                : Icons.battery_1_bar;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 2),
        Text('$percent%', style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
