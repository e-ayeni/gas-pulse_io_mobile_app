import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/alert.dart';
import '../../providers/alert_provider.dart';
import '../../providers/site_provider.dart';
import '../../theme/app_theme.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  void _loadAlerts() {
    final sites = context.read<SiteProvider>().sites;
    // Load alerts for first site, or use 'demo-site-1' which triggers demo fallback
    final siteId = sites.isNotEmpty ? sites.first.id : 'demo-site-1';
    context.read<AlertProvider>().loadSiteAlerts(siteId);
  }

  @override
  Widget build(BuildContext context) {
    final alertProv = context.watch<AlertProvider>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            if (alertProv.unreadCount > 0)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${alertProv.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        if (alertProv.loading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
        else if (alertProv.alerts.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No alerts', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final alert = alertProv.alerts[index];
                return _AlertTile(
                  alert: alert,
                  onTap: () {
                    if (!alert.isRead) {
                      alertProv.markRead(alert.id);
                    }
                  },
                );
              },
              childCount: alertProv.alerts.length,
            ),
          ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final Alert alert;
  final VoidCallback onTap;

  const _AlertTile({required this.alert, required this.onTap});

  (IconData, Color) get _iconAndColor {
    switch (alert.alertType) {
      case AlertType.lowGas:
        return (Icons.propane_tank, AppColors.gasMedium);
      case AlertType.criticalGas:
        return (Icons.warning_amber, AppColors.gasCritical);
      case AlertType.cylinderRemoved:
        return (Icons.remove_circle_outline, AppColors.gasEmpty);
      case AlertType.batteryLow:
        return (Icons.battery_alert, Colors.orange);
      case AlertType.gatewayOffline:
        return (Icons.cloud_off, Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: alert.isRead ? null : color.withAlpha(10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          alert.message,
          style: TextStyle(
            fontSize: 14,
            fontWeight: alert.isRead ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          timeago.format(alert.createdAt),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: alert.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
        onTap: onTap,
      ),
    );
  }
}
