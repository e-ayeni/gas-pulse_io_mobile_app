import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/alert.dart';
import '../../models/analytics.dart';
import '../../providers/alert_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ble_provider.dart';
import '../../providers/site_provider.dart';
import '../../theme/app_theme.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;

    final analyticsP = context.read<AnalyticsProvider>();
    analyticsP.loadIfNeeded();

    final sites = context.read<SiteProvider>().sites;
    final siteId = sites.isNotEmpty ? sites.first.id : 'demo-site-1';
    context.read<AlertProvider>().loadSiteAlerts(siteId);
    context.read<SiteProvider>().loadSites();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final analyticsP = context.watch<AnalyticsProvider>();
    final alertP = context.watch<AlertProvider>();
    context.watch<BleProvider>(); // triggers rebuild when local alerts change
    final user = auth.user;

    final isGuest = !auth.isLoggedIn;
    final isPro = user != null && user.hasProAccess;
    final isBasic = user != null && user.hasBasicAccess;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('GasPulse', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            if (!isGuest && user != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Hi, ${user.firstName}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ),
              ),
          ],
        ),

        // ── GUEST: 5-day local chart ──────────────────────────────────────────
        if (isGuest) ...[
          SliverToBoxAdapter(
            child: _LocalChart(days: analyticsP.localChart),
          ),
          const SliverToBoxAdapter(child: _LocalAlertSection()),
          const SliverToBoxAdapter(child: _SignUpCta()),
        ],

        // ── BASIC / PRO: cloud weekly pattern chart ───────────────────────────
        if (!isGuest) ...[
          SliverToBoxAdapter(
            child: _CloudWeeklyChart(
              analytics: analyticsP.analytics,
              loading: analyticsP.loading,
              lastLoaded: analyticsP.lastLoaded,
            ),
          ),
        ],

        // ── BASIC+: predictions ───────────────────────────────────────────────
        if (isBasic) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text('Predictions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
          _PredictionsSection(),
        ],

        // ── PRO only: monthly trend + anomalies ───────────────────────────────
        if (isPro) ...[
          if (analyticsP.analytics != null)
            SliverToBoxAdapter(
              child: _MonthlyTrend(analytics: analyticsP.analytics!),
            ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text('Anomaly Detection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
          _AnomaliesSection(anomalies: analyticsP.anomalies),
        ],

        // ── BASIC (non-pro): upgrade nudge ────────────────────────────────────
        if (isBasic && !isPro)
          const SliverToBoxAdapter(child: _UpgradeToProBanner()),

        // ── BASIC+: cloud alerts ──────────────────────────────────────────────
        if (!isGuest) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  const Text('Recent Alerts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (alertP.unreadCount > 0)
                    _UnreadBadge(count: alertP.unreadCount),
                ],
              ),
            ),
          ),
          if (alertP.loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (alertP.alerts.isEmpty)
            const SliverToBoxAdapter(child: _EmptyAlerts())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final alert = alertP.alerts[index];
                  return _AlertRow(
                    alert: alert,
                    onTap: () {
                      if (!alert.isRead) alertP.markRead(alert.id);
                    },
                  );
                },
                childCount: alertP.alerts.length.clamp(0, 5),
              ),
            ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ── Local 5-day chart (guest) ────────────────────────────────────────────────

class _LocalChart extends StatelessWidget {
  final List<LocalDayConsumption> days;

