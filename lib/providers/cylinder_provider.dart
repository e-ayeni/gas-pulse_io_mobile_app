import 'package:flutter/foundation.dart';
import '../config/demo_data.dart';
import '../models/cylinder.dart';
import '../models/cylinder_type.dart';
import '../services/api_service.dart';

class CylinderProvider extends ChangeNotifier {
  final ApiService _api;

  CylinderDetail? _detail;
  List<CylinderType> _cylinderTypes = [];
  bool _loading = false;
  String? _error;

  CylinderProvider(this._api);

  CylinderDetail? get detail => _detail;
  List<CylinderType> get cylinderTypes => _cylinderTypes;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadCylinderDetail(String siteId, String cylinderId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _detail = await _api.getCylinder(siteId, cylinderId);
      _loading = false;
      notifyListeners();
    } catch (e) {
      // Fall back to demo data
      if (cylinderId.startsWith('demo-')) {
        _detail = DemoData.cylinderDetail(cylinderId);
        _loading = false;
        notifyListeners();
      } else {
        _error = 'Failed to load cylinder';
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadCylinderTypes() async {
    try {
      _cylinderTypes = await _api.getCylinderTypes();
      notifyListeners();
    } catch (e) {
      _cylinderTypes = CylinderType.defaults;
      notifyListeners();
    }
  }

  Future<bool> createCylinder(String siteId, CreateCylinderRequest request) async {
    try {
      await _api.createCylinder(siteId, request);
      return true;
    } catch (e) {
      _error = 'Failed to create cylinder';
      notifyListeners();
      return false;
    }
  }

  Future<bool> pairScale(String siteId, String cylinderId, String scaleDeviceId) async {
    try {
      await _api.pairCylinder(siteId, cylinderId, scaleDeviceId);
      await loadCylinderDetail(siteId, cylinderId);
      return true;
    } catch (e) {
      _error = 'Failed to pair scale';
      notifyListeners();
      return false;
    }
  }
}
