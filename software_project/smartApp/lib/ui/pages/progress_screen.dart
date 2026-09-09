import 'package:flutter/material.dart';
import 'app_shell.dart';
import '../../core/di/app_di.dart';
import 'take_quiz_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;
  bool _mid(BuildContext c) => MediaQuery.of(c).size.width >= 680;

  @override
  Widget build(BuildContext context) {
    final kpiCols = _wide(context) ? 4 : (_mid(context) ? 2 : 1);

    return AppShell(
      title: 'Learning Progress',
      subtitle:
          'Track your learning journey and identify areas for improvement',
      selectedRoute: '/progress',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Grid(
            columns: kpiCols,
            children: const [
              _MiniKpi(
                title: 'Learning\nTime',
                big: '9h 0m',
                sub: 'Total time spent\nlearning',
                icon: Icons.schedule,
                iconBg: Color(0xFFDCEBFF),
                iconColor: Color(0xFF2563EB),
              ),
              _MiniKpi(
                title: 'Skill\nLevel',
                big: '6.0/10',
                sub: 'Average across\nall subjects',
                icon: Icons.trending_up,
                iconBg: Color(0xFFDDFBE7),
                iconColor: Color(0xFF16A34A),
              ),
              _MiniKpi(
                title: 'Subjects',
                big: '3',
                sub: 'Subjects being\nstudied',
                icon: Icons.menu_book,
                iconBg: Color(0xFFF1E8FF),
                iconColor: Color(0xFF7C3AED),
              ),
              _MiniKpi(
                title: 'Achievements',
                big: '5',
                sub: 'Learning badges\nearned',
                icon: Icons.emoji_events,
                iconBg: Color(0xFFFFF0D6),
                iconColor: Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _StudentQuizzesSection(), // NEW: Fetch and take quizzes
          const SizedBox(height: 16),
          _CardSection(
            title: 'Subject Progress',
            child: Column(
              children: const [
                _SubjectProgressRow(
                  title: 'Mathematics',
                  subtitle: '2 lessons completed',
                  scoreText: '7 /10',
                  value: 0.70,
                  color: Color(0xFF2563EB),
                ),
                SizedBox(height: 18),
                _SubjectProgressRow(
                  title: 'Computer Science',
                  subtitle: '1 lessons completed',
                  scoreText: '6 /10',
                  value: 0.60,
                  color: Color(0xFF16A34A),
                ),
                SizedBox(height: 18),
                _SubjectProgressRow(
                  title: 'Science',
                  subtitle: '0 lessons completed',
                  scoreText: '5 /10',
                  value: 0.50,
                  color: Color(0xFF7C3AED),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _TwoCardsRow(
            left: _CardSection(
              title: 'Areas for Improvement',
              trailing: const _TinyCircle(
                  icon: Icons.error_outline, color: Color(0xFFF59E0B)),
              child: Column(
                children: const [
                  _ImproveRow(label: 'Calculus'),
                  _ImproveRow(label: 'Trigonometry'),
                  _ImproveRow(label: 'Data Structures'),
                  _ImproveRow(label: 'Algorithms'),
                  _ImproveRow(label: 'Chemistry'),
                  _ImproveRow(label: 'Biology'),
                ],
              ),
            ),
            right: _CardSection(
              title: 'Your Learning Style',
              child: Column(
                children: const [
                  _StyleRow(
                      label: 'visual', value: 0.35, color: Color(0xFF2563EB)),
                  SizedBox(height: 12),
                  _StyleRow(
                      label: 'kinesthetic',
                      value: 0.35,
                      color: Color(0xFF16A34A)),
                  SizedBox(height: 12),
                  _StyleRow(
                      label: 'auditory', value: 0.35, color: Color(0xFF7C3AED)),
                  SizedBox(height: 12),
                  _InfoBox(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentQuizzesSection extends StatefulWidget {
  const _StudentQuizzesSection();
  @override
  State<_StudentQuizzesSection> createState() => _StudentQuizzesSectionState();
}

class _StudentQuizzesSectionState extends State<_StudentQuizzesSection> {
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
      if (mounted) setState(() {
        _evals = res as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: 'Your Scheduled Quizzes',
      trailing: IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _fetchEvals),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _evals.isEmpty
              ? const Text('No pending quizzes.', style: TextStyle(color: Colors.black54))
              : Column(
                  children: _evals.map((e) {
                    final isCompleted = e['completed'] == true;
                    final dateStr = e['scheduledDate']?.toString().split('T').first ?? '';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e['title'] ?? 'Quiz', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('${e['subject']} • $dateStr', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                if (isCompleted) 
                                  Text('Grade: ${e['grade']}/100', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ),
                          if (!isCompleted)
                            ElevatedButton(
                              onPressed: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => TakeQuizScreen(quiz: e)));
                                _fetchEvals();
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: const Text('Take Quiz'),
                            )
                        ],
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}

/* ---------------- UI ---------------- */

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              color: Colors.black.withOpacity(0.08)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w900))),
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

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({
    required this.title,
    required this.big,
    required this.sub,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String title;
  final String big;
  final String sub;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

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
              color: Colors.black.withOpacity(0.08)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(big,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(sub,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.black.withOpacity(0.55),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ],
      ),
    );
  }
}

class _SubjectProgressRow extends StatelessWidget {
  const _SubjectProgressRow({
    required this.title,
    required this.subtitle,
    required this.scoreText,
    required this.value,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String scoreText;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.black.withOpacity(0.55),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Text(scoreText,
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: const Color(0xFF374151),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _ImproveRow extends StatelessWidget {
  const _ImproveRow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
          const Text('Focus on this',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB))),
        ],
      ),
    );
  }
}

class _StyleRow extends StatelessWidget {
  const _StyleRow(
      {required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: Text('$label  Learner',
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            const Text('3%', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            backgroundColor: const Color(0xFF374151),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _TinyCircle extends StatelessWidget {
  const _TinyCircle({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration:
          BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Your learning style affects how you best\nabsorb information. The AI tutor adapts\nto your preferred style.',
        style: TextStyle(
            fontSize: 11.5,
            color: Colors.black.withOpacity(0.55),
            fontWeight: FontWeight.w700),
      ),
    );
  }
}