  const _LocalChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final maxY = days.isEmpty
        ? 1.0
        : days.map((d) => d.consumptionKg).reduce((a, b) => a > b ? a : b) * 1.4;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final fmt = DateFormat('E'); // Mon, Tue…

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Text('Last 5 Days',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Tooltip(
                    message: 'Local data — resets every 5 days',
                    child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text('Gas consumed (kg)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 16),
              if (days.isEmpty)
                const SizedBox(
                  height: 130,
                  child: Center(
                    child: Text('Keep the app open to start tracking',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                SizedBox(
                  height: 130,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                            '${days[group.x].consumptionKg.toStringAsFixed(2)} kg',
                            const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                              final isToday = DateFormat('yyyy-MM-dd')
                                      .format(days[idx].date) ==
                                  today;
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  fmt.format(days[idx].date),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                        isToday ? FontWeight.bold : FontWeight.normal,
                                    color: isToday
                                        ? AppColors.primary
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 3,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: days.asMap().entries.map((e) {
                        final isToday = DateFormat('yyyy-MM-dd').format(e.value.date) == today;
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.consumptionKg,
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.primaryLight.withAlpha(140),
                              width: 28,
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(5)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Local alerts section (guest) ─────────────────────────────────────────────

class _LocalAlertSection extends StatelessWidget {
  const _LocalAlertSection();

  @override
  Widget build(BuildContext context) {
    final bleP = context.watch<BleProvider>();
    final alerts = bleP.localAlerts;
    final unread = alerts.where((a) => !a.isRead).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Row(
            children: [
              const Text('Recent Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (unread > 0) _UnreadBadge(count: unread),
            ],
          ),
        ),
        if (alerts.isEmpty)
          const _EmptyAlerts()
        else
          ...alerts.map(
            (alert) => _AlertRow(
              alert: alert,
              onTap: () => bleP.markLocalAlertRead(alert.id),
            ),
          ),
      ],
    );
  }
}

// ── Cloud weekly pattern chart (basic / pro) ─────────────────────────────────

class _CloudWeeklyChart extends StatelessWidget {
  final ConsumptionAnalytics? analytics;
  final bool loading;
  final DateTime? lastLoaded;

  const _CloudWeeklyChart(
      {required this.analytics, required this.loading, this.lastLoaded});

  @override
  Widget build(BuildContext context) {
    final days = analytics?.byDayOfWeek ?? [];
    final maxY = days.isEmpty
        ? 1.0
        : days.map((d) => d.avgConsumptionKg).reduce((a, b) => a > b ? a : b) * 1.4;
    final todayWeekday = DateTime.now().weekday; // 1=Mon … 7=Sun

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Weekly Pattern',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  if (lastLoaded != null)
                    Text(
                      'Updated ${timeago.format(lastLoaded!)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text('Avg gas consumed per day (kg)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 16),
              if (loading)
                const SizedBox(
                    height: 130, child: Center(child: CircularProgressIndicator()))
              else if (days.isEmpty)
                const SizedBox(
                  height: 130,
                  child: Center(
                      child: Text('No data yet', style: TextStyle(color: Colors.grey))),
                )
              else
                SizedBox(
                  height: 130,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                            '${days[group.x].avgConsumptionKg.toStringAsFixed(2)} kg',
                            const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                              final isToday = days[idx].day == todayWeekday;
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  days[idx].dayName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                        isToday ? FontWeight.bold : FontWeight.normal,
                                    color: isToday
                                        ? AppColors.primary
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 3,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: days.asMap().entries.map((e) {
                        final isToday = e.value.day == todayWeekday;
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.avgConsumptionKg,
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.primaryLight.withAlpha(140),
                              width: 20,
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(5)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Monthly trend (pro) ───────────────────────────────────────────────────────

class _MonthlyTrend extends StatelessWidget {
  final ConsumptionAnalytics analytics;

  const _MonthlyTrend({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final months = analytics.byMonth;
    if (months.isEmpty) return const SizedBox.shrink();
    final maxY =
        months.map((m) => m.totalConsumptionKg).reduce((a, b) => a > b ? a : b) * 1.4;
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monthly Trend',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Total gas consumed (kg)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 16),
              SizedBox(
                height: 130,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                          '${months[group.x].totalConsumptionKg.toStringAsFixed(1)} kg',
                          const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= months.length) return const SizedBox.shrink();
                            final isCurrent = months[idx].month == now.month &&
                                months[idx].year == now.year;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                months[idx].label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                      isCurrent ? FontWeight.bold : FontWeight.normal,
                                  color: isCurrent
                                      ? AppColors.accent
                                      : Colors.grey.shade500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 3,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: months.asMap().entries.map((e) {
                      final isCurrent =
                          e.value.month == now.month && e.value.year == now.year;
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.totalConsumptionKg,
                            color: isCurrent
                                ? AppColors.accent
                                : AppColors.primaryLight.withAlpha(140),
                            width: 20,
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(5)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Predictions (basic+) ──────────────────────────────────────────────────────

class _PredictionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final siteProv = context.watch<SiteProvider>();
    final cylinders = siteProv.sites
        .expand((s) => s.cylinders ?? [])
        .where((c) => c.estimatedDaysRemaining != null)
        .toList()
      ..sort((a, b) => a.estimatedDaysRemaining!.compareTo(b.estimatedDaysRemaining!));

    if (cylinders.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No cloud cylinders yet — add cylinders to a site to see predictions.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final cyl = cylinders[index];
          final days = cyl.estimatedDaysRemaining!;
          final urgent = days <= 3;
          final soon = days <= 7;
          final color = urgent
              ? AppColors.gasCritical
              : soon
                  ? AppColors.gasMedium
                  : AppColors.gasHigh;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cyl.friendlyName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            cyl.cylinderTypeName ?? '',
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$days day${days != 1 ? 's' : ''}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color),
                        ),
                        Text('remaining',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: cylinders.length.clamp(0, 5),
      ),
    );
  }
}

// ── Anomaly detection (pro) ───────────────────────────────────────────────────

class _AnomaliesSection extends StatelessWidget {
  final List<CylinderAnomaly> anomalies;

  const _AnomaliesSection({required this.anomalies});

  @override
  Widget build(BuildContext context) {
    if (anomalies.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: AppColors.gasHigh, size: 28),
                  const SizedBox(width: 12),
                  const Text('No anomalies detected',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final a = anomalies[index];
          final isLeak = a.type == AnomalyType.possibleLeak;
          final color = isLeak ? AppColors.gasCritical : AppColors.gasMedium;
          final icon = isLeak ? Icons.water_drop_outlined : Icons.speed;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              color: color.withAlpha(10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.friendlyName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(a.description,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Text(
                            timeago.format(a.detectedAt),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: anomalies.length,
      ),
    );
  }
}

// ── Upgrade to Pro banner (basic only) ───────────────────────────────────────

class _UpgradeToProBanner extends StatelessWidget {
  const _UpgradeToProBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        color: AppColors.accent.withAlpha(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_graph, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unlock anomaly detection',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    SizedBox(height: 2),
                    Text('Upgrade to Pro to detect leaks and unusual consumption',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.lock_outline, color: AppColors.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sign-up CTA (guest) ──────────────────────────────────────────────────────

class _SignUpCta extends StatelessWidget {
  const _SignUpCta();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        color: AppColors.primary.withAlpha(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/register'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Want predictions & remote alerts?',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      SizedBox(height: 2),
                      Text('Create an account to unlock cloud features',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.notifications_none, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('No alerts', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final Alert alert;
  final VoidCallback onTap;

  const _AlertRow({required this.alert, required this.onTap});

  (IconData, Color) get _iconAndColor {
    switch (alert.alertType) {
      case AlertType.lowGas:
        return (Icons.propane_tank, AppColors.gasMedium);
      case AlertType.criticalGas:
        return (Icons.warning_amber, AppColors.gasCritical);
      case AlertType.cylinderRemoved:
        return (Icons.remove_circle_outline, AppColors.gasEmpty);
      case AlertType.batteryLow:
        return (Icons.battery_alert, Colors.orange);
      case AlertType.gatewayOffline:
        return (Icons.cloud_off, Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Card(
        color: alert.isRead ? null : color.withAlpha(12),
        child: ListTile(
          dense: true,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            alert.message,
            style: TextStyle(
              fontSize: 13,
              fontWeight: alert.isRead ? FontWeight.normal : FontWeight.w600,
            ),
          ),
          subtitle: Text(
            timeago.format(alert.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          trailing: alert.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
          onTap: onTap,
        ),
      ),
    );
  }
}
