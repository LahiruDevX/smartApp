
/*
import 'package:flutter/material.dart';
import 'app_shell.dart';
import 'ai_chat_screen.dart';

class AiTeacherScreen extends StatelessWidget {
  const AiTeacherScreen({super.key});

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;
  bool _mid(BuildContext c) => MediaQuery.of(c).size.width >= 680;

  @override
  Widget build(BuildContext context) {
    final cols = _wide(context) ? 5 : (_mid(context) ? 3 : 1);

    return AppShell(
      title: 'AI Teaching Assistant',
      subtitle:
          'Your personalized learning companion for interactive education',
      selectedRoute: '/ai-teacher',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose a Subject',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _Grid(
            columns: cols,
            children: [
             _SubjectCard(
  title: 'Mathematics',
  icon: Icons.menu_book_outlined,
  circleBg: const Color(0xFFDCEBFF),
  barColor: const Color(0xFF2563EB),
  levelText: 'Skill Level  7/10',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AiChatScreen(subject: "Mathematics"),
    ),
  ),
),
_SubjectCard(
  title: 'Computer\nScience',
  icon: Icons.code_rounded,
  circleBg: const Color(0xFFDDFBE7),
  barColor: const Color(0xFF16A34A),
  levelText: 'Skill Level  6/10',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AiChatScreen(subject: "Computer Science"),
    ),
  ),
),
_SubjectCard(
  title: 'Science',
  icon: Icons.science_outlined,
  circleBg: const Color(0xFFF1E8FF),
  barColor: const Color(0xFF7C3AED),
  levelText: 'Skill Level  5/10',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AiChatScreen(subject: "Science"),
    ),
  ),
),
_SubjectCard(
  title: 'Languages',
  icon: Icons.public,
  circleBg: const Color(0xFFFFF0D6),
  barColor: const Color(0xFFF59E0B),
  levelText: 'Skill Level  0/10',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AiChatScreen(subject: "Languages"),
    ),
  ),
),
_SubjectCard(
  title: 'History',
  icon: Icons.access_time_rounded,
  circleBg: const Color(0xFFFFE1E1),
  barColor: const Color(0xFFEF4444),
  levelText: 'Skill Level  0/10',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AiChatScreen(subject: "History"),
    ),
  ),
),
            ],
          ),
          const SizedBox(height: 16),
          _TwoCardsRow(
            left: _CardSection(
              title: 'Your Progress',
              trailing: Icon(Icons.trending_up,
                  color: Colors.black.withOpacity(0.55)),
              child: Column(
                children: const [
                  _ProgressRow(
                    label: 'Mathematics',
                    rightText: '4 hrs 0 mins',
                    value: 0.72,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(height: 14),
                  _ProgressRow(
                    label: 'Computer Science',
                    rightText: '3 hrs 0 mins',
                    value: 0.58,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(height: 14),
                  _ProgressRow(
                    label: 'Science',
                    rightText: '2 hrs 0 mins',
                    value: 0.42,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(height: 14),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'View Detailed Progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
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
                    'No recommended lessons at this time. Start by\nexploring a subject!',
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
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B3DFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 13),
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
}

/* ---------------- helpers ---------------- */

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
    required this.levelText,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color circleBg;
  final Color barColor;
  final String levelText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 150,
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
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900)),
              const Spacer(),
              Text(levelText,
                  style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _parseSkill(levelText),
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

  double _parseSkill(String t) {
    // "Skill Level  7/10"
    final parts = t.split(' ');
    final frac = parts.isNotEmpty ? parts.last : '0/10';
    final nums = frac.split('/');
    if (nums.length != 2) return 0;
    final a = double.tryParse(nums[0]) ?? 0;
    final b = double.tryParse(nums[1]) ?? 10;
    if (b == 0) return 0;
    return (a / b).clamp(0, 1);
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
            backgroundColor: const Color(0xFF1F2937),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'app_shell.dart';
import 'ai_chat_screen.dart';

class AiTeacherScreen extends StatefulWidget {
  const AiTeacherScreen({super.key});

  @override
  State<AiTeacherScreen> createState() => _AiTeacherScreenState();
}

class _AiTeacherScreenState extends State<AiTeacherScreen> {
  late final WebViewController _controller;

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;
  bool _mid(BuildContext c) => MediaQuery.of(c).size.width >= 680;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('http://192.168.71.63:4000'));
  }

  @override
  Widget build(BuildContext context) {
    final cols = _wide(context) ? 5 : (_mid(context) ? 3 : 1);

    return AppShell(
      title: 'AI Teaching Assistant',
      subtitle:
          'Your personalized learning companion for interactive education',
      selectedRoute: '/ai-teacher',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── 3D Teacher Model ──────────────────────────────────────
          Container(
            height: 280,
            width: double.infinity,
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
            clipBehavior: Clip.hardEdge,
            child: WebViewWidget(controller: _controller),
          ),
          const SizedBox(height: 20),

          // ── Subject Cards ─────────────────────────────────────────
          const Text('Choose a Subject',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _Grid(
            columns: cols,
            children: [
              _SubjectCard(
                title: 'Mathematics',
                icon: Icons.menu_book_outlined,
                circleBg: const Color(0xFFDCEBFF),
                barColor: const Color(0xFF2563EB),
                levelText: 'Skill Level  7/10',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AiChatScreen(subject: "Mathematics"),
                  ),
                ),
              ),
              _SubjectCard(
                title: 'Computer\nScience',
                icon: Icons.code_rounded,
                circleBg: const Color(0xFFDDFBE7),
                barColor: const Color(0xFF16A34A),
                levelText: 'Skill Level  6/10',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AiChatScreen(subject: "Computer Science"),
                  ),
                ),
              ),
              _SubjectCard(
                title: 'Science',
                icon: Icons.science_outlined,
                circleBg: const Color(0xFFF1E8FF),
                barColor: const Color(0xFF7C3AED),
                levelText: 'Skill Level  5/10',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AiChatScreen(subject: "Science"),
                  ),
                ),
              ),
              _SubjectCard(
                title: 'Languages',
                icon: Icons.public,
                circleBg: const Color(0xFFFFF0D6),
                barColor: const Color(0xFFF59E0B),
                levelText: 'Skill Level  0/10',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AiChatScreen(subject: "Languages"),
                  ),
                ),
              ),
              _SubjectCard(
                title: 'History',
                icon: Icons.access_time_rounded,
                circleBg: const Color(0xFFFFE1E1),
                barColor: const Color(0xFFEF4444),
                levelText: 'Skill Level  0/10',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AiChatScreen(subject: "History"),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Progress & Recommendations ────────────────────────────
          _TwoCardsRow(
            left: _CardSection(
              title: 'Your Progress',
              trailing: Icon(Icons.trending_up,
                  color: Colors.black.withOpacity(0.55)),
              child: Column(
                children: const [
                  _ProgressRow(
                    label: 'Mathematics',
                    rightText: '4 hrs 0 mins',
                    value: 0.72,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(height: 14),
                  _ProgressRow(
                    label: 'Computer Science',
                    rightText: '3 hrs 0 mins',
                    value: 0.58,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(height: 14),
                  _ProgressRow(
                    label: 'Science',
                    rightText: '2 hrs 0 mins',
                    value: 0.42,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(height: 14),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'View Detailed Progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
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
                    'No recommended lessons at this time. Start by\nexploring a subject!',
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
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B3DFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 13),
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
}

/* ---------------- helpers ---------------- */

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
    required this.levelText,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color circleBg;
  final Color barColor;
  final String levelText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 150,
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
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900)),
              const Spacer(),
              Text(levelText,
                  style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _parseSkill(levelText),
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

  double _parseSkill(String t) {
    final parts = t.split(' ');
    final frac = parts.isNotEmpty ? parts.last : '0/10';
    final nums = frac.split('/');
    if (nums.length != 2) return 0;
    final a = double.tryParse(nums[0]) ?? 0;
    final b = double.tryParse(nums[1]) ?? 10;
    if (b == 0) return 0;
    return (a / b).clamp(0, 1);
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
            backgroundColor: const Color(0xFF1F2937),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}