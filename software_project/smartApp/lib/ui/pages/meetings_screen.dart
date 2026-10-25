import 'package:flutter/material.dart';

import '../../core/di/app_di.dart';
import '../../features/meetings/meeting_service.dart';
import '../theme/chalk_shapes.dart';
import '../theme/chalk_theme.dart';
import 'app_shell.dart';
import 'schedule_meeting_screen.dart';
import 'meeting_room_screen.dart';

/// Video-call lectures. Teachers schedule and review attendance; students
/// join from here. Admins get a read-only view — the backend reserves
/// scheduling and attendance review for teachers, and joining for students.
class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  bool _loading = true;
  String? _error;
  List<Meeting> _meetings = const [];

  bool get _isTeacher => authService.user.value?.role == 'teacher';
  bool get _isStudent => authService.user.value?.role == 'student';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await meetingService.list();
      if (!mounted) return;
      setState(() {
        _meetings = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _scheduleMeeting() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleMeetingScreen()),
    );
    if (created == true) _load();
  }

  Future<void> _openRoom(Meeting meeting) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MeetingRoomScreen(meeting: meeting)),
    );
    _load();
  }

  Future<void> _viewAttendance(Meeting meeting) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => _MeetingAttendanceScreen(meeting: meeting)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Meetings',
      subtitle: _isTeacher
          ? 'Schedule and run live video lectures'
          : 'Join your class video calls',
      selectedRoute: '/meetings',
      solidBackground: ChalkColors.paper,
      actions: _isTeacher
          ? [
              FilledButton.icon(
                onPressed: _scheduleMeeting,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Schedule Meeting'),
              ),
            ]
          : null,
      body: _loading
          ? const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator()))
          : _error != null
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load meetings\n$_error',
                            textAlign: TextAlign.center,
                            style: ChalkText.body()),
                        const SizedBox(height: 10),
                        ElevatedButton(
                            onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _meetings.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          _isTeacher
                              ? 'No meetings scheduled yet.'
                              : 'No meetings yet.',
                          style: ChalkText.body(
                              color: ChalkColors.ink.withOpacity(0.5)),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (final m in _meetings) ...[
                          _MeetingCard(
                            meeting: m,
                            isTeacher: _isTeacher,
                            isStudent: _isStudent,
                            onOpen: () => _openRoom(m),
                            onViewAttendance: () => _viewAttendance(m),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({
    required this.meeting,
    required this.isTeacher,
    required this.isStudent,
    required this.onOpen,
    required this.onViewAttendance,
  });

  final Meeting meeting;
  final bool isTeacher;
  final bool isStudent;
  final VoidCallback onOpen;
  final VoidCallback onViewAttendance;

  Color get _statusColor {
    switch (meeting.status) {
      case 'live':
        return ChalkColors.chalkCoral;
      case 'ended':
        return ChalkColors.ink.withOpacity(0.35);
      default:
        return ChalkColors.chalkSky;
    }
  }

  String _formatDateTime(DateTime d) {
    final local = d.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 12),
            color: ChalkColors.ink.withOpacity(0.08),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.videocam_outlined, color: _statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meeting.title, style: ChalkText.heading(size: 15)),
                const SizedBox(height: 3),
                Text(
                  '${meeting.subjectName ?? 'General'} · ${_formatDateTime(meeting.scheduledAt)} · ${meeting.durationMinutes} min',
                  style: ChalkText.body(
                      size: 11.5, color: ChalkColors.ink.withOpacity(0.55)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    meeting.status.toUpperCase(),
                    style: ChalkText.body(
                        size: 10.5,
                        weight: FontWeight.w800,
                        color: _statusColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isTeacher) ...[
            if (meeting.status != 'scheduled')
              TextButton.icon(
                onPressed: onViewAttendance,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('Attendance'),
              ),
            if (meeting.status != 'ended')
              ChalkTapScale(
                onTap: onOpen,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: ChalkColors.chalkboard,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Open Call',
                    style: ChalkText.body(
                        size: 12.5,
                        weight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
          ],
          if (isStudent)
            ChalkTapScale(
              onTap: meeting.isJoinable ? onOpen : () {},
              child: Opacity(
                opacity: meeting.isJoinable ? 1 : 0.4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: ChalkColors.chalkboard,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    meeting.isJoinable ? 'Join' : 'Not yet',
                    style: ChalkText.body(
                        size: 12.5,
                        weight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeetingAttendanceScreen extends StatefulWidget {
  const _MeetingAttendanceScreen({required this.meeting});
  final Meeting meeting;

  @override
  State<_MeetingAttendanceScreen> createState() =>
      _MeetingAttendanceScreenState();
}

class _MeetingAttendanceScreenState extends State<_MeetingAttendanceScreen> {
  bool _loading = true;
  String? _error;
  List<MeetingAttendanceRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await meetingService.attendance(widget.meeting.id);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChalkColors.paper,
      appBar: AppBar(title: Text('Attendance · ${widget.meeting.title}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load attendance\n$_error',
                        textAlign: TextAlign.center),
                  ),
                )
              : _rows.isEmpty
                  ? Center(
                      child: Text('No one has joined yet.',
                          style: ChalkText.body(
                              color: ChalkColors.ink.withOpacity(0.5))),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final r = _rows[i];
                        final present = r.finalStatus == 'present';
                        final statusColor = r.finalStatus == null
                            ? ChalkColors.chalkSky
                            : present
                                ? ChalkColors.chalkMint
                                : ChalkColors.chalkCoral;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: ChalkColors.ink.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: statusColor.withOpacity(0.15),
                                child: Text(
                                  r.studentEmail.isNotEmpty
                                      ? r.studentEmail[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(r.studentEmail.split('@').first,
                                        style: ChalkText.heading(size: 13.5)),
                                    Text(
                                      'Face detected in ${r.presenceChecksWithFace}/${r.presenceChecksTotal} checks',
                                      style: ChalkText.body(
                                          size: 11,
                                          color: ChalkColors.ink
                                              .withOpacity(0.55)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  (r.finalStatus ?? 'in call').toUpperCase(),
                                  style: ChalkText.body(
                                      size: 10.5,
                                      weight: FontWeight.w800,
                                      color: statusColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
