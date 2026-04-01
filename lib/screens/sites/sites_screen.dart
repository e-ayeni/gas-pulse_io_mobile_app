import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/cylinder.dart';
import '../../providers/site_provider.dart';
import '../../theme/app_theme.dart';

class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SiteProvider>().loadSites();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SiteProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sites', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/sites/add'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Site'),
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.sites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No sites yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text(
                        'Add a site to start monitoring your cylinders',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => prov.loadSites(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: prov.sites.length,
                    itemBuilder: (context, index) {
                      final site = prov.sites[index];
                      final cylCount = site.cylinders?.length ?? 0;
                      final gwCount = site.gateways?.length ?? 0;
                      final onlineGw = site.gateways?.where((g) => g.isOnline).length ?? 0;

                      // Worst cylinder status for summary
                      CylinderStatus worstStatus = CylinderStatus.noData;
                      if (site.cylinders != null && site.cylinders!.isNotEmpty) {
                        for (final c in site.cylinders!) {
                          if (c.status.index < worstStatus.index || worstStatus == CylinderStatus.noData) {
                            worstStatus = c.status;
                          }
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.push('/sites/${site.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(20),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.location_on, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            site.name,
                                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                          ),
                                          if (site.address != null && site.address!.displayString.isNotEmpty)
                                            Text(
                                              site.address!.displayString,
                                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _SiteStat(
                                      icon: Icons.propane_tank,
                                      label: '$cylCount cylinder${cylCount != 1 ? 's' : ''}',
                                    ),
                                    const SizedBox(width: 16),
                                    _SiteStat(
                                      icon: Icons.router,
                                      label: '$onlineGw/$gwCount gateway${gwCount != 1 ? 's' : ''} online',
                                      color: onlineGw > 0 ? Colors.green : Colors.orange,
                                    ),
                                  ],
                                ),
                              ],
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

class _SiteStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _SiteStat({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color ?? Colors.grey.shade600)),
      ],
    );
  }
}
