import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_shell.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _period = 'Last 30 days';
  DateTime _updatedAt = DateTime.now();
  final Set<String> _scheduledAlerts = {};

  static const _reports = <String, _AnalyticsReport>{
    'Last 7 days': _AnalyticsReport(
      attendance: '93.8%',
      attendanceChange: '+1.4% from previous week',
      energySaved: '14%',
      utilization: '82%',
      savings: r'$580',
      energy: [38, 46, 41, 50, 36],
      attendanceTrend: [92, 95, 93, 94],
      utilizationSplit: [36, 46, 18],
    ),
    'Last 30 days': _AnalyticsReport(
      attendance: '94.2%',
      attendanceChange: '+2.3% from last month',
      energySaved: '18%',
      utilization: '87%',
      savings: r'$2,340',
      energy: [45, 54, 48, 57, 42],
      attendanceTrend: [94, 96, 92, 95],
      utilizationSplit: [40, 40, 20],
    ),
    'This semester': _AnalyticsReport(
      attendance: '92.7%',
      attendanceChange: '+3.1% from last semester',
      energySaved: '21%',
      utilization: '84%',
      savings: r'$9,860',
      energy: [52, 48, 44, 46, 39],
      attendanceTrend: [89, 91, 94, 97],
      utilizationSplit: [42, 35, 23],
    ),
  };

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;
  bool _mid(BuildContext c) => MediaQuery.of(c).size.width >= 680;

  String get _updatedLabel {
    final hour = _updatedAt.hour == 0
        ? 12
        : (_updatedAt.hour > 12 ? _updatedAt.hour - 12 : _updatedAt.hour);
    final minute = _updatedAt.minute.toString().padLeft(2, '0');
    final suffix = _updatedAt.hour >= 12 ? 'PM' : 'AM';
    return 'Updated $hour:$minute $suffix';
  }

  void _refresh() {
    setState(() => _updatedAt = DateTime.now());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analytics data refreshed')),
    );
  }

  Future<void> _export(_AnalyticsReport report) async {
    final csv = <String>[
      'Metric,Value',
      'Report period,$_period',
      'Average attendance,${report.attendance}',
      'Energy saved,${report.energySaved}',
      'Room utilization,${report.utilization}',
      'Cost savings,${report.savings}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report copied as CSV')),
    );
  }

  Future<void> _schedule(String alert) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    setState(() => _scheduledAlerts.add(alert));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$alert scheduled for ${date.day}/${date.month}/${date.year}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kpiCols = _wide(context) ? 4 : (_mid(context) ? 2 : 1);
    final report = _reports[_period]!;

    return AppShell(
      title: 'Analytics & Reports',
      subtitle: 'Insights and trends for classroom management',
      selectedRoute: '/analytics',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportToolbar(
            period: _period,
            updatedLabel: _updatedLabel,
            onPeriodChanged: (value) => setState(() => _period = value),
            onRefresh: _refresh,
            onExport: () => _export(report),
          ),
          const SizedBox(height: 16),
          _Grid(
            columns: kpiCols,
            children: [
              _KpiCard(
                title: 'Avg.\nAttendance',
                value: report.attendance,
                note: report.attendanceChange,
                noteColor: const Color(0xFF16A34A),
              ),
              _KpiCard(
                title: 'Energy Saved',
                value: report.energySaved,
                note: 'Compared with baseline',
                noteColor: const Color(0xFF16A34A),
              ),
              _KpiCard(
                title: 'Room\nUtilization',
                value: report.utilization,
                note: 'Optimal range',
                noteColor: const Color(0xFF2563EB),
              ),
              _KpiCard(
                title: 'Cost Savings',
                value: report.savings,
                note: _period,
                noteColor: const Color(0xFF16A34A),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TwoCardsRow(
            left: _CardSection(
              title: 'Weekly Energy Usage',
              child: SizedBox(
                height: 240,
                child: _WeeklyBarChart(values: report.energy),
              ),
            ),
            right: _CardSection(
              title: 'Classroom Utilization',
              child: SizedBox(
                height: 240,
                child: _UtilizationPie(values: report.utilizationSplit),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _CardSection(
            title: 'Attendance Trends',
            child: SizedBox(
              height: 260,
              child: _AttendanceLine(values: report.attendanceTrend),
            ),
          ),
          const SizedBox(height: 16),
          _CardSection(
            title: 'Predictive Maintenance Alerts',
            child: Column(
              children: [
                _AlertTile(
                  title: 'HVAC Filter Replacement',
                  subtitle: 'Recommended in 5 days based on usage patterns',
                  bg: const Color(0xFFFFF7E6),
                  buttonColor: const Color(0xFFEA7B00),
                  scheduled:
                      _scheduledAlerts.contains('HVAC Filter Replacement'),
                  onSchedule: () => _schedule('HVAC Filter Replacement'),
                ),
                const SizedBox(height: 12),
                _AlertTile(
                  title: 'Projector Lamp Check',
                  subtitle: 'Approaching 80% of rated lifespan',
                  bg: const Color(0xFFEFF6FF),
                  buttonColor: const Color(0xFF2563EB),
                  scheduled: _scheduledAlerts.contains('Projector Lamp Check'),
                  onSchedule: () => _schedule('Projector Lamp Check'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsReport {
  const _AnalyticsReport({
    required this.attendance,
    required this.attendanceChange,
    required this.energySaved,
    required this.utilization,
    required this.savings,
    required this.energy,
    required this.attendanceTrend,
    required this.utilizationSplit,
  });

  final String attendance;
  final String attendanceChange;
  final String energySaved;
  final String utilization;
  final String savings;
  final List<double> energy;
  final List<double> attendanceTrend;
  final List<double> utilizationSplit;
}

/* ---------------- components ---------------- */

class _ReportToolbar extends StatelessWidget {
  const _ReportToolbar({
    required this.period,
    required this.updatedLabel,
    required this.onPeriodChanged,
    required this.onRefresh,
    required this.onExport,
  });

  final String period;
  final String updatedLabel;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onRefresh;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            initialValue: period,
            decoration: const InputDecoration(
              labelText: 'Report period',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                  value: 'Last 7 days', child: Text('Last 7 days')),
              DropdownMenuItem(
                  value: 'Last 30 days', child: Text('Last 30 days')),
              DropdownMenuItem(
                value: 'This semester',
                child: Text('This semester'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onPeriodChanged(value);
            },
          ),
        ),
        Text(updatedLabel, style: const TextStyle(color: Color(0xFF64748B))),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
        ),
        FilledButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Export CSV'),
        ),
      ],
    );
  }
}

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
        children:
            children.map((e) => SizedBox(width: itemW, child: e)).toList(),
      );
    });
  }
}

class _TwoCardsRow extends StatelessWidget {
  const _TwoCardsRow({required this.left, required this.right});
  final Widget left;
  final Widget right;

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;

  @override
  Widget build(BuildContext context) {
    if (_wide(context)) {
      return Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 14),
          Expanded(child: right),
        ],
      );
    }
    return Column(
      children: [
        left,
        const SizedBox(height: 14),
        right,
      ],
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
              style:
                  const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.note,
    required this.noteColor,
  });

  final String title;
  final String value;
  final String note;
  final Color noteColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.6),
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(note,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: noteColor)),
        ],
      ),
    );
  }
}

