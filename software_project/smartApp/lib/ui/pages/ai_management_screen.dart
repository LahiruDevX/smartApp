import 'package:flutter/material.dart';

import '../../core/di/app_di.dart';
import 'app_shell.dart';

/// Staff view of the AI teachers (GET /api/ai/overview): for each subject,
/// its teacher, the course materials uploaded for it, whether those are
/// indexed for RAG yet, and how many questions students have asked.
class AiManagementScreen extends StatefulWidget {
  const AiManagementScreen({super.key});

  @override
  State<AiManagementScreen> createState() => _AiManagementScreenState();
}

class _AiManagementScreenState extends State<AiManagementScreen> {
  List<Map<String, dynamic>>? _subjects;
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
      final d = await apiClient.getAuthed('/api/ai/overview');
      if (mounted) {
        setState(() => _subjects =
            (d['subjects'] as List).cast<Map<String, dynamic>>());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'AI Teacher Management',
      subtitle: 'Each subject\'s AI teacher, its course materials and usage',
      selectedRoute: '/ai-management',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _load,
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/materials'),
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Upload Materials'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
            ),
          ),
        ),
      ],
      body: _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not load AI teachers\n$_error',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : _subjects == null
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HowItWorks(),
                    const SizedBox(height: 14),
                    _WrapGrid(
                      columns: _wide(context) ? 3 : (_mid(context) ? 2 : 1),
                      children: [
                        for (final s in _subjects!) _TeacherCard(s: s),
                      ],
                    ),
                  ],
                ),
    );
  }
}

/// One-line explanation of RAG for staff (and evaluators).
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Each AI teacher answers from its subject\'s uploaded materials '
              '(RAG) and its own general knowledge. Uploaded PDF/Word files '
              'are split into passages and indexed automatically; answers '
              'that used them show a "Source" line.',
              style: TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  const _TeacherCard({required this.s});
  final Map<String, dynamic> s;

  Color get _accent {
    final hex = (s['accent'] ?? '#2563EB').toString().replaceFirst('#', '');
    return Color(int.tryParse('FF$hex', radix: 16) ?? 0xFF2563EB);
  }

  /// RAG readiness from the passage counts.
  (String, Color, IconData) get _ragStatus {
    final subject = s['subject'].toString();
    final chunks = s['chunks'] as int;
    final embedded = s['embedded'] as int;
    if (subject == 'General') {
      return ('General knowledge only', Colors.black54, Icons.public);
    }
    if (chunks == 0) {
      return ('No materials — general knowledge only', const Color(0xFFB45309),
          Icons.info_outline);
    }
    if (embedded < chunks) {
      return ('Indexing $embedded/$chunks passages…', const Color(0xFF2563EB),
          Icons.hourglass_top);
    }
    return ('RAG ready · $chunks passages', const Color(0xFF16A34A),
        Icons.check_circle_outline);
  }

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _ragStatus;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 12),
            color: Colors.black.withOpacity(0.07),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _accent.withOpacity(0.15),
                child: Icon(Icons.smart_toy_outlined, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['subject'].toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 14.5)),
                    Text(s['teacher'].toString(),
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.6))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(label: 'Materials', value: '${s['materials']}'),
              _Stat(label: 'Questions', value: '${s['questions']}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label,
              style: TextStyle(
                  fontSize: 11.5, color: Colors.black.withOpacity(0.55))),
        ],
      ),
    );
  }
}

class _WrapGrid extends StatelessWidget {
  const _WrapGrid({required this.columns, required this.children});
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      const spacing = 14.0;
      final itemW = (c.maxWidth - (columns - 1) * spacing) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children:
            children.map((e) => SizedBox(width: itemW, child: e)).toList(),
      );
    });
  }
}
