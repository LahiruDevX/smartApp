import 'package:flutter/material.dart';

import '../../core/di/app_di.dart';
import '../../features/learning/learning_service.dart';
import 'app_shell.dart';

class AiTeacherScreen extends StatefulWidget {
  const AiTeacherScreen({super.key});

  @override
  State<AiTeacherScreen> createState() => _AiTeacherScreenState();
}

class _AiTeacherScreenState extends State<AiTeacherScreen> {
  bool _loading = true;
  String? _error;
  List<Subject> _subjects = const [];
  List<ChatSession> _sessions = const [];
  Map<String, TeacherInfo> _teachers = const {};

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;
  bool _mid(BuildContext c) => MediaQuery.of(c).size.width >= 680;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final o = await learningService.overview();
      List<ChatSession> sessions = const [];
      try {
        sessions = await learningService.chatSessions();
      } catch (_) {}
      Map<String, TeacherInfo> teachers = const {};
      try {
        teachers = await learningService.teachers();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _subjects = o.subjects;
        _sessions = sessions;
        _teachers = teachers;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Opens the subject's classroom: its own teacher (3D avatar + chat).
  Future<void> _openSubject(String subject) async {
    await Navigator.pushNamed(context, '/ai-teacher-3d', arguments: subject);
    _load(); // refresh Chat History after returning
  }

  // Visual identity per subject (name -> icon/colours). Falls back gracefully.
  ({IconData icon, Color circle, Color bar}) _style(String name) {
    switch (name) {
      case 'Mathematics':
        return (
          icon: Icons.menu_book_outlined,
          circle: const Color(0xFFDCEBFF),
          bar: const Color(0xFF2563EB)
        );
      case 'Computer Science':
        return (
          icon: Icons.code_rounded,
          circle: const Color(0xFFDDFBE7),
          bar: const Color(0xFF16A34A)
        );
      case 'Science':
        return (
          icon: Icons.science_outlined,
          circle: const Color(0xFFF1E8FF),
          bar: const Color(0xFF7C3AED)
        );
      case 'Languages':
        return (
          icon: Icons.public,
          circle: const Color(0xFFFFF0D6),
          bar: const Color(0xFFF59E0B)
        );
      case 'History':
        return (
          icon: Icons.access_time_rounded,
          circle: const Color(0xFFFFE1E1),
          bar: const Color(0xFFEF4444)
        );
      default:
        return (
          icon: Icons.auto_stories_outlined,
          circle: const Color(0xFFEAF1FF),
          bar: const Color(0xFF2563EB)
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cols = _wide(context) ? 5 : (_mid(context) ? 3 : 1);

    return AppShell(
      title: 'AI Teaching Assistant',
      subtitle:
          'Your personalized learning companion for interactive education',
      selectedRoute: '/ai-teacher',
      body: _loading
          ? const SizedBox(
              height: 300, child: Center(child: CircularProgressIndicator()))
          : _error != null
              ? SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load subjects\n$_error',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        ElevatedButton(
                            onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Meet3dTeacherBanner(
                      onTap: () => _openSubject('General'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Choose a Subject',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    _Grid(
                      columns: cols,
                      children: [
                        for (final s in _subjects)
                          _SubjectCard(
                            title: s.name,
                            teacher: _teachers[s.name],
                            icon: _style(s.name).icon,
                            circleBg: _style(s.name).circle,
                            barColor: _style(s.name).bar,
                            skillLevel: s.skillLevel,
                            onTap: () => _openSubject(s.name),
                          ),
                      ],
                    ),
                    if (_sessions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _CardSection(
                        title: 'Chat History',
                        trailing: Icon(Icons.history,
                            color: Colors.black.withOpacity(0.55)),
                        child: Column(
                          children: [
                            for (final cs in _sessions)
                              _SessionRow(
                                session: cs,
                                onTap: () => _openSubject(cs.subject),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _TwoCardsRow(
                      left: _CardSection(
                        title: 'Your Progress',
                        trailing: Icon(Icons.trending_up,
                            color: Colors.black.withOpacity(0.55)),
                        child: Column(
                          children: [
                            for (final s in _subjects
                                .where((s) => s.studyMinutes > 0)
                                .take(4)) ...[
                              _ProgressRow(
                                label: s.name,
                                rightText: s.studyLabel,
                                value: s.skillFraction,
                                color: _style(s.name).bar,
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (_subjects.every((s) => s.studyMinutes == 0))
                              Text('No study time logged yet.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black.withOpacity(0.55))),
                            Align(
                              alignment: Alignment.center,
                              child: TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/progress'),
                                child: const Text(
                                  'View Detailed Progress',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      right: _CardSection(
                        title: 'Recommended Lessons',
                        trailing: Icon(Icons.auto_awesome,
                            color: const Color(0xFF7C3AED).withOpacity(0.85)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _recommendation(),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.55),
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 44,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/learning'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B3DFF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13),
                                ),
                                child: const Text('Explore All Lessons'),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _recommendation() {
    final weakest = [..._subjects]..sort((a, b) => a.skillLevel.compareTo(b.skillLevel));
    if (weakest.isEmpty) return 'Start by exploring a subject!';
    final s = weakest.first;
    return 'Focus area: ${s.name} (skill ${s.skillLevel.toStringAsFixed(0)}/10). '
        'Open it to start a guided session.';
  }
}

/* ---------------- helpers ---------------- */

class _Meet3dTeacherBanner extends StatelessWidget {
  const _Meet3dTeacherBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.view_in_ar_rounded,
                  color: Colors.white, size: 34),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Meet your 3D AI Teacher',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 3),
                    Text('Each subject below has its own teacher. Tap one to enter their classroom, or start here with the general tutor.',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
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
      const spacing = 14.0;
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

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.title,
    required this.icon,
    required this.circleBg,
    required this.barColor,
    required this.skillLevel,
    required this.onTap,
    this.teacher,
  });

  final String title;
  final TeacherInfo? teacher; // the subject's named teacher, if any
  final IconData icon;
  final Color circleBg;
  final Color barColor;
  final double skillLevel; // 0..10
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 158),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                offset: const Offset(0, 12),
                color: Colors.black.withOpacity(0.08),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(color: circleBg, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.black.withOpacity(0.75)),
              ),
              const SizedBox(height: 12),
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900)),
              if (teacher != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.view_in_ar_rounded,
                        size: 14, color: teacher!.accent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(teacher!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withOpacity(0.65))),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Text('Skill Level  ${skillLevel.toStringAsFixed(0)}/10',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (skillLevel / 10).clamp(0, 1).toDouble(),
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onTap});
  final ChatSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 18, color: Color(0xFF2563EB)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.subject,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(
                    session.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.black.withOpacity(0.55),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('${session.count} msg',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.45))),
            const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.rightText,
    required this.value,
    required this.color,
  });

  final String label;
  final String rightText;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w900))),
            Text(rightText,
                style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
