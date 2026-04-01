import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ble_device.dart';

class LocalStorageService {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _scaleConfigsKey = 'scale_configs';
  static const _hasOnboardedKey = 'has_onboarded';

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
}
