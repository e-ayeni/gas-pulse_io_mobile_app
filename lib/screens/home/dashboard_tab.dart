import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/cylinder.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ble_provider.dart';
import '../../providers/site_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cylinder_card.dart';
import '../../widgets/liquid_cylinder.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    _loadDataIfNeeded();
  }

  void _loadDataIfNeeded() {
    final auth = context.read<AuthProvider>();
    final isBusiness = auth.user != null && (auth.user!.isCompanyAdmin || auth.user!.isSystemAdmin);
    if (isBusiness) {
      context.read<SiteProvider>().loadSites();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bt = context.watch<BleProvider>();
    final isLoggedIn = auth.isLoggedIn;
    final isBusinessUser = auth.user != null && (auth.user!.isCompanyAdmin || auth.user!.isSystemAdmin);
    final devices = bt.deviceList;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('GasPulse', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            if (isLoggedIn)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Hi, ${auth.user?.firstName ?? ''}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ),
              ),
          ],
        ),

        // ── My Cylinders overview ──
        if (devices.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  const Text(
                    'My Cylinders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Switch to Cylinders tab (index 1) — find HomeScreen state
                      final homeState = context.findAncestorStateOfType<State>();
                      if (homeState != null && homeState is dynamic) {
                        // Navigate via bottom nav
                      }
                      context.push('/scan');
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
          // Show the lowest cylinder prominently
          if (_lowestDevice(devices) != null)
            SliverToBoxAdapter(
              child: _HeroCylinder(device: _lowestDevice(devices)!),
            ),
          // Other cylinders as compact cards
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final device = devices[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push('/bluetooth/${device.deviceId}'),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            LiquidCylinder(
                              fillPercent: device.gasRemainingPercent,
                              width: 40,
                              height: 56,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        device.connected
                                            ? Icons.bluetooth_connected
                                            : Icons.bluetooth_disabled,
                                        size: 12,
                                        color: device.connected ? Colors.blue : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      if (device.cylinderType != null)
                                        Text(
                                          device.cylinderType!.name,
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                        ),
                                      if (device.cylinderLifted) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.warning_amber, size: 12, color: Colors.red),
                                        const SizedBox(width: 2),
                                        const Text(
                                          'Lifted!',
                                          style: TextStyle(fontSize: 12, color: Colors.red),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              device.gasRemainingPercent != null
                                  ? '${device.gasRemainingPercent!.toStringAsFixed(0)}%'
                                  : device.connected
                                      ? '${device.rawWeightKg.toStringAsFixed(1)} kg'
                                      : '--',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: device.gasRemainingPercent != null
                                    ? AppColors.gasColor(device.gasRemainingPercent)
                                    : AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: devices.length,
            ),
          ),
        ],

        // ── Empty state: no cylinders yet ──
        if (devices.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Center(
                child: Column(
                  children: [
                    const LiquidCylinder(
                      fillPercent: null,
                      width: 100,
                      height: 150,
                      animate: false,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No cylinders yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a GasPulse scale to start\nmonitoring your gas level',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/scan'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Scale'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(180, 44)),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ══════════════════════════════════════════════
        // ── CLOUD: Sites + Cylinders (business only) ──
        // ══════════════════════════════════════════════
        if (isBusinessUser) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  const Text('My Sites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/sites'),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
          ),
          _SitesSummary(),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Cloud Cylinders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
          _CylindersList(),
        ],

        // ── Sign-in prompt for non-logged-in users ──
        if (!isLoggedIn)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Card(
                color: AppColors.primary.withAlpha(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/login'),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloud_outlined, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Want predictions & remote alerts?',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              SizedBox(height: 2),
                              Text('Sign in to access cloud features',
                                  style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  /// Find the device with the lowest gas level for the hero card.
  _device? _lowestDevice(List<dynamic> devices) {
    if (devices.isEmpty) return null;
    dynamic lowest;
    double lowestPct = 101;
    for (final d in devices) {
      final pct = d.gasRemainingPercent;
      if (pct != null && pct < lowestPct) {
        lowestPct = pct;
        lowest = d;
      }
    }
    return lowest;
  }
}

typedef _device = dynamic;

class _HeroCylinder extends StatelessWidget {
  final dynamic device;
  const _HeroCylinder({required this.device});

  @override
  Widget build(BuildContext context) {
    final pct = device.gasRemainingPercent as double?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: pct != null && pct < 15
            ? Colors.red.shade50
            : pct != null && pct < 30
                ? Colors.orange.shade50
                : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/bluetooth/${device.deviceId}'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                LiquidCylinder(
                  fillPercent: pct,
                  width: 70,
                  height: 100,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pct != null && pct < 15)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LOW GAS',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      Text(
                        device.displayName as String,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      if (device.cylinderType != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          device.cylinderType.name as String,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        pct != null
                            ? '${pct.toStringAsFixed(0)}% remaining'
                            : '${(device.rawWeightKg as double).toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: pct != null
                              ? AppColors.gasColor(pct)
                              : AppColors.primaryDark,
                        ),
                      ),
                      if (device.gasRemainingKg != null)
                        Text(
                          '${(device.gasRemainingKg as double).toStringAsFixed(1)} kg gas',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SitesSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final siteProv = context.watch<SiteProvider>();

    if (siteProv.loading) {
      return const SliverToBoxAdapter(
        child: Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      );
    }

    if (siteProv.sites.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/sites/add'),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_location_alt, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create your first site', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          SizedBox(height: 4),
                          Text('Add a site to start monitoring cylinders', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: siteProv.sites.length,
          itemBuilder: (context, index) {
            final site = siteProv.sites[index];
            final cylCount = site.cylinders?.length ?? 0;
            final gwOnline = site.gateways?.where((g) => g.isOnline).length ?? 0;
            final gwTotal = site.gateways?.length ?? 0;

            return Container(
              width: 200,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/sites/${site.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                site.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '$cylCount cylinder${cylCount != 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: gwOnline > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$gwOnline/$gwTotal gateway${gwTotal != 1 ? 's' : ''}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CylindersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final siteProv = context.watch<SiteProvider>();

    if (siteProv.loading) {
      return const SliverToBoxAdapter(
        child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      );
    }

    final allCylinders = <(String siteId, CylinderSummary cyl)>[];
    for (final site in siteProv.sites) {
      if (site.cylinders != null) {
        for (final c in site.cylinders!) {
          allCylinders.add((site.id, c));
        }
      }
    }

    if (allCylinders.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.propane_tank_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No cloud cylinders yet', style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text('Add a cylinder from your site page', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final (siteId, cyl) = allCylinders[index];
          return CylinderCard(
            cylinder: cyl,
            onTap: () => context.push('/sites/$siteId/cylinders/${cyl.id}'),
          );
        },
        childCount: allCylinders.length,
      ),
    );
  }
}
