import 'package:flutter/material.dart';

import '../../core/di/app_di.dart';
import '../../features/learning/learning_service.dart';
import '../theme/chalk_theme.dart';

/// Teacher form to create a meeting. Pushed (not a named route) from
/// meetings_screen.dart's "Schedule Meeting" button.
class ScheduleMeetingScreen extends StatefulWidget {
  const ScheduleMeetingScreen({super.key});

  @override
  State<ScheduleMeetingScreen> createState() => _ScheduleMeetingScreenState();
}

class _ScheduleMeetingScreenState extends State<ScheduleMeetingScreen> {
  final _title = TextEditingController();
  List<Subject> _subjects = const [];
  Subject? _selectedSubject;
  DateTime? _date;
  TimeOfDay? _time;
  int _duration = 45;
  bool _loadingSubjects = true;
  bool _saving = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      final overview = await learningService.overview();
      if (!mounted) return;
      setState(() {
        _subjects = overview.subjects;
        _selectedSubject = _subjects.isNotEmpty ? _subjects.first : null;
        _loadingSubjects = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.toString().replaceFirst('Exception: ', '');
        _loadingSubjects = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final subject = _selectedSubject;
    if (subject == null) {
      setState(() => _err = 'Choose a subject');
      return;
    }
    if (_title.text.trim().isEmpty) {
      setState(() => _err = 'Title is required');
      return;
    }
    if (_date == null || _time == null) {
      setState(() => _err = 'Pick a date and time');
      return;
    }
    final scheduledAt = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    if (scheduledAt.isBefore(DateTime.now())) {
      setState(() => _err = 'Pick a time in the future');
      return;
    }

    setState(() {
      _saving = true;
      _err = null;
    });
    try {
      await meetingService.create(
        subjectId: subject.id,
        title: _title.text.trim(),
        scheduledAt: scheduledAt,
        durationMinutes: _duration,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _err = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChalkColors.paper,
      appBar: AppBar(title: const Text('Schedule Meeting')),
      body: _loadingSubjects
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Subject', style: ChalkText.heading(size: 13)),
                const SizedBox(height: 8),
                if (_subjects.isEmpty)
                  Text('No subjects available.', style: ChalkText.body())
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in _subjects)
                        ChoiceChip(
                          label: Text(s.name),
                          selected: _selectedSubject?.id == s.id,
                          onSelected: (_) =>
                              setState(() => _selectedSubject = s),
                        ),
                    ],
                  ),
                const SizedBox(height: 18),
                TextField(
                  controller: _title,
                  decoration:
                      const InputDecoration(labelText: 'Meeting title'),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined,
                            size: 16),
                        label: Text(
                            _date == null ? 'Pick date' : _formatDate(_date!)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(_time == null
                            ? 'Pick time'
                            : _time!.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Duration: $_duration minutes',
                    style: ChalkText.body(weight: FontWeight.w700)),
                Slider(
                  value: _duration.toDouble(),
                  min: 15,
                  max: 120,
                  divisions: 7,
                  label: '$_duration min',
                  onChanged: (v) => setState(() => _duration = v.round()),
                ),
                if (_err != null) ...[
                  const SizedBox(height: 10),
                  Text(_err!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                        backgroundColor: ChalkColors.chalkboard),
                    child: Text(_saving ? 'Scheduling…' : 'Schedule Meeting'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}
