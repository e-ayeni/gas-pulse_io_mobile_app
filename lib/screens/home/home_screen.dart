import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_provider.dart';
import '../home/dashboard_tab.dart';
import '../ble/ble_tab.dart';
import '../alerts/alerts_tab.dart';
import '../settings/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Start Bluetooth scan automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BleProvider>().startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    const tabs = [
      DashboardTab(),
      BleTab(),
      AlertsTab(),
      SettingsTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.bluetooth_searching), label: 'Bluetooth'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
