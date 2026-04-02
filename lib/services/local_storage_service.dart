import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert.dart';
import '../models/ble_device.dart';

class LocalStorageService {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _scaleConfigsKey = 'scale_configs';
  static const _hasOnboardedKey = 'has_onboarded';
  static const _localSnapshotsKey = 'local_daily_snapshots';
  static const _localAlertsKey = 'local_alerts';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // ── Auth ──

  String? get token => _prefs.getString(_tokenKey);
  String? get refreshToken => _prefs.getString(_refreshTokenKey);
  bool get isLoggedIn => token != null;

  Future<void> saveAuth(String token, String refreshToken) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> clearAuth() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_refreshTokenKey);
  }

  // ── Onboarding ──

  bool get hasOnboarded => _prefs.getBool(_hasOnboardedKey) ?? false;

  Future<void> setOnboarded() async {
    await _prefs.setBool(_hasOnboardedKey, true);
  }

  // ── Local Scale Configs ──

  List<LocalScaleConfig> getScaleConfigs() {
    final json = _prefs.getString(_scaleConfigsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => LocalScaleConfig.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveScaleConfig(LocalScaleConfig config) async {
    final configs = getScaleConfigs();
    final idx = configs.indexWhere((c) => c.deviceId == config.deviceId);
    if (idx >= 0) {
      configs[idx] = config;
    } else {
      configs.add(config);
    }
    await _prefs.setString(_scaleConfigsKey, jsonEncode(configs.map((c) => c.toJson()).toList()));
  }

  Future<void> removeScaleConfig(String deviceId) async {
    final configs = getScaleConfigs()..removeWhere((c) => c.deviceId == deviceId);
    await _prefs.setString(_scaleConfigsKey, jsonEncode(configs.map((c) => c.toJson()).toList()));
  }

  LocalScaleConfig? getScaleConfig(String deviceId) {
    final configs = getScaleConfigs();
    try {
      return configs.firstWhere((c) => c.deviceId == deviceId);
    } catch (_) {
      return null;
    }
  }

  // ── Local Daily Snapshots (guest chart) ──

  List<LocalDailySnapshot> getDailySnapshots() {
    final json = _prefs.getString(_localSnapshotsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    final snapshots = list
        .map((e) => LocalDailySnapshot.fromJson(e as Map<String, dynamic>))
        .toList();
    snapshots.sort((a, b) => a.date.compareTo(b.date));
    return snapshots;
  }

  void saveDailySnapshot(LocalDailySnapshot snapshot) {
    final snapshots = getDailySnapshots();
    snapshots.removeWhere((s) => s.date == snapshot.date);
    snapshots.add(snapshot);
    snapshots.sort((a, b) => a.date.compareTo(b.date));
    // Keep last 6 days (need N+1 to compute N consumption deltas)
    final cutoff = DateTime.now().subtract(const Duration(days: 6));
    snapshots.removeWhere((s) => DateTime.parse(s.date).isBefore(cutoff));
    _prefs.setString(
        _localSnapshotsKey, jsonEncode(snapshots.map((s) => s.toJson()).toList()));
  }

  // ── Local Alerts (guest, max 5) ──

  List<Alert> getLocalAlerts() {
    final json = _prefs.getString(_localAlertsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => Alert.fromJson(e as Map<String, dynamic>)).toList();
  }

  void saveLocalAlert(Alert alert) {
    final alerts = getLocalAlerts();
    // Deduplicate: skip if same device + type already fired in last 24h
    final isDuplicate = alerts.any((a) =>
        a.cylinderId == alert.cylinderId &&
        a.alertType == alert.alertType &&
        DateTime.now().difference(a.createdAt).inHours < 24);
    if (isDuplicate) return;
    alerts.insert(0, alert);
    final capped = alerts.take(5).toList();
    _prefs.setString(_localAlertsKey, jsonEncode(capped.map((a) => a.toJson()).toList()));
  }

  void markLocalAlertRead(String alertId) {
    final alerts = getLocalAlerts();
    final idx = alerts.indexWhere((a) => a.id == alertId);
    if (idx < 0) return;
    final a = alerts[idx];
    alerts[idx] = Alert(
      id: a.id,
      cylinderId: a.cylinderId,
      siteId: a.siteId,
      alertType: a.alertType,
      message: a.message,
      isRead: true,
      createdAt: a.createdAt,
    );
    _prefs.setString(_localAlertsKey, jsonEncode(alerts.map((a) => a.toJson()).toList()));
  }
}