/* ---------------- charts ---------------- */

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: 60,
        minY: 0,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.black.withOpacity(0.06), strokeWidth: 1),
          drawVerticalLine: false,
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
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 15,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(v.toStringAsFixed(0),
                    style: TextStyle(
                        fontSize: 10.5, color: Colors.black.withOpacity(0.55))),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, meta) {
                const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(labels[i],
                      style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.black.withOpacity(0.55))),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++) _bar(i, values[i]),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 22,
          borderRadius: BorderRadius.circular(6),
          color: const Color(0xFF2D66F6),
        ),
      ],
    );
  }
}

class _UtilizationPie extends StatelessWidget {
  const _UtilizationPie({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    const labels = ['In use', 'Available', 'Maintenance'];
    const colors = [Color(0xFF2D66F6), Color(0xFF10B981), Color(0xFFF59E0B)];
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 34,
              sectionsSpace: 2,
              sections: [
                for (var i = 0; i < values.length; i++)
                  PieChartSectionData(
                    value: values[i],
                    color: colors[i],
                    title: '${values[i].toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < labels.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, color: colors[i]),
                    const SizedBox(width: 7),
                    Text(labels[i], style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AttendanceLine extends StatelessWidget {
  const _AttendanceLine({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minX: 1,
        maxX: 4,
        minY: 85,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 5,
          verticalInterval: 1,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.black.withOpacity(0.06), strokeWidth: 1),
          getDrawingVerticalLine: (v) =>
              FlLine(color: Colors.black.withOpacity(0.04), strokeWidth: 1),
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
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 4,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(v.toStringAsFixed(0),
                    style: TextStyle(
                        fontSize: 10.5, color: Colors.black.withOpacity(0.55))),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 1 || i > 4) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Week $i',
                      style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.black.withOpacity(0.55))),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            barWidth: 2.5,
            color: const Color(0xFF10B981),
            dotData: const FlDotData(show: true),
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot((i + 1).toDouble(), values[i]),
            ],
          ),
        ],
      ),
    );
  }
}

/* ---------------- alerts ---------------- */

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.buttonColor,
    required this.scheduled,
    required this.onSchedule,
  });

  final String title;
  final String subtitle;
  final Color bg;
  final Color buttonColor;
  final bool scheduled;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 13)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.black.withOpacity(0.55))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: scheduled ? null : onSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              child: Text(scheduled ? 'Scheduled' : 'Schedule'),
            ),
          ),
        ],
      ),
    );
  }
}
