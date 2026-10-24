import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/di/app_di.dart';
import 'app_shell.dart';

/// Classroom analytics built from real data (GET /api/analytics): attendance
/// over the last 7 days, AI-teacher usage per subject and quiz results.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _data;
  String? _error;

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;
  bool _mid(BuildContext c) => MediaQuery.of(c).size.width >= 680;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = await apiClient.getAuthed('/api/analytics');
      if (mounted) setState(() => _data = d);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Analytics & Reports',
      subtitle: 'Attendance, AI teacher usage and quiz results',
      selectedRoute: '/analytics',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not load analytics\n$_error',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : _data == null
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _body(context, _data!),
    );
  }

  Widget _body(BuildContext context, Map<String, dynamic> d) {
    final att = d['attendance'] as Map<String, dynamic>;
    final ai = d['ai'] as Map<String, dynamic>;
    final quiz = d['quizzes'] as Map<String, dynamic>;
    final days = (att['days'] as List).cast<Map<String, dynamic>>();
    final aiBySubject = (ai['bySubject'] as List).cast<Map<String, dynamic>>();
    final quizBySubject =
        (quiz['bySubject'] as List).cast<Map<String, dynamic>>();
    final kpiCols = _wide(context) ? 4 : (_mid(context) ? 2 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Grid(
          columns: kpiCols,
          children: [
            _KpiCard(
              title: 'Attendance\nToday',
              value: '${att['todayRate']}%',
              note: '${att['students']} enrolled students',
              noteColor: const Color(0xFF16A34A),
            ),
            _KpiCard(
              title: 'Avg. Attendance\n(last 7 days)',
              value: '${att['weekAvgRate']}%',
              note: 'Days with attendance taken',
              noteColor: const Color(0xFF2563EB),
            ),
            _KpiCard(
              title: 'AI Teacher\nQuestions',
              value: '${ai['questions']}',
              note: 'Asked by students, all subjects',
              noteColor: const Color(0xFF7C3AED),
            ),
            _KpiCard(
              title: 'Avg. Quiz\nScore',
              value: quiz['avgScore'] == null ? '—' : '${quiz['avgScore']}%',
              note: '${quiz['attempts']} quiz attempts',
              noteColor: const Color(0xFFEA7B00),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _CardSection(
          title: 'Attendance Rate — Last 7 Days',
          child: SizedBox(height: 240, child: _AttendanceLine(days: days)),
        ),
        const SizedBox(height: 16),
        _TwoCardsRow(
          left: _CardSection(
            title: 'AI Teacher Questions by Subject',
            child: SizedBox(
              height: 240,
              child: aiBySubject.isEmpty
                  ? const _Empty('No questions asked yet')
                  : _SubjectBars(
                      rows: aiBySubject,
                      valueKey: 'questions',
                      color: const Color(0xFF7C3AED),
                    ),
            ),
          ),
          right: _CardSection(
            title: 'Average Quiz Score by Subject (%)',
            child: SizedBox(
              height: 240,
              child: quizBySubject.isEmpty
                  ? const _Empty('No quiz attempts yet')
                  : _SubjectBars(
                      rows: quizBySubject,
                      valueKey: 'avgScore',
                      color: const Color(0xFFEA7B00),
                      maxY: 100,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ---------------- components ---------------- */

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
      constraints: const BoxConstraints(minHeight: 120),
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

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(text,
            style: TextStyle(
                fontSize: 13, color: Colors.black.withOpacity(0.5))),
      );
}

/* ---------------- charts ---------------- */

TextStyle get _axisStyle =>
    TextStyle(fontSize: 10.5, color: Colors.black.withOpacity(0.55));

FlBorderData get _axisBorder => FlBorderData(
      show: true,
      border: Border(
        left: BorderSide(color: Colors.black.withOpacity(0.12)),
        bottom: BorderSide(color: Colors.black.withOpacity(0.12)),
        right: const BorderSide(color: Colors.transparent),
        top: const BorderSide(color: Colors.transparent),
      ),
    );

/// One bar per subject. [valueKey] picks the number from each row.
class _SubjectBars extends StatelessWidget {
  const _SubjectBars({
    required this.rows,
    required this.valueKey,
    required this.color,
    this.maxY,
  });

  final List<Map<String, dynamic>> rows;
  final String valueKey;
  final Color color;
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    final values = rows.map((r) => (r[valueKey] as num? ?? 0).toDouble());
    final top = maxY ?? (values.reduce((a, b) => a > b ? a : b) * 1.2 + 1);

    return BarChart(
      BarChartData(
        maxY: top,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.black.withOpacity(0.06), strokeWidth: 1),
        ),
        borderData: _axisBorder,
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(v.toStringAsFixed(0), style: _axisStyle),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= rows.length) return const SizedBox.shrink();
                // short label so six subjects fit side by side
                final name = rows[i]['subject'].toString();
                final label = name.contains(' ')
                    ? name.split(' ').map((w) => w[0]).join()
                    : (name.length > 6 ? name.substring(0, 5) : name);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Tooltip(
                      message: name, child: Text(label, style: _axisStyle)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (final (i, v) in values.indexed)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: v,
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                  color: color,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AttendanceLine extends StatelessWidget {
  const _AttendanceLine({required this.days});
  final List<Map<String, dynamic>> days;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (days.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 25,
          verticalInterval: 1,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.black.withOpacity(0.06), strokeWidth: 1),
          getDrawingVerticalLine: (v) =>
              FlLine(color: Colors.black.withOpacity(0.04), strokeWidth: 1),
        ),
        borderData: _axisBorder,
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: 25,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text('${v.toStringAsFixed(0)}%', style: _axisStyle),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                final date = DateTime.parse(days[i]['date'].toString());
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_weekdays[date.weekday - 1], style: _axisStyle),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: false,
            barWidth: 2.5,
            color: const Color(0xFF10B981),
            dotData: const FlDotData(show: true),
            spots: [
              for (final (i, d) in days.indexed)
                FlSpot(i.toDouble(), (d['rate'] as num).toDouble()),
            ],
          ),
        ],
      ),
    );
  }
}
