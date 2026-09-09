import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/di/app_di.dart';
import 'app_shell.dart';

class EnvironmentalScreen extends StatefulWidget {
  const EnvironmentalScreen({super.key});

  @override
  State<EnvironmentalScreen> createState() => _EnvironmentalScreenState();
}

class _EnvironmentalScreenState extends State<EnvironmentalScreen> {
  Timer? _pollingTimer;
  bool _loading = true;
  String? _error;

  double _temperature = 23.4;
  double _humidity = 48.0;
  double _airQuality = 385.0;
  double _light = 340.0;
  double _noise = 42.0;

  List<Map<String, dynamic>> _historyLogs = [];
  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchData(silent: true));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final dashboardFuture = apiClient.getAuthed('/api/iot/dashboard');
      final historyFuture = apiClient.getAuthed('/api/iot/history');

      final results = await Future.wait([dashboardFuture, historyFuture]);
      final dashRes = results[0] as Map<String, dynamic>;
      final histRes = results[1];

      List<dynamic> rawLogs = [];
      if (histRes is List) {
        rawLogs = histRes;
      } else if (histRes is Map && histRes.containsKey('history')) {
        rawLogs = (histRes['history'] as List?) ?? [];
      }

      if (mounted) {
        setState(() {
          _temperature = (dashRes['temperature'] as num?)?.toDouble() ?? _temperature;
          _humidity = (dashRes['humidity'] as num?)?.toDouble() ?? _humidity;
          _airQuality = (dashRes['airQuality'] as num?)?.toDouble() ?? _airQuality;
          _light = (dashRes['light'] as num?)?.toDouble() ?? _light;
          _noise = (dashRes['noise'] as num?)?.toDouble() ?? _noise;

          _historyLogs = rawLogs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _lastUpdated = DateTime.now();
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Environmental Monitoring',
      subtitle: 'Live IoT telemetry and historical analytics',
      selectedRoute: '/environmental',
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Live IoT (${_lastUpdated.hour.toString().padLeft(2, '0')}:${_lastUpdated.minute.toString().padLeft(2, '0')}:${_lastUpdated.second.toString().padLeft(2, '0')})',
                style: const TextStyle(
                  color: Color(0xFF047857),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Refresh Telemetry',
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2D66F6)),
          onPressed: () => _fetchData(),
        ),
      ],
      body: _loading && _historyLogs.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Error updating IoT telemetry: $_error',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _fetchData(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),

                // Metrics grid
                _MetricsGrid(
                  temperature: _temperature,
                  humidity: _humidity,
                  airQuality: _airQuality,
                  light: _light,
                  noise: _noise,
                ),
                const SizedBox(height: 16),

                // Real-time History Chart Section
                _HistoryChartSection(logs: _historyLogs),
                const SizedBox(height: 16),

                // Alert Thresholds Section
                const _AlertThresholdsCard(),
              ],
            ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.temperature,
    required this.humidity,
    required this.airQuality,
    required this.light,
    required this.noise,
  });

  final double temperature;
  final double humidity;
  final double airQuality;
  final double light;
  final double noise;

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;
  bool _mid(BuildContext c) => MediaQuery.of(c).size.width >= 680;

  @override
  Widget build(BuildContext context) {
    final columns = _wide(context) ? 3 : (_mid(context) ? 2 : 1);

    return LayoutBuilder(builder: (_, c) {
      final spacing = 14.0;
      final w = c.maxWidth;
      final itemW = (w - (columns - 1) * spacing) / columns;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          SizedBox(
            width: itemW,
            child: _MiniMetric(
              title: 'Temperature',
              value: temperature.toStringAsFixed(1),
              unit: '°C',
              status: temperature > 28 ? 'high' : 'normal',
              statusColor: temperature > 28 ? Colors.orange : Colors.green,
            ),
          ),
          SizedBox(
            width: itemW,
            child: _MiniMetric(
              title: 'Humidity',
              value: humidity.toStringAsFixed(1),
              unit: '%',
              status: humidity > 70 ? 'high' : 'normal',
              statusColor: humidity > 70 ? Colors.orange : Colors.green,
            ),
          ),
          SizedBox(
            width: itemW,
            child: _MiniMetric(
              title: 'Air Quality',
              value: airQuality.toStringAsFixed(1),
              unit: 'PPM',
              status: airQuality > 450 ? 'warning' : 'healthy',
              statusColor: airQuality > 450 ? Colors.red : Colors.green,
            ),
          ),
          SizedBox(
            width: itemW,
            child: _MiniMetric(
              title: 'Ambient Light',
              value: light.toStringAsFixed(1),
              unit: 'Lux',
              status: 'optimal',
              statusColor: Colors.blue,
            ),
          ),
          SizedBox(
            width: itemW,
            child: _MiniMetric(
              title: 'Noise Level',
              value: noise.toStringAsFixed(1),
              unit: 'dB',
              status: noise > 60 ? 'noisy' : 'quiet',
              statusColor: noise > 60 ? Colors.orange : Colors.green,
            ),
          ),
        ],
      );
    });
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusColor,
  });

  final String title;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.w800,
            ),
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
              Icon(Icons.circle, size: 8, color: statusColor),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryChartSection extends StatelessWidget {
  const _HistoryChartSection({required this.logs});
  final List<Map<String, dynamic>> logs;

  @override
  Widget build(BuildContext context) {
    // Generate FlSpots from logs
    final List<FlSpot> tempSpots = [];
    final List<FlSpot> humSpots = [];
    final List<FlSpot> airSpots = [];
    final Map<double, String> labels = {};

    final count = logs.isEmpty ? 5 : logs.length;
    for (int i = 0; i < count; i++) {
      final double x = i.toDouble();
      if (logs.isNotEmpty && i < logs.length) {
        final item = logs[i];
        final t = (item['temperature'] as num?)?.toDouble() ?? 23.0;
        final h = (item['humidity'] as num?)?.toDouble() ?? 50.0;
        final a = (item['airQuality'] as num?)?.toDouble() ?? 380.0;
        tempSpots.add(FlSpot(x, t));
        humSpots.add(FlSpot(x, h));
        airSpots.add(FlSpot(x, a));

        if (item['timestamp'] != null) {
          try {
            final dt = DateTime.parse(item['timestamp'].toString()).toLocal();
            labels[x] = '${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
          } catch (_) {
            labels[x] = '${i}m';
          }
        }
      } else {
        // Fallback smooth baseline
        tempSpots.add(FlSpot(x, 22.5 + (i * 0.3)));
        humSpots.add(FlSpot(x, 50.0 - (i * 0.5)));
        airSpots.add(FlSpot(x, 370.0 + (i * 3.0)));
        labels[x] = '${(count - 1 - i) * 3}m ago';
      }
    }

    final maxX = (count - 1).toDouble().clamp(1.0, 100.0);

    final tempLine = LineChartBarData(
      isCurved: true,
      curveSmoothness: 0.35,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: const Color(0xFF2D66F6).withOpacity(0.08),
      ),
      barWidth: 2.5,
      color: const Color(0xFF2D66F6),
      spots: tempSpots,
    );

    final humLine = LineChartBarData(
      isCurved: true,
      curveSmoothness: 0.35,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
      barWidth: 2.5,
      color: const Color(0xFF16A34A),
      spots: humSpots,
    );

    final airLine = LineChartBarData(
      isCurved: true,
      curveSmoothness: 0.35,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: const Color(0xFFF59E0B).withOpacity(0.08),
      ),
      barWidth: 2.5,
      color: const Color(0xFFF59E0B),
      spots: airSpots,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 12),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Live Telemetry Charts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              _LegendBadge(color: const Color(0xFF2D66F6), label: 'Temp (°C)'),
              const SizedBox(width: 10),
              _LegendBadge(color: const Color(0xFF16A34A), label: 'Humidity (%)'),
              const SizedBox(width: 10),
              _LegendBadge(color: const Color(0xFFF59E0B), label: 'Air Quality (PPM)'),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Temperature & Humidity (°C / %)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 10),
          _ChartCard(
            height: 220,
            lines: [tempLine, humLine],
            minX: 0,
            maxX: maxX,
            minY: 0,
            maxY: 100,
            bottomLabels: labels,
          ),
          const SizedBox(height: 20),
          const Text(
            'Air Quality (PPM)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 10),
          _ChartCard(
            height: 220,
            lines: [airLine],
            minX: 0,
            maxX: maxX,
            minY: 300,
            maxY: 500,
            bottomLabels: labels,
          ),
        ],
      ),
    );
  }
}

class _LegendBadge extends StatelessWidget {
  const _LegendBadge({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
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
  final Map<double, String>? bottomLabels;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 14, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
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
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.black.withOpacity(0.05),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.black.withOpacity(0.03),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: Colors.black.withOpacity(0.1)),
              bottom: BorderSide(color: Colors.black.withOpacity(0.1)),
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
                reservedSize: 36,
                interval: (maxY - minY) / 4,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    v.toStringAsFixed(0),
                    style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.55)),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final txt = bottomLabels?[v] ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      txt,
                      style: TextStyle(fontSize: 9.5, color: Colors.black.withOpacity(0.5)),
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

class _AlertThresholdsCard extends StatelessWidget {
  const _AlertThresholdsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 12),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alert Threshold Configuration',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _ThresholdItem(
                  label: 'Temperature Warning (°C)',
                  value: '26.0°C',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _ThresholdItem(
                  label: 'Humidity Warning (%)',
                  value: '70.0%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _ThresholdItem(
                  label: 'Air Quality Warning (PPM)',
                  value: '450 PPM',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _ThresholdItem(
                  label: 'Noise Level Warning (dB)',
                  value: '60.0 dB',
                ),
              ),
            ],
          ),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}
