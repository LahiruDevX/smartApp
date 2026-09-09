import 'package:flutter/material.dart';
import '../../core/di/app_di.dart';
import 'app_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;

  // Live IoT metrics state
  double _temperature = 24.4;
  double _humidity = 47.8;
  double _airQuality = 392.2;
  double _light = 334.2;
  double _noise = 42.2;
  bool _lightsOn = true;
  int _studentsPresent = 156;
  int _totalStudents = 160;
  int _activeDevices = 24;
  int _systemHealth = 98;
  double _powerUsageKw = 2.4;
  String _lastUpdated = 'Just now';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await apiClient.getAuthed('/api/iot/dashboard');
      if (res is Map) {
        setState(() {
          _temperature = (res['temperature'] as num?)?.toDouble() ?? 24.4;
          _humidity = (res['humidity'] as num?)?.toDouble() ?? 47.8;
          _airQuality = (res['airQuality'] as num?)?.toDouble() ?? 392.2;
          _light = (res['light'] as num?)?.toDouble() ?? 334.2;
          _noise = (res['noise'] as num?)?.toDouble() ?? 42.2;
          _lightsOn = res['lightsOn'] == true;
          _studentsPresent = (res['studentsPresent'] as num?)?.toInt() ?? 156;
          _totalStudents = (res['totalStudents'] as num?)?.toInt() ?? 160;
          _activeDevices = (res['activeDevices'] as num?)?.toInt() ?? 24;
          _systemHealth = (res['systemHealth'] as num?)?.toInt() ?? 98;
          _powerUsageKw = (res['powerUsageKw'] as num?)?.toDouble() ?? 2.4;

          final timeStr = res['timestamp']?.toString();
          if (timeStr != null) {
            final parsed = DateTime.tryParse(timeStr)?.toLocal();
            if (parsed != null) {
              final hour = parsed.hour > 12 ? parsed.hour - 12 : (parsed.hour == 0 ? 12 : parsed.hour);
              final period = parsed.hour >= 12 ? 'PM' : 'AM';
              final min = parsed.minute.toString().padLeft(2, '0');
              final sec = parsed.second.toString().padLeft(2, '0');
              _lastUpdated = '$hour:$min:$sec $period';
            } else {
              _lastUpdated = 'Live';
            }
          } else {
            _lastUpdated = 'Live';
          }
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update IoT metrics: $e'),
            backgroundColor: const Color(0xFFDC2626),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchDashboardData,
            ),
          ),
        );
      }
    }
  }

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;
  bool _mid(BuildContext c) => MediaQuery.of(c).size.width >= 680;

  @override
  Widget build(BuildContext context) {
    final columns = _wide(context) ? 4 : (_mid(context) ? 2 : 1);
    final userRole = apiClient.currentRole?.toUpperCase() ?? 'ADMIN';

    return AppShell(
      title: 'Dashboard',
      subtitle: 'Real-time classroom monitoring and control',
      selectedRoute: '/dashboard',
      actions: [
        IconButton(
          onPressed: _fetchDashboardData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh IoT Data',
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications up to date')),
            );
          },
          icon: const Icon(Icons.notifications_none),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5C6ACB), Color(0xFF8D78F6)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                  color: Colors.black.withOpacity(0.12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userRole',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'All systems and IoT telemetry are synchronized.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const _HeaderPill(label: 'Live Classroom', accent: Color(0xFF7C78F9)),
                    const SizedBox(width: 10),
                    _HeaderPill(
                      label: _error == null ? 'Sensors Online' : 'Sensors Error',
                      accent: _error == null ? const Color(0xFF4AD7A6) : const Color(0xFFF87171),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Action Toolbar & Error Banner
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Connection issue: $_error',
                      style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _fetchDashboardData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              if (_loading)
                Row(
                  children: const [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Syncing telemetry...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                )
              else
                Text(
                  'Last synced: $_lastUpdated',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              const Spacer(),
              _SoftButton(
                icon: Icons.refresh,
                label: 'Refresh',
                onTap: _fetchDashboardData,
              ),
              const SizedBox(width: 10),
              _SoftButton(
                icon: Icons.description_outlined,
                label: 'View Analytics',
                onTap: () => Navigator.pushNamed(context, '/analytics'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary Stat Cards
          _Grid(
            columns: columns,
            children: [
              _StatCard(
                tint: const Color(0xFFEAF1FF),
                iconBg: const Color(0xFFDCEBFF),
                icon: Icons.flash_on_outlined,
                title: 'Active\nDevices',
                value: '$_activeCount',
                chipText: 'Online',
                chipColor: const Color(0xFF2D66F6),
              ),
              _StatCard(
                tint: const Color(0xFFE9FFF3),
                iconBg: const Color(0xFFD8FBE7),
                icon: Icons.groups_outlined,
                title: 'Students\nPresent',
                value: '$_studentsPresent/$_totalStudents',
                chipText: '${((_studentsPresent / _totalStudents) * 100).round()}%',
                chipColor: const Color(0xFF16A34A),
              ),
              _StatCard(
                tint: const Color(0xFFEAF7FF),
                iconBg: const Color(0xFFD9F0FF),
                icon: Icons.monitor_heart_outlined,
                title: 'System\nHealth',
                value: '$_systemHealth%',
                chipText: 'Optimal',
                chipColor: const Color(0xFF0EA5E9),
              ),
              _StatCard(
                tint: const Color(0xFFFFF7E6),
                iconBg: const Color(0xFFFFE9B8),
                icon: Icons.power_settings_new,
                title: 'Power\nUsage',
                value: '${_powerUsageKw.toStringAsFixed(1)} kW',
                chipText: 'Normal',
                chipColor: const Color(0xFFF59E0B),
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
                  'Environmental Sensors (Live IoT Telemetry)',
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
                    'Live Data ($_lastUpdated)',
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
                tint: const Color(0xFFE9FFF3),
                iconBg: const Color(0xFFD8FBE7),
                icon: Icons.thermostat_outlined,
                name: 'Temperature',
                value: _temperature.toStringAsFixed(1),
                unit: '°C',
                status: _temperature > 28 ? 'Warning' : 'Normal',
                updatedTime: _lastUpdated,
              ),
              _SensorCard(
                tint: const Color(0xFFEAF1FF),
                iconBg: const Color(0xFFDCEBFF),
                icon: Icons.water_drop_outlined,
                name: 'Humidity',
                value: _humidity.toStringAsFixed(1),
                unit: '%',
                status: 'Normal',
                updatedTime: _lastUpdated,
              ),
              _SensorCard(
                tint: _airQuality > 450 ? const Color(0xFFFFF7E6) : const Color(0xFFE9FFF3),
                iconBg: _airQuality > 450 ? const Color(0xFFFFE9B8) : const Color(0xFFD8FBE7),
                icon: Icons.air_outlined,
                name: 'Air Quality',
                value: _airQuality.toStringAsFixed(1),
                unit: 'PPM',
                status: _airQuality > 450 ? 'Warning' : 'Optimal',
                updatedTime: _lastUpdated,
              ),
              _SensorCard(
                tint: const Color(0xFFFFFBEB),
                iconBg: const Color(0xFFFEF3C7),
                icon: Icons.wb_sunny_outlined,
                name: 'Ambient Light',
                value: _light.toStringAsFixed(1),
                unit: 'Lux',
                status: _lightsOn ? 'Active' : 'Dim',
                updatedTime: _lastUpdated,
              ),
              _SensorCard(
                tint: _noise > 55 ? const Color(0xFFFFF7E6) : const Color(0xFFE9FFF3),
                iconBg: _noise > 55 ? const Color(0xFFFFE9B8) : const Color(0xFFD8FBE7),
                icon: Icons.volume_up_outlined,
                name: 'Acoustic Noise',
                value: _noise.toStringAsFixed(1),
                unit: 'dB',
                status: _noise > 55 ? 'Warning' : 'Quiet',
                updatedTime: _lastUpdated,
              ),
            ],
          ),

          const SizedBox(height: 18),
          const _SectionCard(
            title: 'Recent Classroom Alerts',
            icon: Icons.warning_amber_rounded,
            child: _AlertsList(),
          ),
        ],
      ),
    );
  }
}

/* ---------- Shared Widgets ---------- */

class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children});
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      const spacing = 14.0;
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF5C6ACB)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.tint,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.value,
    required this.chipText,
    required this.chipColor,
  });

  final Color tint;
  final Color iconBg;
  final IconData icon;
  final String title;
  final String value;
  final String chipText;
  final Color chipColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
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
                  color: Colors.white.withOpacity(0.8),
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
                        fontSize: 11.5,
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
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 700;
      final actions = [
        _QuickAction(
          icon: Icons.power_settings_new,
          title: 'Device Center',
          subtitle: 'Toggle & Dim Power',
          onTap: () => Navigator.pushNamed(context, '/device-control'),
        ),
        _QuickAction(
          icon: Icons.check_circle_outline,
          title: 'Attendance',
          subtitle: 'RFID & Camera Feed',
          onTap: () => Navigator.pushNamed(context, '/attendance'),
        ),
        _QuickAction(
          icon: Icons.query_stats,
          title: 'Analytics',
          subtitle: 'Reports & Energy Trends',
          onTap: () => Navigator.pushNamed(context, '/analytics'),
        ),
        _QuickAction(
          icon: Icons.thermostat_outlined,
          title: 'Environment',
          subtitle: 'Live Sensor Telemetry',
          onTap: () => Navigator.pushNamed(context, '/environmental'),
        ),
      ];

      if (isWide) {
        return Row(
          children: actions
              .map((e) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: e,
                    ),
                  ))
              .toList(),
        );
      }

      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: actions
            .map((e) => SizedBox(
                  width: (constraints.maxWidth - 10) / 2,
                  child: e,
                ))
            .toList(),
      );
    });
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F9FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF2D66F6), size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.55)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.tint,
    required this.iconBg,
    required this.icon,
    required this.name,
    required this.value,
    required this.unit,
    required this.status,
    required this.updatedTime,
  });

  final Color tint;
  final Color iconBg;
  final IconData icon;
  final String name;
  final String value;
  final String unit;
  final String status;
  final String updatedTime;

  @override
  Widget build(BuildContext context) {
    final warn = status.toLowerCase() == 'warning';
    final chipColor = warn ? const Color(0xFFF59E0B) : const Color(0xFF16A34A);

    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
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
                  color: Colors.white.withOpacity(0.8),
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
              Icon(Icons.access_time, size: 13, color: Colors.black.withOpacity(0.4)),
              const SizedBox(width: 5),
              Text(
                updatedTime,
                style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.55)),
              ),
            ],
          ),
        ],
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
          title: 'Air quality threshold check optimal in Room 301',
          time: 'Active Telemetry',
        ),
        SizedBox(height: 10),
        _AlertRow(
          accent: Color(0xFF2D66F6),
          title: 'HVAC system power efficiency at optimal baseline',
          time: 'Active Telemetry',
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
            height: 48,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Icon(Icons.info_outline, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.55)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
