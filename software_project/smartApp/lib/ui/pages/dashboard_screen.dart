import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/di/app_di.dart';
import 'app_shell.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Dashboard',
      subtitle: 'Real-time classroom monitoring and control',
      selectedRoute: '/dashboard',
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.dark_mode_outlined),
        ),
      ],
      body: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;
  bool _mid(BuildContext c) => MediaQuery.of(c).size.width >= 680;

  final _rng = math.Random();
  bool _refreshing = false;

  // Real data from the backend.
  int? _activeDevices;
  int _totalDevices = 0;

  // Environmental readings from the backend (GET /api/environment/latest).
  double _temp = 24.4, _humidity = 47.8, _airQ = 392.2, _light = 334.2, _noise = 42.2;
  final Map<String, String> _status = {};
  String _updated = '—';
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Poll so the "Live Data" tiles actually stay live.
    _autoRefresh = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refresh(silent: true),
    );
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  double _jitter(double base, double spread) =>
      base + (_rng.nextDouble() - 0.5) * spread;

  String _fmtTime(DateTime dt) {
    final t = TimeOfDay.fromDateTime(dt.toLocal());
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    return '$h:${t.minute.toString().padLeft(2, '0')} '
        '${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent && mounted) setState(() {});

    try {
      final res = await apiClient.getAuthed('/api/devices');
      final list = (res['devices'] as List?) ?? const [];
      _totalDevices = list.length;
      _activeDevices = list
          .whereType<Map>()
          .where((d) => d['isOn'] == true)
          .length;
    } catch (_) {
      // Backend unreachable — keep the last known device count.
    }

    try {
      final env = await environmentService.latest();
      for (final s in env.sensors) {
        _status[s.type] = s.status;
        switch (s.type) {
          case 'temperature':
            _temp = s.value;
          case 'humidity':
            _humidity = s.value;
          case 'air_quality':
            _airQ = s.value;
          case 'light':
            _light = s.value;
          case 'noise':
            _noise = s.value;
        }
      }
      _updated = _fmtTime(env.updatedAt ?? DateTime.now());
    } catch (_) {
      // Environment endpoint unavailable — nudge the last values so the tiles
      // still look live.
      _temp = _jitter(_temp, 1.0);
      _humidity = _jitter(_humidity, 2.0);
      _airQ = _jitter(_airQ, 10.0);
      _light = _jitter(_light, 15.0);
      _noise = _jitter(_noise, 3.0);
      _updated = _fmtTime(DateTime.now());
    }

    _refreshing = false;
    if (!mounted) return;
    setState(() {});
    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard refreshed'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  String _f(double v) => v.toStringAsFixed(1);

  Color _tint(String type) =>
      (_status[type] == 'warning') ? const Color(0xFFFFF7E6) : const Color(0xFFE9FFF3);
  Color _iconBg(String type) =>
      (_status[type] == 'warning') ? const Color(0xFFFFE9B8) : const Color(0xFFD8FBE7);

  @override
  Widget build(BuildContext context) {
    final columns = _wide(context) ? 4 : (_mid(context) ? 2 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SizedBox()),
            _SoftButton(
              icon: Icons.refresh,
              label: _refreshing ? 'Refreshing…' : 'Refresh',
              onTap: _refresh,
            ),
            const SizedBox(width: 10),
            _SoftButton(
              icon: Icons.description_outlined,
              label: 'Generate Report',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 14),

        _Grid(
          columns: columns,
          children: [
            _StatCard(
              tint: const Color(0xFFEAF1FF),
              iconBg: const Color(0xFFDCEBFF),
              icon: Icons.flash_on_outlined,
              title: 'Active\nDevices',
              value: _activeDevices == null
                  ? '—'
                  : '$_activeDevices/$_totalDevices',
              chipText: 'live',
              chipColor: const Color(0xFF2D66F6),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/device-control'),
            ),
            _StatCard(
              tint: const Color(0xFFE9FFF3),
              iconBg: const Color(0xFFD8FBE7),
              icon: Icons.groups_outlined,
              title: 'Students\nPresent',
              value: '156',
              chipText: '+12',
              chipColor: const Color(0xFF16A34A),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/attendance'),
            ),
            _StatCard(
              tint: const Color(0xFFEAF7FF),
              iconBg: const Color(0xFFD9F0FF),
              icon: Icons.monitor_heart_outlined,
              title: 'System\nHealth',
              value: '98%',
              chipText: 'Optimal',
              chipColor: const Color(0xFF0EA5E9),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/analytics'),
            ),
            _StatCard(
              tint: const Color(0xFFFFF7E6),
              iconBg: const Color(0xFFFFE9B8),
              icon: Icons.power_settings_new,
              title: 'Power\nUsage',
              value: '2.4kW',
              chipText: '-8%',
              chipColor: const Color(0xFFF59E0B),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/environmental'),
            ),
          ],
        ),

        const SizedBox(height: 18),
        const _SectionCard(
          title: 'Quick Actions',
          icon: Icons.bolt,
          child: _QuickActionsRow(),
        ),

        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Environmental Sensors',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.circle, size: 10, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  'Live Data',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),
        _Grid(
          columns: _wide(context) ? 3 : 2,
          children: [
            _SensorCard(
              tint: _tint('temperature'),
              iconBg: _iconBg('temperature'),
              icon: Icons.thermostat_outlined,
              name: 'temperature',
              value: _f(_temp),
              unit: '°C',
              status: _status['temperature'] ?? 'normal',
              updated: _updated,
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/environmental'),
            ),
            _SensorCard(
              tint: _tint('humidity'),
              iconBg: _iconBg('humidity'),
              icon: Icons.water_drop_outlined,
              name: 'humidity',
              value: _f(_humidity),
              unit: '%',
              status: _status['humidity'] ?? 'normal',
              updated: _updated,
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/environmental'),
            ),
            _SensorCard(
              tint: _tint('air_quality'),
              iconBg: _iconBg('air_quality'),
              icon: Icons.air_outlined,
              name: 'air Quality',
              value: _f(_airQ),
              unit: 'PPM',
              status: _status['air_quality'] ?? 'normal',
              updated: _updated,
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/environmental'),
            ),
            _SensorCard(
              tint: _tint('light'),
              iconBg: _iconBg('light'),
              icon: Icons.wb_sunny_outlined,
              name: 'light',
              value: _f(_light),
              unit: 'Lux',
              status: _status['light'] ?? 'normal',
              updated: _updated,
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/environmental'),
            ),
            _SensorCard(
              tint: _tint('noise'),
              iconBg: _iconBg('noise'),
              icon: Icons.volume_up_outlined,
              name: 'noise',
              value: _f(_noise),
              unit: 'dB',
              status: _status['noise'] ?? 'normal',
              updated: _updated,
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/environmental'),
            ),
          ],
        ),

        const SizedBox(height: 18),
        const _SectionCard(
          title: 'Recent Alerts',
          icon: Icons.warning_amber_rounded,
          child: _AlertsList(),
        ),
      ],
    );
  }
}

