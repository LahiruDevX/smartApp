/*import 'package:flutter/material.dart';
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
            onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        IconButton(
            onPressed: () {}, icon: const Icon(Icons.dark_mode_outlined)),
      ],
      body: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;
  bool _mid(BuildContext c) => MediaQuery.of(c).size.width >= 680;

  @override
  Widget build(BuildContext context) {
    final columns = _wide(context) ? 4 : (_mid(context) ? 2 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SizedBox()),
            _SoftButton(icon: Icons.refresh, label: 'Refresh', onTap: () {}),
            const SizedBox(width: 10),
            _SoftButton(
                icon: Icons.description_outlined,
                label: 'Generate Report',
                onTap: () {}),
          ],
        ),
        const SizedBox(height: 14),
        _Grid(
          columns: columns,
          children: const [
            _StatCard(
              tint: Color(0xFFEAF1FF),
              iconBg: Color(0xFFDCEBFF),
              icon: Icons.flash_on_outlined,
              title: 'Active\nDevices',
              value: '24',
              chipText: '+2',
              chipColor: Color(0xFF2D66F6),
            ),
            _StatCard(
              tint: Color(0xFFE9FFF3),
              iconBg: Color(0xFFD8FBE7),
              icon: Icons.groups_outlined,
              title: 'Students\nPresent',
              value: '156',
              chipText: '+12',
              chipColor: Color(0xFF16A34A),
            ),
            _StatCard(
              tint: Color(0xFFEAF7FF),
              iconBg: Color(0xFFD9F0FF),
              icon: Icons.monitor_heart_outlined,
              title: 'System\nHealth',
              value: '98%',
              chipText: 'Optimal',
              chipColor: Color(0xFF0EA5E9),
            ),
            _StatCard(
              tint: Color(0xFFFFF7E6),
              iconBg: Color(0xFFFFE9B8),
              icon: Icons.power_settings_new,
              title: 'Power\nUsage',
              value: '2.4kW',
              chipText: '-8%',
              chipColor: Color(0xFFF59E0B),
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
                    color: Color(0xFF0F172A)),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.circle, size: 10, color: Colors.green),
                const SizedBox(width: 6),
                Text('Live Data',
                    style: TextStyle(
                        fontSize: 12, color: Colors.black.withOpacity(0.55))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Grid(
          columns: _wide(context) ? 3 : 2,
          children: const [
            _SensorCard(
              tint: Color(0xFFE9FFF3),
              iconBg: Color(0xFFD8FBE7),
              icon: Icons.thermostat_outlined,
              name: 'temperature',
              value: '24.4',
              unit: '°C',
              status: 'normal',
            ),
            _SensorCard(
              tint: Color(0xFFE9FFF3),
              iconBg: Color(0xFFD8FBE7),
              icon: Icons.water_drop_outlined,
              name: 'humidity',
              value: '47.8',
              unit: '%',
              status: 'normal',
            ),
            _SensorCard(
              tint: Color(0xFFE9FFF3),
              iconBg: Color(0xFFD8FBE7),
              icon: Icons.air_outlined,
              name: 'air Quality',
              value: '392.2',
              unit: 'PPM',
              status: 'normal',
            ),
            _SensorCard(
              tint: Color(0xFFE9FFF3),
              iconBg: Color(0xFFD8FBE7),
              icon: Icons.wb_sunny_outlined,
              name: 'light',
              value: '334.2',
              unit: 'Lux',
              status: 'normal',
            ),
            _SensorCard(
              tint: Color(0xFFFFF7E6),
              iconBg: Color(0xFFFFE9B8),
              icon: Icons.volume_up_outlined,
              name: 'noise',
              value: '42.2',
              unit: 'dB',
              status: 'warning',
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
        children:
            children.map((e) => SizedBox(width: itemW, child: e)).toList(),
      );
    });
  }
}

class _SoftButton extends StatelessWidget {
  const _SoftButton(
      {required this.icon, required this.label, required this.onTap});
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
                color: Colors.black.withOpacity(0.08)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF2D66F6)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.icon, required this.child});
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
              color: Colors.black.withOpacity(0.08)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2D66F6)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w900)),
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
      height: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              blurRadius: 24,
              offset: const Offset(0, 14),
              color: Colors.black.withOpacity(0.08)),
        ],
      ),
      child: Column(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, size: 14, color: chipColor),
                    const SizedBox(width: 6),
                    Text(chipText,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: chipColor)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.6),
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;

  @override
  Widget build(BuildContext context) {
    final actions = const [
      _QuickAction(
          icon: Icons.power_settings_new,
          title: 'All Devices',
          subtitle: 'Toggle Power'),
      _QuickAction(
          icon: Icons.check_circle_outline,
          title: 'Mark Present',
          subtitle: 'Attendance'),
      _QuickAction(
          icon: Icons.query_stats,
          title: 'View Analytics',
          subtitle: 'Reports'),
      _QuickAction(
          icon: Icons.notifications_active_outlined,
          title: 'View Alerts',
          subtitle: 'Notifications'),
    ];

    if (_wide(context)) {
      return Row(
        children: actions
            .map((e) => Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: e)))
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
  const _QuickAction(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF2D66F6)),
          const SizedBox(height: 10),
          Text(title,
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 11, color: Colors.black.withOpacity(0.55))),
        ],
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
  });

  final Color tint;
  final Color iconBg;
  final IconData icon;
  final String name;
  final String value;
  final String unit;
  final String status;

  @override
  Widget build(BuildContext context) {
    final warn = status.toLowerCase() == 'warning';
    final chipColor = warn ? const Color(0xFFF59E0B) : const Color(0xFF16A34A);

    return Container(
      height: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              blurRadius: 24,
              offset: const Offset(0, 14),
              color: Colors.black.withOpacity(0.08)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: chipColor),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: chipColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(name,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.65))),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A))),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.55),
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.trending_up, size: 14, color: chipColor),
              const SizedBox(width: 6),
              Text('Updated',
                  style: TextStyle(
                      fontSize: 11, color: Colors.black.withOpacity(0.55))),
              const SizedBox(width: 8),
              Text('3:43:43 PM',
                  style: TextStyle(
                      fontSize: 11, color: Colors.black.withOpacity(0.55))),
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
  const _AlertRow(
      {required this.accent, required this.title, required this.time});
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(time,
                    style: TextStyle(
                        fontSize: 11, color: Colors.black.withOpacity(0.55))),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Dismiss')),
        ],
      ),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _darkMode = false;
  int _refreshIndex = 0;
  DateTime _updatedAt = DateTime.now();
  final List<_DashboardAlert> _alerts = [
    const _DashboardAlert(
      title: 'Humidity above threshold in Classroom A-01',
      time: 'Just now',
      color: Color(0xFFF59E0B),
    ),
    const _DashboardAlert(
      title: 'Automatic lights activated due to low light',
      time: '12 minutes ago',
      color: Color(0xFF2D66F6),
    ),
  ];

  static const _sensorSets = [
    [24.4, 68.0, 392.0, 284.0, 42.0],
    [24.7, 64.0, 380.0, 410.0, 39.0],
    [25.1, 71.0, 405.0, 235.0, 46.0],
  ];

  List<double> get _sensors => _sensorSets[_refreshIndex];

  void _refresh() {
    setState(() {
      _refreshIndex = (_refreshIndex + 1) % _sensorSets.length;
      _updatedAt = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dashboard data refreshed')),
    );
  }

  Future<void> _generateReport() async {
    final report = <String>[
      'Smart Classroom Dashboard Report',
      'Generated,${_updatedAt.toIso8601String()}',
      'Active devices,3/4',
      'Students present,28',
      'Temperature,${_sensors[0]} C',
      'Humidity,${_sensors[1]}%',
      'Light level,${_sensors[3]} lux',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: report));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dashboard report copied to clipboard')),
    );
  }

  void _showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              if (_alerts.isEmpty)
                const ListTile(
                  leading: Icon(Icons.notifications_off_outlined),
                  title: Text('No new notifications'),
                )
              else
                for (final alert in _alerts)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        Icon(Icons.warning_amber_rounded, color: alert.color),
                    title: Text(alert.title),
                    subtitle: Text(alert.time),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _dismissAlert(int index) {
    final removed = _alerts[index];
    setState(() => _alerts.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Alert dismissed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => setState(() => _alerts.insert(index, removed)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    return Theme(
      data: _darkMode
          ? ThemeData.dark(useMaterial3: true).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF60A5FA),
                brightness: Brightness.dark,
              ),
            )
          : baseTheme,
      child: AppShell(
        title: 'Dashboard',
        subtitle: 'Real-time classroom monitoring and control',
        selectedRoute: '/dashboard',
        actions: [
          Badge(
            isLabelVisible: _alerts.isNotEmpty,
            label: Text('${_alerts.length}'),
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: _showNotifications,
              icon: const Icon(Icons.notifications_none),
            ),
          ),
          IconButton(
            tooltip: _darkMode ? 'Use light mode' : 'Use dark mode',
            onPressed: () => setState(() => _darkMode = !_darkMode),
            icon: Icon(
              _darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
        ],
        body: _DashboardBody(
          sensors: _sensors,
          updatedAt: _updatedAt,
          alerts: _alerts,
          onRefresh: _refresh,
          onGenerateReport: _generateReport,
          onShowAlerts: _showNotifications,
          onDismissAlert: _dismissAlert,
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.sensors,
    required this.updatedAt,
    required this.alerts,
    required this.onRefresh,
    required this.onGenerateReport,
    required this.onShowAlerts,
    required this.onDismissAlert,
  });

  final List<double> sensors;
  final DateTime updatedAt;
  final List<_DashboardAlert> alerts;
  final VoidCallback onRefresh;
  final VoidCallback onGenerateReport;
  final VoidCallback onShowAlerts;
  final ValueChanged<int> onDismissAlert;

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;
  bool _mid(BuildContext c) => MediaQuery.of(c).size.width >= 680;

  @override
  Widget build(BuildContext context) {
    final columns = _wide(context) ? 4 : (_mid(context) ? 2 : 1);
    final updatedLabel =
        '${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SizedBox()),
            _SoftButton(
              icon: Icons.refresh,
              label: 'Refresh',
              onTap: onRefresh,
            ),
            const SizedBox(width: 10),
            _SoftButton(
              icon: Icons.description_outlined,
              label: 'Generate Report',
              onTap: onGenerateReport,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Grid(
          columns: columns,
          children: const [
            _StatCard(
              tint: Color(0xFFEAF1FF),
              iconBg: Color(0xFFDCEBFF),
              icon: Icons.flash_on_outlined,
              title: 'Active\nDevices',
              value: '24',
              chipText: '+2',
              chipColor: Color(0xFF2D66F6),
            ),
            _StatCard(
              tint: Color(0xFFE9FFF3),
              iconBg: Color(0xFFD8FBE7),
              icon: Icons.groups_outlined,
              title: 'Students\nPresent',
              value: '156',
              chipText: '+12',
              chipColor: Color(0xFF16A34A),
            ),
            _StatCard(
              tint: Color(0xFFEAF7FF),
              iconBg: Color(0xFFD9F0FF),
              icon: Icons.monitor_heart_outlined,
              title: 'System\nHealth',
              value: '98%',
              chipText: 'Optimal',
              chipColor: Color(0xFF0EA5E9),
            ),
            _StatCard(
              tint: Color(0xFFFFF7E6),
              iconBg: Color(0xFFFFE9B8),
              icon: Icons.power_settings_new,
              title: 'Power\nUsage',
              value: '2.4kW',
              chipText: '-8%',
              chipColor: Color(0xFFF59E0B),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Quick Actions',
          icon: Icons.bolt,
          child: _QuickActionsRow(onShowAlerts: onShowAlerts),
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
              tint: Color(0xFFE9FFF3),
              iconBg: Color(0xFFD8FBE7),
              icon: Icons.thermostat_outlined,
              name: 'temperature',
              value: sensors[0].toStringAsFixed(1),
              unit: '°C',
              status: 'normal',
              updatedLabel: updatedLabel,
            ),
            _SensorCard(
              tint: Color(0xFFE9FFF3),
              iconBg: Color(0xFFD8FBE7),
              icon: Icons.water_drop_outlined,
              name: 'humidity',
              value: sensors[1].toStringAsFixed(0),
              unit: '%',
              status: sensors[1] > 65 ? 'warning' : 'normal',
              updatedLabel: updatedLabel,
            ),
            _SensorCard(
              tint: Color(0xFFE9FFF3),
              iconBg: Color(0xFFD8FBE7),
              icon: Icons.air_outlined,
              name: 'air Quality',
              value: sensors[2].toStringAsFixed(0),
              unit: 'PPM',
              status: 'normal',
              updatedLabel: updatedLabel,
            ),
            _SensorCard(
              tint: Color(0xFFE9FFF3),
              iconBg: Color(0xFFD8FBE7),
              icon: Icons.wb_sunny_outlined,
              name: 'light',
              value: sensors[3].toStringAsFixed(0),
              unit: 'Lux',
              status: 'normal',
              updatedLabel: updatedLabel,
            ),
            _SensorCard(
              tint: Color(0xFFFFF7E6),
              iconBg: Color(0xFFFFE9B8),
              icon: Icons.volume_up_outlined,
              name: 'noise',
              value: sensors[4].toStringAsFixed(0),
              unit: 'dB',
              status: 'warning',
              updatedLabel: updatedLabel,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Recent Alerts',
          icon: Icons.warning_amber_rounded,
          child: _AlertsList(alerts: alerts, onDismiss: onDismissAlert),
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
        children:
            children.map((e) => SizedBox(width: itemW, child: e)).toList(),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.onShowAlerts});

  final VoidCallback onShowAlerts;

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
        onTap: onShowAlerts,
      ),
    ];

    if (_wide(context)) {
      return Row(
        children: actions
            .map((e) => Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: e)))
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
              Icon(icon, color: const Color(0xFF2D66F6)),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
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
    required this.updatedLabel,
  });

  final Color tint;
  final Color iconBg;
  final IconData icon;
  final String name;
  final String value;
  final String unit;
  final String status;
  final String updatedLabel;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              Text('Updated',
                  style: TextStyle(
                      fontSize: 11, color: Colors.black.withOpacity(0.55))),
              const SizedBox(width: 8),
              Text(
                updatedLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertsList extends StatelessWidget {
  const _AlertsList({required this.alerts, required this.onDismiss});

  final List<_DashboardAlert> alerts;
  final ValueChanged<int> onDismiss;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text('No active alerts')),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < alerts.length; index++) ...[
          _AlertRow(
            accent: alerts[index].color,
            title: alerts[index].title,
            time: alerts[index].time,
            onDismiss: () => onDismiss(index),
          ),
          if (index < alerts.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.accent,
    required this.title,
    required this.time,
    required this.onDismiss,
  });

  final Color accent;
  final String title;
  final String time;
  final VoidCallback onDismiss;

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
                Text(title,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(time,
                    style: TextStyle(
                        fontSize: 11, color: Colors.black.withOpacity(0.55))),
              ],
            ),
          ),
          TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
        ],
      ),
    );
  }
}

class _DashboardAlert {
  const _DashboardAlert({
    required this.title,
    required this.time,
    required this.color,
  });

  final String title;
  final String time;
  final Color color;
}
