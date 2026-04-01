import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weight_reading.dart';
import '../theme/app_theme.dart';

class ReadingChart extends StatelessWidget {
  final List<WeightReading> readings;

  const ReadingChart({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No readings yet')),
      );
    }

    final sorted = List<WeightReading>.from(readings)
      ..sort((a, b) => a.readAt.compareTo(b.readAt));

    final spots = sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.gasRemainingPercent);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}%',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (sorted.length / 4).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                  return Text(
                    DateFormat('dd/MM').format(sorted[idx].readAt),
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: (minY - 5).clamp(0, 100),
          maxY: (maxY + 5).clamp(0, 100),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeColor: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withAlpha(60),
                    AppColors.primary.withAlpha(5),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) {
                final reading = sorted[spot.spotIndex];
                return LineTooltipItem(
                  '${reading.gasRemainingPercent.toStringAsFixed(1)}%\n${DateFormat('dd MMM HH:mm').format(reading.readAt)}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
