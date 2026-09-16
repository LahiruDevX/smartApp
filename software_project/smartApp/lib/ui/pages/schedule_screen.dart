import 'package:flutter/material.dart';

import '../../core/di/app_di.dart';
import '../../features/schedule/schedule_service.dart';
import 'app_shell.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  static const _startHour = 8;
  static const _endHour = 19;
  static const _slotHeight = 56.0;

  late DateTime _weekStart; // Monday of the displayed week
  List<Booking> _bookings = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final b = await scheduleService.bookings();
      if (!mounted) return;
      setState(() {
        _bookings = b;
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

  void _shiftWeek(int weeks) =>
      setState(() => _weekStart = _weekStart.add(Duration(days: 7 * weeks)));

  void _thisWeek() {
    final now = DateTime.now();
    setState(() => _weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1)));
  }

  int? get _todayColumn {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(_weekStart).inDays;
    return (diff >= 0 && diff < _days.length) ? diff : null;
  }

  String get _weekLabel {
    final end = _weekStart.add(const Duration(days: 4));
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[_weekStart.month - 1]} ${_weekStart.day} – '
        '${m[end.month - 1]} ${end.day}, ${end.year}';
  }

  Future<void> _newBooking() async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _NewBookingDialog(),
    );
    if (data == null) return;
    try {
      final created = await scheduleService.create(
        title: data['title'] as String,
        teacher: data['teacher'] as String,
        room: data['room'] as String,
        weekday: data['weekday'] as int,
        startHour: data['startHour'] as int,
        endHour: data['endHour'] as int,
      );
      setState(() => _bookings = [..._bookings, created]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _delete(Booking b) async {
    final prev = _bookings;
    setState(() => _bookings = _bookings.where((x) => x.id != b.id).toList());
    try {
      await scheduleService.delete(b.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _bookings = prev);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Class Schedule',
      subtitle: 'Manage classroom bookings and timetables',
      selectedRoute: '/schedule',
      actions: [
        SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: _newBooking,
            icon: const Icon(Icons.add),
            label: const Text('New Booking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D66F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
          ),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              _CardSection(
                title: 'Weekly Schedule',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text('Could not load schedule\n$_error',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else ...[
              _weeklyCard(),
              const SizedBox(height: 16),
              _upcomingCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _weeklyCard() {
    return _CardSection(
      title: 'Weekly Schedule  ·  $_weekLabel',
      trailing: Row(
        children: [
          _SmallBtn(label: 'Previous Week', onTap: () => _shiftWeek(-1)),
          const SizedBox(width: 10),
          _SmallBtn(label: 'This Week', onTap: _thisWeek),
          const SizedBox(width: 10),
          _SmallBtn(label: 'Next Week', onTap: () => _shiftWeek(1)),
        ],
      ),
      child: _loading
          ? const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator()))
          : Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 64,
                        child: Text('Time',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                      for (int d = 0; d < _days.length; d++)
                        Expanded(
                          child: Text(
                            _days[d],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: d == _todayColumn
                                  ? const Color(0xFF2D66F6)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (int h = _startHour; h < _endHour; h++)
                  SizedBox(
                    height: _slotHeight,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: Text(
                            _fmt24(h),
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.65),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        for (int d = 0; d < _days.length; d++)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 3),
                              decoration: d == _todayColumn
                                  ? BoxDecoration(
                                      color: const Color(0xFF2D66F6)
                                          .withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(8),
                                    )
                                  : null,
                              child: _slotFor(weekday: d + 1, hour: h),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _slotFor({required int weekday, required int hour}) {
    for (final b in _bookings) {
      if (b.weekday != weekday) continue;
      if (hour < b.startHour || hour >= b.endHour) continue;
      if (hour != b.startHour) {
        return Container(
          decoration: const BoxDecoration(color: Color(0xFFDCEBFF)),
        );
      }
      return _BookingChip(booking: b, onDelete: () => _delete(b));
    }
    return const SizedBox.shrink();
  }

  Widget _upcomingCard() {
    final upcoming = [..._bookings]..sort((a, b) {
        final byDay = a.weekday.compareTo(b.weekday);
        return byDay != 0 ? byDay : a.startHour.compareTo(b.startHour);
      });

    return _CardSection(
      title: 'Upcoming Classes',
      child: _loading
          ? const SizedBox(height: 80)
          : upcoming.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text('No classes booked.',
                      style: TextStyle(color: Colors.black.withOpacity(0.5))),
                )
              : Column(
                  children: [
                    for (int i = 0; i < upcoming.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _UpcomingTile(
                        title: upcoming[i].title,
                        teacher: upcoming[i].teacher,
                        room: upcoming[i].room,
                        day: _days[upcoming[i].weekday - 1],
                        time:
                            '${_fmt12(upcoming[i].startHour)} – ${_fmt12(upcoming[i].endHour)}',
                      ),
                    ],
                  ],
                ),
    );
  }

  static String _fmt24(int h) => '${h.toString().padLeft(2, '0')}:00';

  static String _fmt12(int h) {
    final period = h < 12 ? 'AM' : 'PM';
    final hr = h % 12 == 0 ? 12 : h % 12;
    return '$hr:00 $period';
  }
}

/* ------- New booking dialog ------- */

class _NewBookingDialog extends StatefulWidget {
  const _NewBookingDialog();

  @override
  State<_NewBookingDialog> createState() => _NewBookingDialogState();
}

class _NewBookingDialogState extends State<_NewBookingDialog> {
  final _title = TextEditingController();
  final _teacher = TextEditingController();
  final _room = TextEditingController(text: 'Room 301');
  int _weekday = 1;
  int _start = 9;
  int _end = 10;
  String? _err;

  @override
  void dispose() {
    _title.dispose();
    _teacher.dispose();
    _room.dispose();
    super.dispose();
  }

  void _save() {
    if (_title.text.trim().isEmpty || _teacher.text.trim().isEmpty) {
      setState(() => _err = 'Class name and teacher are required');
      return;
    }
    if (_end <= _start) {
      setState(() => _err = 'End time must be after start time');
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'title': _title.text.trim(),
      'teacher': _teacher.text.trim(),
      'room': _room.text.trim().isEmpty ? 'Room 301' : _room.text.trim(),
      'weekday': _weekday,
      'startHour': _start,
      'endHour': _end,
    });
  }

  @override
  Widget build(BuildContext context) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    final hours = [for (int h = 8; h <= 19; h++) h];

    return AlertDialog(
      title: const Text('New Booking'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Class name')),
            const SizedBox(height: 10),
            TextField(
                controller: _teacher,
                decoration: const InputDecoration(labelText: 'Teacher')),
            const SizedBox(height: 10),
            TextField(
                controller: _room,
                decoration: const InputDecoration(labelText: 'Room')),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _weekday,
              decoration: const InputDecoration(labelText: 'Day'),
              items: [
                for (int i = 0; i < days.length; i++)
                  DropdownMenuItem(value: i + 1, child: Text(days[i])),
              ],
              onChanged: (v) => setState(() => _weekday = v ?? 1),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _start,
                    decoration: const InputDecoration(labelText: 'Start'),
                    items: [
                      for (final h in hours)
                        DropdownMenuItem(
                            value: h,
                            child: Text(_ScheduleScreenState._fmt24(h))),
                    ],
                    onChanged: (v) => setState(() => _start = v ?? 9),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _end,
                    decoration: const InputDecoration(labelText: 'End'),
                    items: [
                      for (final h in hours)
                        DropdownMenuItem(
                            value: h,
                            child: Text(_ScheduleScreenState._fmt24(h))),
                    ],
                    onChanged: (v) => setState(() => _end = v ?? 10),
                  ),
                ),
              ],
            ),
            if (_err != null) ...[
              const SizedBox(height: 10),
              Text(_err!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }
}

/* ------- shared ui ------- */

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
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w900),
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

class _BookingChip extends StatelessWidget {
  const _BookingChip({required this.booking, required this.onDelete});
  final Booking booking;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${booking.title} · ${booking.teacher} · ${booking.room}\nTap to remove',
      child: InkWell(
        onTap: onDelete,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFDCEBFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
              ),
              Text(
                booking.teacher,
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
        ),
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({
    required this.title,
    required this.teacher,
    required this.room,
    required this.day,
    required this.time,
  });

  final String title;
  final String teacher;
  final String room;
  final String day;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: const Color(0xFFDCEBFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month, color: Color(0xFF2D66F6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '$teacher  •  $room',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$day  •  $time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDDFBE7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'scheduled',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
