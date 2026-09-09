import 'package:flutter/material.dart';
import '../../core/di/app_di.dart';
import 'app_shell.dart';
import 'create_evaluation_screen.dart';
import 'take_quiz_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;

  @override
  Widget build(BuildContext context) {
    final isTeacherOrAdmin = apiClient.currentRole != 'student';

    return AppShell(
      title: 'Class Schedule & Assessments',
      subtitle: 'Manage classroom bookings, timetable, and scheduled evaluations',
      selectedRoute: '/schedule',
      actions: [
        if (isTeacherOrAdmin)
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEvaluationScreen()),
                );
                if (created == true && context.mounted) {
                  // Handled via state reload
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Schedule Assessment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D66F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
          ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WeeklyScheduleCard(wide: _wide(context)),
            const SizedBox(height: 16),
            const _UpcomingClassesCard(),
          ],
        ),
      ),
    );
  }
}

class _WeeklyScheduleCard extends StatelessWidget {
  const _WeeklyScheduleCard({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday'];
    const times = [
      '8:00',
      '9:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00',
      '19:00'
    ];

    return _CardSection(
      title: 'Weekly Schedule - Room 301',
      trailing: Row(
        children: [
          _SmallBtn(label: 'Previous Week', onTap: () {}),
          const SizedBox(width: 10),
          _SmallBtn(label: 'Next Week', onTap: () {}),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 600, // minimum width to prevent squishing
          child: Column(
            children: [
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 90,
                      child: Text(
                        'Time',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                    ...days.map(
                      (d) => Expanded(
                        child: Text(
                          d,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 480,
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: times.length,
                  itemBuilder: (_, i) {
                    final t = times[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(
                              t,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.65),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          for (int d = 0; d < days.length; d++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: _slotCard(t, d),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotCard(String time, int dayIdx) {
    final isSlot = (dayIdx == 0 && time == '9:00') ||
        (dayIdx == 0 && time == '11:00') ||
        (dayIdx == 0 && time == '14:00');

    if (!isSlot) return const SizedBox(height: 50);

    String title = 'Computer\nScience 301';
    String sub = 'Dr. Smith';

    if (time == '11:00') {
      title = 'Mathematics\n201';
      sub = 'Prof. Johnson';
    }
    if (time == '14:00') {
      title = 'Physics Lab';
      sub = 'Dr. Williams';
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEBFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingClassesCard extends StatefulWidget {
  const _UpcomingClassesCard();

  @override
  State<_UpcomingClassesCard> createState() => _UpcomingClassesCardState();
}

class _UpcomingClassesCardState extends State<_UpcomingClassesCard> {
  List<dynamic> _evals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvals();
  }

  Future<void> _fetchEvals() async {
    setState(() => _loading = true);
    try {
      final res = await apiClient.getAuthed('/api/evaluations');
      if (mounted) {
        setState(() {
          _evals = res is List ? res : [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: 'Scheduled Evaluations & Quizzes (Live Grades Table)',
      trailing: IconButton(
        icon: const Icon(Icons.refresh, size: 20),
        tooltip: 'Refresh Assessments',
        onPressed: _fetchEvals,
      ),
      child: _loading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : _evals.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No evaluations scheduled yet.', style: TextStyle(color: Colors.black54)),
                  ),
                )
              : Column(
                  children: _evals.map((e) {
                    final isMap = e is Map;
                    final id = isMap ? (e['id'] as num?)?.toInt() ?? 0 : 0;
                    final title = isMap ? (e['title'] ?? 'AI Assessment').toString() : 'Assessment';
                    final subject = isMap ? (e['subject'] ?? 'Mathematics').toString() : 'General';
                    final completed = isMap && e['completed'] == true;
                    final grade = isMap ? (e['grade'] as num?)?.toDouble() : null;
                    final dateStr = isMap ? (e['scheduledDate']?.toString().split('T').first ?? 'Today') : 'Today';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: completed ? const Color(0xFFDDFBE7) : const Color(0xFFDCEBFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                completed ? Icons.check_circle_outline : Icons.quiz_outlined,
                                color: completed ? const Color(0xFF16A34A) : const Color(0xFF2D66F6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$subject  •  Scheduled: $dateStr',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.black.withOpacity(0.55),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (completed) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDDFBE7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  grade != null ? 'Grade: ${grade.toStringAsFixed(1)}%' : 'Completed',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ] else ...[
                              SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final taken = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TakeQuizScreen(
                                          evaluationId: id,
                                          title: title,
                                          subject: subject,
                                        ),
                                      ),
                                    );
                                    if (taken == true) {
                                      _fetchEvals();
                                    }
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                  label: const Text('Take Quiz'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}

/* ------- Shared UI ------- */

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  const _SmallBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEFF4FF),
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
        child: Text(label),
      ),
    );
  }
}
