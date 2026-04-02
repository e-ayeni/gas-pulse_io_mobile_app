import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'services/local_storage_service.dart';
import 'services/api_service.dart';
import 'services/ble_service.dart';
import 'providers/auth_provider.dart';
import 'providers/site_provider.dart';
import 'providers/cylinder_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/ble_provider.dart';
import 'screens/auth/landing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/ble/ble_device_screen.dart';
import 'screens/ble/scan_screen.dart';
import 'screens/sites/sites_screen.dart';
import 'screens/sites/site_detail_screen.dart';
import 'screens/sites/add_site_screen.dart';
import 'screens/cylinders/cylinder_detail_screen.dart';
import 'screens/cylinders/add_cylinder_screen.dart';
import 'screens/gateways/add_gateway_screen.dart';
import 'screens/settings/bluetooth_settings_screen.dart';
import 'screens/settings/notification_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = LocalStorageService(prefs);

  runApp(GasPulseApp(storage: storage));
}

class GasPulseApp extends StatefulWidget {
  final LocalStorageService storage;
  const GasPulseApp({super.key, required this.storage});

  @override
  State<GasPulseApp> createState() => _GasPulseAppState();
}

class _GasPulseAppState extends State<GasPulseApp> {
  late final ApiService _apiService;
  late final BleService _bleService;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(widget.storage);
    _bleService = BleService(widget.storage);

    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),

        // Scan for new scales
        GoRoute(
          path: '/scan',
          builder: (context, state) => const ScanScreen(),
        ),

        // Bluetooth device detail / config
        GoRoute(
          path: '/bluetooth/:deviceId',
          builder: (context, state) => BleDeviceScreen(
            deviceId: state.pathParameters['deviceId']!,
          ),
        ),

        // Sites
        GoRoute(
          path: '/sites',
          builder: (context, state) => const SitesScreen(),
        ),
        GoRoute(
          path: '/sites/add',
          builder: (context, state) => const AddSiteScreen(),
        ),
        GoRoute(
          path: '/sites/:siteId',
          builder: (context, state) => SiteDetailScreen(
            siteId: state.pathParameters['siteId']!,
          ),
        ),

        // Cylinders
        GoRoute(
          path: '/sites/:siteId/cylinders/add',
          builder: (context, state) => AddCylinderScreen(
            siteId: state.pathParameters['siteId']!,
          ),
        ),
        GoRoute(
          path: '/sites/:siteId/cylinders/:cylinderId',
          builder: (context, state) => CylinderDetailScreen(
            siteId: state.pathParameters['siteId']!,
            cylinderId: state.pathParameters['cylinderId']!,
          ),
        ),

        // Gateways
        GoRoute(
          path: '/sites/:siteId/gateways/add',
          builder: (context, state) => AddGatewayScreen(
            siteId: state.pathParameters['siteId']!,
          ),
        ),

        // Settings sub-screens
        GoRoute(
          path: '/settings/bluetooth',
          builder: (context, state) => const BluetoothSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/notifications',
          builder: (context, state) => const NotificationSettingsScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: _apiService),
        ChangeNotifierProvider(create: (_) => AuthProvider(_apiService, widget.storage)..init()),
        ChangeNotifierProvider(create: (_) => SiteProvider(_apiService)),
        ChangeNotifierProvider(create: (_) => CylinderProvider(_apiService)),
        ChangeNotifierProvider(create: (_) => AlertProvider(_apiService)),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider(_apiService, widget.storage)),
        ChangeNotifierProvider(create: (_) => BleProvider(_bleService, widget.storage)),
      ],
      child: MaterialApp.router(
        title: 'GasPulse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
