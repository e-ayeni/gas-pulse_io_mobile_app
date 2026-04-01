import 'package:flutter/foundation.dart';
import '../config/demo_data.dart';
import '../models/site.dart';
import '../services/api_service.dart';

class SiteProvider extends ChangeNotifier {
  final ApiService _api;

  List<Site> _sites = [];
  Site? _selectedSite;
  bool _loading = false;
  String? _error;
  bool _usingDemo = false;

  SiteProvider(this._api);

  List<Site> get sites => _sites;
  Site? get selectedSite => _selectedSite;
  bool get loading => _loading;
  String? get error => _error;
  bool get usingDemo => _usingDemo;

  Future<void> loadSites() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _sites = await _api.getSites();
      _usingDemo = false;
      _loading = false;
      notifyListeners();
    } catch (e) {
      // Fall back to demo data
      _sites = DemoData.sites;
      _usingDemo = true;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadSiteDetail(String id) async {
    _loading = true;
    notifyListeners();

    try {
      if (_usingDemo) {
        _selectedSite = DemoData.sites.firstWhere((s) => s.id == id);
      } else {
        _selectedSite = await _api.getSite(id);
      }
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load site details';
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createSite(CreateSiteRequest request) async {
    try {
      final site = await _api.createSite(request);
      _sites.add(site);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create site';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSite(String id) async {
    try {
      if (!_usingDemo) await _api.deleteSite(id);
      _sites.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete site';
      notifyListeners();
      return false;
    }
  }
}