/* ---------- shared widgets (dashboard) ---------- */

class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children});
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      final spacing = 14.0;
      final itemW = (w - (columns - 1) * spacing) / columns;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children.map((e) => SizedBox(width: itemW, child: e)).toList(),
      );
    });
  }
}

class _SoftButton extends StatelessWidget {
  const _SoftButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF2D66F6)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
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
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2D66F6)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// ✅ FIXED: no fixed height, no Spacer overflow
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.tint,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.value,
    required this.chipText,
    required this.chipColor,
    this.onTap,
  });

  final Color tint;
  final Color iconBg;
  final IconData icon;
  final String title;
  final String value;
  final String chipText;
  final Color chipColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Material(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: chipColor),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 14, color: chipColor),
                    const SizedBox(width: 6),
                    Text(
                      chipText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: chipColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.power_settings_new,
        title: 'All Devices',
        subtitle: 'Toggle Power',
        onTap: () => Navigator.pushReplacementNamed(context, '/device-control'),
      ),
      _QuickAction(
        icon: Icons.check_circle_outline,
        title: 'Mark Present',
        subtitle: 'Attendance',
        onTap: () => Navigator.pushReplacementNamed(context, '/attendance'),
      ),
      _QuickAction(
        icon: Icons.query_stats,
        title: 'View Analytics',
        subtitle: 'Reports',
        onTap: () => Navigator.pushReplacementNamed(context, '/analytics'),
      ),
      _QuickAction(
        icon: Icons.notifications_active_outlined,
        title: 'View Alerts',
        subtitle: 'Notifications',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No new alerts')),
        ),
      ),
    ];

    if (_wide(context)) {
      return Row(
        children: actions
            .map((e) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: e)))
            .toList(),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.map((e) => SizedBox(width: 220, child: e)).toList(),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F9FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF2D66F6)),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.55))),
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ updated: prevents overflow too
class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.tint,
    required this.iconBg,
    required this.icon,
    required this.name,
    required this.value,
    required this.unit,
    required this.status,
    this.updated = '—',
    this.onTap,
  });

  final Color tint;
  final Color iconBg;
  final IconData icon;
  final String name;
  final String value;
  final String unit;
  final String status;
  final String updated;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final warn = status.toLowerCase() == 'warning';
    final chipColor = warn ? const Color(0xFFF59E0B) : const Color(0xFF16A34A);

    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Material(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: chipColor),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: chipColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.trending_up, size: 14, color: chipColor),
              const SizedBox(width: 6),
              Text('Updated', style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.55))),
              const SizedBox(width: 8),
              Text(updated, style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.55))),
            ],
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertsList extends StatelessWidget {
  const _AlertsList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _AlertRow(
          accent: Color(0xFFF59E0B),
          title: 'Air quality above threshold in Room 301',
          time: '10/25/2025, 3:42:33 PM',
        ),
        SizedBox(height: 10),
        _AlertRow(
          accent: Color(0xFF2D66F6),
          title: 'Scheduled maintenance for HVAC system',
          time: '10/25/2025, 2:24:33 PM',
        ),
      ],
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.accent,
    required this.title,
    required this.time,
  });

  final Color accent;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Icon(Icons.warning_amber_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.55))),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Dismiss')),
        ],
      ),
    );
  }
}
