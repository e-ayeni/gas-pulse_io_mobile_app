import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/auth.dart';
import '../models/site.dart';
import '../models/cylinder.dart';
import '../models/cylinder_type.dart';
import '../models/gateway.dart';
import '../models/alert.dart';
import '../models/analytics.dart';
import 'local_storage_service.dart';

class ApiService {
  late final Dio _dio;
  final LocalStorageService _storage;

  ApiService(this._storage) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _storage.token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer ${_storage.token}';
            final response = await _dio.fetch(opts);
            return handler.resolve(response);
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = _storage.refreshToken;
    final token = _storage.token;
    if (refreshToken == null || token == null) return false;

    try {
      final response = await Dio().post(
        ApiConfig.refreshToken,
        data: {'token': token, 'refreshToken': refreshToken},
      );
      final loginResp = LoginResponse.fromJson(response.data);
      await _storage.saveAuth(loginResp.token, loginResp.refreshToken);
      return true;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      await _storage.clearAuth();
      return false;
    }
  }

  // ── Auth ──

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _dio.post(ApiConfig.login, data: request.toJson());
    return LoginResponse.fromJson(response.data);
  }

  Future<LoginResponse> register(RegisterRequest request) async {
    final response = await _dio.post(ApiConfig.register, data: request.toJson());
    return LoginResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get(ApiConfig.me);
    return response.data as Map<String, dynamic>;
  }

  // ── Sites ──

  Future<List<Site>> getSites() async {
    final response = await _dio.get(ApiConfig.sites());
    return (response.data as List).map((e) => Site.fromJson(e)).toList();
  }

  Future<Site> getSite(String id) async {
    final response = await _dio.get(ApiConfig.site(id));
    return Site.fromJson(response.data);
  }

  Future<Site> createSite(CreateSiteRequest request) async {
    final response = await _dio.post(ApiConfig.sites(), data: request.toJson());
    return Site.fromJson(response.data);
  }

  Future<void> deleteSite(String id) async {
    await _dio.delete(ApiConfig.site(id));
  }

  // ── Cylinders ──

  Future<List<CylinderSummary>> getCylinders(String siteId) async {
    final response = await _dio.get(ApiConfig.cylinders(siteId));
    return (response.data as List).map((e) => CylinderSummary.fromJson(e)).toList();
  }

  Future<CylinderDetail> getCylinder(String siteId, String cylinderId) async {
    final response = await _dio.get(ApiConfig.cylinder(siteId, cylinderId));
    return CylinderDetail.fromJson(response.data);
  }

  Future<void> createCylinder(String siteId, CreateCylinderRequest request) async {
    await _dio.post(ApiConfig.cylinders(siteId), data: request.toJson());
  }

  Future<void> pairCylinder(String siteId, String cylinderId, String scaleDeviceId) async {
    await _dio.post(
      ApiConfig.pairCylinder(siteId, cylinderId),
      data: {'scaleDeviceId': scaleDeviceId},
    );
  }

  Future<void> unpairCylinder(String siteId, String cylinderId) async {
    await _dio.post(ApiConfig.unpairCylinder(siteId, cylinderId));
  }

  Future<void> deleteCylinder(String siteId, String cylinderId) async {
    await _dio.delete(ApiConfig.cylinder(siteId, cylinderId));
  }

  // ── Cylinder Types ──

  Future<List<CylinderType>> getCylinderTypes() async {
    final response = await _dio.get(ApiConfig.cylinderTypes);
    return (response.data as List).map((e) => CylinderType.fromJson(e)).toList();
  }

  // ── Gateways ──

  Future<List<Gateway>> getGateways(String siteId) async {
    final response = await _dio.get(ApiConfig.gateways(siteId));
    return (response.data as List).map((e) => Gateway.fromJson(e)).toList();
  }

  Future<void> registerGateway(String siteId, RegisterGatewayRequest request) async {
    await _dio.post(ApiConfig.gateways(siteId), data: request.toJson());
  }

  // ── User Profile & Dashboard ──

  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _dio.get(ApiConfig.userProfile);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final response = await _dio.put(ApiConfig.userProfile, data: {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUserDashboard() async {
    final response = await _dio.get(ApiConfig.userDashboard);
    return response.data as Map<String, dynamic>;
  }

  Future<ConsumptionAnalytics> getConsumptionAnalytics() async {
    final response = await _dio.get(ApiConfig.userAnalytics);
    return ConsumptionAnalytics.fromJson(response.data);
  }

  Future<List<CylinderAnomaly>> getAnomalies() async {
    final response = await _dio.get(ApiConfig.userAnomalies);
    return (response.data as List)
        .map((e) => CylinderAnomaly.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Alerts ──

  Future<List<Alert>> getCylinderAlerts(String cylinderId) async {
    final response = await _dio.get(ApiConfig.cylinderAlerts(cylinderId));
    return (response.data as List).map((e) => Alert.fromJson(e)).toList();
  }

  Future<List<Alert>> getSiteAlerts(String siteId) async {
    final response = await _dio.get(ApiConfig.siteAlerts(siteId));
    return (response.data as List).map((e) => Alert.fromJson(e)).toList();
  }

  Future<void> markAlertRead(String alertId) async {
    await _dio.put(ApiConfig.markAlertRead(alertId));
  }
}
