import 'package:flutter/material.dart';

import '../../core/di/app_di.dart';
import 'app_shell.dart';

/// Teacher/admin oversight: pick a student, then read their conversations
/// with each subject's AI teacher (GET /api/ai/students[/:id/chats]).
/// Read-only — staff can't send or delete messages here.
class StudentChatsScreen extends StatefulWidget {
  const StudentChatsScreen({super.key});

  @override
  State<StudentChatsScreen> createState() => _StudentChatsScreenState();
}

class _StudentChatsScreenState extends State<StudentChatsScreen> {
  List<Map<String, dynamic>>? _students;
  String? _error;

  int? _selectedId;
  List<Map<String, dynamic>>? _sessions; // the selected student's chats
  bool _loadingChats = false;
  String? _subject; // selected subject within the student's chats

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _error = null);
    try {
      final d = await apiClient.getAuthed('/api/ai/students');
      final list = (d['students'] as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() => _students = list);
      if (_selectedId == null && list.isNotEmpty) _select(list.first['id'] as int);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _select(int id) async {
    setState(() {
      _selectedId = id;
      _loadingChats = true;
      _sessions = null;
      _subject = null;
    });
    try {
      final d = await apiClient.getAuthed('/api/ai/students/$id/chats');
      final sessions = (d['sessions'] as List).cast<Map<String, dynamic>>();
      if (!mounted || _selectedId != id) return;
      setState(() {
        _sessions = sessions;
        _subject = sessions.isEmpty ? null : sessions.first['subject'] as String;
        _loadingChats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sessions = const [];
        _loadingChats = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not load chats: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Student Chats',
      subtitle: 'Read each student\'s conversations with the AI teachers',
      selectedRoute: '/student-chats',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () {
            _loadStudents();
            if (_selectedId != null) _select(_selectedId!);
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not load students\n$_error',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  TextButton(
                      onPressed: _loadStudents, child: const Text('Retry')),
                ],
              ),
            )
          : _students == null
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _students!.isEmpty
                  ? const _Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No student accounts yet.'),
                      ),
                    )
                  : _wide(context)
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 300, child: _studentList()),
                            const SizedBox(width: 14),
                            Expanded(child: _chatPanel()),
                          ],
                        )
                      : Column(
                          children: [
                            _studentList(),
                            const SizedBox(height: 14),
                            _chatPanel(),
                          ],
                        ),
    );
  }

  Widget _studentList() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text('Students',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
          ),
          for (final s in _students!)
            ListTile(
              selected: s['id'] == _selectedId,
              selectedTileColor: const Color(0xFFEFF6FF),
              leading: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFDBEAFE),
                child: Icon(Icons.person, size: 18, color: Color(0xFF2563EB)),
              ),
              title: Text(s['email'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: Text(
                (s['questions'] as int) == 0
                    ? 'No AI chats yet'
                    : '${s['questions']} questions · ${s['subjects']} subjects'
                        ' · ${_when(s['lastAt'])}',
                style: const TextStyle(fontSize: 11.5),
              ),
              onTap: () => _select(s['id'] as int),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _chatPanel() {
    if (_loadingChats) {
      return const _Card(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final sessions = _sessions ?? const [];
    if (sessions.isEmpty) {
      return const _Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('This student has not chatted with an AI teacher yet.'),
        ),
      );
    }
    final current = sessions.firstWhere((s) => s['subject'] == _subject,
        orElse: () => sessions.first);
    final messages = (current['messages'] as List).cast<Map<String, dynamic>>();

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in sessions)
                  ChoiceChip(
                    label: Text(
                        '${s['subject']} (${(s['messages'] as List).length})'),
                    selected: s['subject'] == current['subject'],
                    onSelected: (_) =>
                        setState(() => _subject = s['subject'] as String),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            for (final m in messages) _Bubble(m: m),
          ],
        ),
      ),
    );
  }
}

/// "5 Oct, 2:32 PM" in local time.
String _when(Object? iso) {
  if (iso == null) return '';
  final t = DateTime.parse(iso.toString()).toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '${t.day} ${months[t.month - 1]}, $h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.m});
  final Map<String, dynamic> m;

  @override
  Widget build(BuildContext context) {
    final isStudent = m['role'] == 'user';
    return Align(
      alignment: isStudent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
        decoration: BoxDecoration(
          color: isStudent ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isStudent ? 'Student' : 'AI teacher',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: isStudent ? Colors.white70 : Colors.black45,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              m['content'].toString(),
              style: TextStyle(
                color: isStudent ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _when(m['createdAt']),
              style: TextStyle(
                fontSize: 10,
                color: isStudent ? Colors.white60 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 12),
            color: Colors.black.withOpacity(0.07),
          ),
        ],
      ),
      child: child,
    );
  }
}
