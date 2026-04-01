import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/site_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cylinder_card.dart';

class SiteDetailScreen extends StatefulWidget {
  final String siteId;
  const SiteDetailScreen({super.key, required this.siteId});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SiteProvider>().loadSiteDetail(widget.siteId);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SiteProvider>();
    final site = prov.selectedSite;

    return Scaffold(
      appBar: AppBar(
        title: Text(site?.name ?? 'Site'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Site')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Site', style: TextStyle(color: AppColors.error)),
              ),
            ],
            onSelected: (value) async {
              if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Site?'),
                    content: const Text('This will remove all cylinders and gateways at this site.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await prov.deleteSite(widget.siteId);
                  if (context.mounted) context.pop();
                }
              }
            },
          ),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : site == null
              ? const Center(child: Text('Failed to load site'))
              : RefreshIndicator(
                  onRefresh: () => prov.loadSiteDetail(widget.siteId),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Site info ──
                        if (site.address != null && site.address!.displayString.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    site.address!.displayString,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // ── Gateways ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Row(
                            children: [
                              const Text('Gateways', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => context.push('/sites/${widget.siteId}/gateways/add'),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                        ),
                        if (site.gateways == null || site.gateways!.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Icon(Icons.router, color: Colors.grey.shade400),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No gateways registered.\nAdd a gateway to receive scale data.',
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          ...site.gateways!.map((gw) => Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (gw.isOnline ? Colors.green : Colors.grey).withAlpha(20),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.router,
                                      color: gw.isOnline ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                  title: Text(gw.name ?? gw.deviceId),
                                  subtitle: Text(
                                    gw.isOnline
                                        ? 'Online${gw.lastSeenAt != null ? ' - last seen ${timeago.format(gw.lastSeenAt!)}' : ''}'
                                        : 'Offline${gw.lastSeenAt != null ? ' - last seen ${timeago.format(gw.lastSeenAt!)}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: gw.isOnline ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  trailing: gw.firmwareVersion != null
                                      ? Text('v${gw.firmwareVersion}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400))
                                      : null,
                                ),
                              )),

                        // ── Cylinders ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                          child: Row(
                            children: [
                              const Text('Cylinders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => context.push('/sites/${widget.siteId}/cylinders/add'),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                        ),
                        if (site.cylinders == null || site.cylinders!.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Icon(Icons.propane_tank, color: Colors.grey.shade400),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No cylinders registered.\nAdd a cylinder and pair it with a scale.',
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          ...site.cylinders!.map((cyl) => CylinderCard(
                                cylinder: cyl,
                                onTap: () => context.push('/sites/${widget.siteId}/cylinders/${cyl.id}'),
                              )),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
    );
  }
}
