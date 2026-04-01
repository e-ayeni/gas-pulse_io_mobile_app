import 'package:flutter/foundation.dart';
import '../models/auth.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final LocalStorageService _storage;

  User? _user;
  bool _loading = false;
  String? _error;

  AuthProvider(this._api, this._storage);

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool _demoMode = false;

  bool get isLoggedIn => _storage.isLoggedIn || _demoMode;
  bool get isDemoMode => _demoMode;

  Future<void> init() async {
    if (_storage.isLoggedIn) {
      await fetchUser();
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.login(LoginRequest(email: email, password: password));
      await _storage.saveAuth(response.token, response.refreshToken);
      _user = response.user;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String firstName, String lastName) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.register(RegisterRequest(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      ));
      await _storage.saveAuth(response.token, response.refreshToken);
      _user = response.user;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchUser() async {
    try {
      final data = await _api.getMe();
      _user = User.fromJson(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch user: $e');
      await logout();
    }
  }

  void loginDemo({bool business = false}) {
    _demoMode = true;
    _user = User(
      id: 'demo-user',
      email: business ? 'admin@gaspulse.io' : 'demo@gaspulse.io',
      firstName: business ? 'Admin' : 'Demo',
      lastName: 'User',
      role: business ? 'CompanyAdmin' : 'PrivateConsumer',
      companyId: business ? 'demo-company' : null,
    );
    _error = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.clearAuth();
    _user = null;
    _demoMode = false;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    return 'Login failed. Please check your credentials.';
  }
}
