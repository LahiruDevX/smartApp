import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/di/app_di.dart';
import '../../features/environment/environment_service.dart';
import 'app_shell.dart';

class EnvironmentalScreen extends StatelessWidget {
  const EnvironmentalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Environmental Monitoring',
      subtitle: 'Real-time and historical environmental data',
      selectedRoute: '/environmental',
      body: _EnvironmentalBody(),
    );
  }
}

class _EnvironmentalBody extends StatefulWidget {
  const _EnvironmentalBody();

  @override
  State<_EnvironmentalBody> createState() => _EnvironmentalBodyState();
}

class _EnvironmentalBodyState extends State<_EnvironmentalBody> {
  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;
  bool _mid(BuildContext c) => MediaQuery.of(c).size.width >= 680;

  static final _bottomLabels = <double, String>{
    0: '20m',
    5: '15m',
    10: '10m',
    15: '5m',
    20: 'now',
  };

  static const _order = ['temperature', 'humidity', 'air_quality', 'light', 'noise'];
  static const _icons = {
    'temperature': Icons.thermostat_outlined,
    'humidity': Icons.water_drop_outlined,
    'air_quality': Icons.air_outlined,
    'light': Icons.wb_sunny_outlined,
    'noise': Icons.volume_up_outlined,
  };

  bool _loading = true;
  String? _error;
  List<SensorReading> _sensors = const [];
  Map<String, List<SeriesPoint>> _history = const {};
  DateTime? _updatedAt;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _load();
    _autoRefresh = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final latest = await environmentService.latest();
      final history = await environmentService.history(minutes: 20);
      if (!mounted) return;
      setState(() {
        _sensors = latest.sensors;
        _history = history;
        _updatedAt = latest.updatedAt ?? DateTime.now();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _hms(DateTime dt) {
    final t = dt.toLocal();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(t.hour)}:${p(t.minute)}:${p(t.second)}';
  }

  LineChartBarData _line(String type, Color color) => LineChartBarData(
        isCurved: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        barWidth: 2.5,
        color: color,
        spots: (_history[type] ?? const [])
            .map((p) => FlSpot(p.t, p.value))
            .toList(),
      );

  (double, double) _bounds(List<String> types) {
    final values = [
      for (final t in types) ...(_history[t] ?? const []).map((p) => p.value),
    ];
    if (values.isEmpty) return (0, 100);
    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    final pad = ((hi - lo) * 0.15).clamp(1.0, double.infinity);
    lo = (lo - pad).floorToDouble();
    hi = (hi + pad).ceilToDouble();
    return (lo, hi);
  }

  @override
  Widget build(BuildContext context) {
    final columns = _wide(context) ? 3 : (_mid(context) ? 2 : 1);

    if (_loading) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load environmental data\n$_error',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final byType = {for (final s in _sensors) s.type: s};
    final metrics = [
      for (final t in _order)
        if (byType[t] != null)
          _MiniMetric(
            title: byType[t]!.label,
            value: byType[t]!.value.toStringAsFixed(1),
            unit: byType[t]!.unit,
            status: byType[t]!.status,
            icon: _icons[t]!,
          ),
    ];

    final (thLo, thHi) = _bounds(['temperature', 'humidity']);
    final (airLo, airHi) = _bounds(['air_quality']);

    // AppShell already wraps the body in a scroll view, so use a plain Column.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Color(0xFF16A34A)),
              const SizedBox(width: 6),
              Text(
                _updatedAt == null
                    ? 'Live'
                    : 'Live · updated ${_hms(_updatedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _load(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          _Grid(columns: columns, children: metrics),
          const SizedBox(height: 16),
          _CardSection(
            title: 'Historical Data (Last 20 minutes)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                const Text(
                  'Temperature & Humidity',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                _LineChartCard(
                  height: 220,
                  lines: [
                    _line('temperature', const Color(0xFF2D66F6)),
                    _line('humidity', const Color(0xFF16A34A)),
                  ],
                  minX: 0,
                  maxX: 20,
                  minY: thLo,
                  maxY: thHi,
                  bottomLabels: _bottomLabels,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Air Quality',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                _LineChartCard(
                  height: 220,
                  lines: [_line('air_quality', const Color(0xFFF59E0B))],
                  minX: 0,
                  maxX: 20,
                  minY: airLo,
                  maxY: airHi,
                  bottomLabels: _bottomLabels,
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        _CardSection(
          title: 'Alert Thresholds',
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                children: const [
                  Expanded(
                    child: _ThresholdItem(
                      label: 'Temperature Warning (°C)',
                      value: '26',
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: _ThresholdItem(
                      label: 'Humidity Warning (%)',
                      value: '70',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(
                    child: _ThresholdItem(
                      label: 'Air Quality Warning (PPM)',
                      value: '450',
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: _ThresholdItem(
                      label: 'Noise Level Warning (dB)',
                      value: '60',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Save Settings'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/* ---- widgets ---- */

class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children});
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final spacing = 14.0;
      final w = c.maxWidth;
      final itemW = (w - (columns - 1) * spacing) / columns;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children.map((e) => SizedBox(width: itemW, child: e)).toList(),
      );
    });
  }
}

/// ✅ FIXED: NO fixed height -> prevents overflow on small tiles
class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.title,
    required this.value,
    required this.unit,
    this.status = 'normal',
    this.icon,
  });

  final String title;
  final String value;
  final String unit;
  final String status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final warn = status.toLowerCase() == 'warning';
    final statusColor = warn ? const Color(0xFFF59E0B) : const Color(0xFF16A34A);
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 14),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: Colors.black.withOpacity(0.45)),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 10, color: statusColor),
              const SizedBox(width: 8),
              Text(
                status,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            blurRadius: 26,
            offset: const Offset(0, 16),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ThresholdItem extends StatelessWidget {
  const _ThresholdItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.6),
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

/// ✅ Real chart widget
class _LineChartCard extends StatelessWidget {
  const _LineChartCard({
    required this.height,
    required this.lines,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    this.bottomLabels,
  });

  final double height;
  final List<LineChartBarData> lines;
  final double minX, maxX, minY, maxY;

  /// map x value -> label text (example: 19 -> "19m ago")
  final Map<double, String>? bottomLabels;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (maxY - minY) / 4,
            verticalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.black.withOpacity(0.06),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.black.withOpacity(0.04),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: Colors.black.withOpacity(0.12)),
              bottom: BorderSide(color: Colors.black.withOpacity(0.12)),
              right: const BorderSide(color: Colors.transparent),
              top: const BorderSide(color: Colors.transparent),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: (maxY - minY) / 4,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    v.toStringAsFixed(0),
                    style: TextStyle(fontSize: 10.5, color: Colors.black.withOpacity(0.55)),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 5,
                getTitlesWidget: (v, meta) {
                  final txt = bottomLabels?[v] ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      txt,
                      style: TextStyle(fontSize: 10.5, color: Colors.black.withOpacity(0.55)),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: lines,
        ),
      ),
    );
  }
}
