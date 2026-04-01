import 'package:flutter/foundation.dart';
import '../config/demo_data.dart';
import '../models/alert.dart';
import '../services/api_service.dart';

class AlertProvider extends ChangeNotifier {
  final ApiService _api;

  List<Alert> _alerts = [];
  bool _loading = false;
  String? _error;

  AlertProvider(this._api);

  List<Alert> get alerts => _alerts;
  List<Alert> get unreadAlerts => _alerts.where((a) => !a.isRead).toList();
  int get unreadCount => unreadAlerts.length;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadSiteAlerts(String siteId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _alerts = await _api.getSiteAlerts(siteId);
      _loading = false;
      notifyListeners();
    } catch (e) {
      // Fall back to demo data
      _alerts = DemoData.alerts.where((a) => a.siteId == siteId).toList();
      if (_alerts.isEmpty) _alerts = DemoData.alerts;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCylinderAlerts(String cylinderId) async {
    _loading = true;
    notifyListeners();

    try {
      _alerts = await _api.getCylinderAlerts(cylinderId);
      _loading = false;
      notifyListeners();
    } catch (e) {
      _alerts = DemoData.alerts.where((a) => a.cylinderId == cylinderId).toList();
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String alertId) async {
    try {
      await _api.markAlertRead(alertId);
    } catch (_) {}

    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) {
      _alerts[idx] = Alert(
        id: _alerts[idx].id,
        cylinderId: _alerts[idx].cylinderId,
        siteId: _alerts[idx].siteId,
        alertType: _alerts[idx].alertType,
        message: _alerts[idx].message,
        isRead: true,
        createdAt: _alerts[idx].createdAt,
      );
      notifyListeners();
    }
  }
}
