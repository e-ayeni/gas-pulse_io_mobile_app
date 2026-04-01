import 'package:flutter/material.dart';
import '../models/cylinder.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final CylinderStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      CylinderStatus.normal => ('Normal', AppColors.gasHigh),
      CylinderStatus.low => ('Low', AppColors.gasMedium),
      CylinderStatus.critical => ('Critical', AppColors.gasCritical),
      CylinderStatus.empty => ('Empty', AppColors.gasEmpty),
      CylinderStatus.noData => ('No Data', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
