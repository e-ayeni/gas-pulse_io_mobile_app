import 'package:flutter/foundation.dart';
import '../config/demo_data.dart';
import '../models/analytics.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final ApiService _api;
  final LocalStorageService _storage;

  ConsumptionAnalytics? _analytics;
  List<CylinderAnomaly> _anomalies = [];
  bool _loading = false;
  String? _error;
  DateTime? _lastLoaded;

  AnalyticsProvider(this._api, this._storage);

  ConsumptionAnalytics? get analytics => _analytics;
  List<CylinderAnomaly> get anomalies => _anomalies;
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get lastLoaded => _lastLoaded;

  bool get needsRefresh =>
      _lastLoaded == null ||
      DateTime.now().difference(_lastLoaded!) >= const Duration(days: 7);

  /// Cloud analytics for basic/pro users. Caches for 7 days.
  Future<void> loadIfNeeded() async {
    if (!needsRefresh) return;
    await load();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _analytics = await _api.getConsumptionAnalytics();
    } catch (_) {
      _analytics = DemoData.consumptionAnalytics;
    }

    try {
      _anomalies = await _api.getAnomalies();
    } catch (_) {
      _anomalies = DemoData.anomalies;
    }

    _lastLoaded = DateTime.now();
    _loading = false;
    notifyListeners();
  }

  /// Computes the 5-day local consumption chart from BLE snapshots (guests).
  /// Returns at most 5 days; each entry = consumption that day (previous kg − current kg).
  List<LocalDayConsumption> get localChart {
    final snapshots = _storage.getDailySnapshots();
    if (snapshots.length < 2) return DemoData.localDayChart;

    final result = <LocalDayConsumption>[];
    for (int i = 1; i < snapshots.length; i++) {
      final consumption = snapshots[i - 1].totalGasKg - snapshots[i].totalGasKg;
      result.add(LocalDayConsumption(
        date: DateTime.parse(snapshots[i].date),
        consumptionKg: consumption.clamp(0, double.infinity),
      ));
    }

    // Rolling 5-day window
    if (result.length > 5) return result.sublist(result.length - 5);
    return result;
  }
}
