class ApiConfig {
  // Change this to your backend URL
  static const String baseUrl = 'https://api.gaspulse.io';
  static const String apiVersion = 'v1';
  static const String apiBase = '$baseUrl/api/$apiVersion';

  // Endpoints
  static const String login = '$apiBase/auth/login';
  static const String register = '$apiBase/auth/register';
  static const String refreshToken = '$apiBase/auth/refresh';
  static const String me = '$apiBase/auth/me';

  static String sites() => '$apiBase/sites';
  static String site(String id) => '$apiBase/sites/$id';

  static String cylinders(String siteId) =>
      '$apiBase/sites/$siteId/cylinders';
  static String cylinder(String siteId, String cylinderId) =>
      '$apiBase/sites/$siteId/cylinders/$cylinderId';
  static String pairCylinder(String siteId, String cylinderId) =>
      '$apiBase/sites/$siteId/cylinders/$cylinderId/pair';
  static String unpairCylinder(String siteId, String cylinderId) =>
      '$apiBase/sites/$siteId/cylinders/$cylinderId/unpair';

  static String gateways(String siteId) =>
      '$apiBase/sites/$siteId/gateways';

  static String cylinderAlerts(String cylinderId) =>
      '$apiBase/cylinders/$cylinderId/alerts';
  static String siteAlerts(String siteId) =>
      '$apiBase/sites/$siteId/alerts';
  static String markAlertRead(String alertId) =>
      '$apiBase/alerts/$alertId/read';

  static const String userProfile = '$apiBase/user/profile';
  static const String userDashboard = '$apiBase/user/dashboard';
  static const String userAnalytics = '$apiBase/user/analytics';
  static const String userAnomalies = '$apiBase/user/anomalies';

  static const String cylinderTypes = '$apiBase/cylinder-types';
}
