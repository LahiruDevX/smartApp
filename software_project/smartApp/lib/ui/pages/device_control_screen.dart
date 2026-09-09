import 'package:flutter/material.dart';

import 'app_shell.dart';

class DeviceControlScreen extends StatefulWidget {
  const DeviceControlScreen({super.key});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  bool _mainLightsOn = true;
  bool _boardLightsOn = true;
  bool _ceilingFanOn = true;
  bool _ventilationFanOn = false;
  bool _autoLighting = true;
  bool _autoClimate = true;

  double _mainBrightness = 72;
  double _boardBrightness = 88;
  double _ceilingFanSpeed = 55;
  double _ventilationFanSpeed = 40;
  double _humidityThreshold = 65;
  double _lightThreshold = 300;

  double _temperature = 24.2;
  double _humidity = 68;
  double _lightLevel = 284;
  int _refreshCount = 0;
  DateTime _lastUpdated = DateTime.now();

  bool _wide(BuildContext context) => MediaQuery.sizeOf(context).width >= 1050;
  bool _mid(BuildContext context) => MediaQuery.sizeOf(context).width >= 700;

  int get _activeDevices => [
        _mainLightsOn,
        _boardLightsOn,
        _ceilingFanOn,
        _ventilationFanOn,
      ].where((value) => value).length;

  int get _powerUsage {
    final lights = (_mainLightsOn ? 96 * _mainBrightness / 100 : 0) +
        (_boardLightsOn ? 42 * _boardBrightness / 100 : 0);
    final fans = (_ceilingFanOn ? 75 * _ceilingFanSpeed / 100 : 0) +
        (_ventilationFanOn ? 55 * _ventilationFanSpeed / 100 : 0);
    return (lights + fans).round();
  }

  String get _updatedLabel {
    final minute = _lastUpdated.minute.toString().padLeft(2, '0');
    return '${_lastUpdated.hour.toString().padLeft(2, '0')}:$minute';
  }

  void _refreshSensors() {
    const temperatures = [24.2, 24.7, 25.1, 24.5];
    const humidities = [68.0, 64.0, 71.0, 61.0];
    const lightLevels = [284.0, 410.0, 235.0, 348.0];
    _refreshCount = (_refreshCount + 1) % temperatures.length;

    setState(() {
      _temperature = temperatures[_refreshCount];
      _humidity = humidities[_refreshCount];
      _lightLevel = lightLevels[_refreshCount];
      _lastUpdated = DateTime.now();

      if (_autoLighting) {
        _mainLightsOn = _lightLevel < _lightThreshold;
        _mainBrightness = _mainLightsOn
            ? ((500 - _lightLevel) / 5).clamp(35, 100)
            : _mainBrightness;
      }
      if (_autoClimate) {
        _ceilingFanOn = _humidity >= _humidityThreshold;
        _ceilingFanSpeed = _ceilingFanOn
            ? (45 + (_humidity - _humidityThreshold) * 4).clamp(45, 100)
            : _ceilingFanSpeed;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sensor readings updated')),
    );
  }

  void _turnEverythingOff() {
    setState(() {
      _mainLightsOn = false;
      _boardLightsOn = false;
      _ceilingFanOn = false;
      _ventilationFanOn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceColumns = _wide(context) ? 2 : 1;
    final sensorColumns = _wide(context) ? 3 : (_mid(context) ? 3 : 1);

    return AppShell(
      title: 'Smart Classroom Control',
      subtitle: 'Classroom A-01 / Live device and sensor management',
      selectedRoute: '/device-control',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusStrip(
            activeDevices: _activeDevices,
            powerUsage: _powerUsage,
            updatedLabel: _updatedLabel,
            onRefresh: _refreshSensors,
            onAllOff: _turnEverythingOff,
          ),
          const SizedBox(height: 22),
          const _SectionHeading(
            title: 'Live classroom sensors',
            subtitle: 'Readings used by automatic fan and lighting controls',
          ),
          const SizedBox(height: 12),
          _Grid(
            columns: sensorColumns,
            children: [
              _SensorCard(
                label: 'Temperature',
                value: _temperature.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat_rounded,
                color: const Color(0xFFF97316),
                status: _temperature <= 26 ? 'Comfortable' : 'Warm',
                progress: (_temperature / 40).clamp(0, 1),
              ),
              _SensorCard(
                label: 'Humidity',
                value: _humidity.toStringAsFixed(0),
                unit: '%',
                icon: Icons.water_drop_outlined,
                color: const Color(0xFF0EA5E9),
                status: _humidity >= _humidityThreshold
                    ? 'Above threshold'
                    : 'Normal',
                progress: (_humidity / 100).clamp(0, 1),
              ),
              _SensorCard(
                label: 'Light level',
                value: _lightLevel.toStringAsFixed(0),
                unit: 'lux',
                icon: Icons.light_mode_outlined,
                color: const Color(0xFFF59E0B),
                status: _lightLevel < _lightThreshold ? 'Low light' : 'Bright',
                progress: (_lightLevel / 600).clamp(0, 1),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeading(
            title: 'Lights and fans',
            subtitle: 'Manual controls remain available when automation is on',
          ),
          const SizedBox(height: 12),
          _Grid(
            columns: deviceColumns,
            children: [
              _DeviceCard(
                title: 'Main classroom lights',
                subtitle: '6 ceiling LED panels',
                icon: Icons.lightbulb_outline_rounded,
                color: const Color(0xFFF59E0B),
                isOn: _mainLightsOn,
                value: _mainBrightness,
                valueLabel: 'Brightness',
                valueText: '${_mainBrightness.round()}%',
                power: _mainLightsOn
                    ? '${(96 * _mainBrightness / 100).round()} W'
                    : '0 W',
                onToggle: (value) => setState(() => _mainLightsOn = value),
                onChanged: (value) => setState(() {
                  _mainBrightness = value;
                  _mainLightsOn = value > 0;
                }),
              ),
              _DeviceCard(
                title: 'Board lights',
                subtitle: '2 focused LED strips',
                icon: Icons.highlight_outlined,
                color: const Color(0xFFF59E0B),
                isOn: _boardLightsOn,
                value: _boardBrightness,
                valueLabel: 'Brightness',
                valueText: '${_boardBrightness.round()}%',
                power: _boardLightsOn
                    ? '${(42 * _boardBrightness / 100).round()} W'
                    : '0 W',
                onToggle: (value) => setState(() => _boardLightsOn = value),
                onChanged: (value) => setState(() {
                  _boardBrightness = value;
                  _boardLightsOn = value > 0;
                }),
              ),
              _DeviceCard(
                title: 'Ceiling fans',
                subtitle: '4 classroom fans',
                icon: Icons.air_rounded,
                color: const Color(0xFF2563EB),
                isOn: _ceilingFanOn,
                value: _ceilingFanSpeed,
                valueLabel: 'Fan speed',
                valueText: '${_ceilingFanSpeed.round()}%',
                power: _ceilingFanOn
                    ? '${(75 * _ceilingFanSpeed / 100).round()} W'
                    : '0 W',
                onToggle: (value) => setState(() => _ceilingFanOn = value),
                onChanged: (value) => setState(() {
                  _ceilingFanSpeed = value;
                  _ceilingFanOn = value > 0;
                }),
              ),
              _DeviceCard(
                title: 'Ventilation fan',
                subtitle: 'Fresh-air circulation',
                icon: Icons.cyclone_rounded,
                color: const Color(0xFF14B8A6),
                isOn: _ventilationFanOn,
                value: _ventilationFanSpeed,
                valueLabel: 'Fan speed',
                valueText: '${_ventilationFanSpeed.round()}%',
                power: _ventilationFanOn
                    ? '${(55 * _ventilationFanSpeed / 100).round()} W'
                    : '0 W',
                onToggle: (value) => setState(() => _ventilationFanOn = value),
                onChanged: (value) => setState(() {
                  _ventilationFanSpeed = value;
                  _ventilationFanOn = value > 0;
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _AutomationPanel(
            autoLighting: _autoLighting,
            autoClimate: _autoClimate,
            lightThreshold: _lightThreshold,
            humidityThreshold: _humidityThreshold,
            onAutoLightingChanged: (value) =>
                setState(() => _autoLighting = value),
            onAutoClimateChanged: (value) =>
                setState(() => _autoClimate = value),
            onLightThresholdChanged: (value) =>
                setState(() => _lightThreshold = value),
            onHumidityThresholdChanged: (value) =>
                setState(() => _humidityThreshold = value),
          ),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({
    required this.activeDevices,
    required this.powerUsage,
    required this.updatedLabel,
    required this.onRefresh,
    required this.onAllOff,
  });

  final int activeDevices;
  final int powerUsage;
  final String updatedLabel;
  final VoidCallback onRefresh;
  final VoidCallback onAllOff;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172554), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Wrap(
        spacing: 28,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const _LiveIndicator(),
          _StatusValue(label: 'Active devices', value: '$activeDevices / 4'),
          _StatusValue(label: 'Current power', value: '$powerUsage W'),
          _StatusValue(label: 'Last sensor update', value: updatedLabel),
          OutlinedButton.icon(
            onPressed: onRefresh,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: const Text('Read sensors'),
          ),
          FilledButton.icon(
            onPressed: onAllOff,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E3A8A),
            ),
            icon: const Icon(Icons.power_settings_new_rounded, size: 18),
            label: const Text('All off'),
          ),
        ],
      ),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.sensors_rounded, color: Color(0xFF86EFAC)),
        SizedBox(width: 8),
        Text(
          'SYSTEM ONLINE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _StatusValue extends StatelessWidget {
  const _StatusValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final width =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.status,
    required this.progress,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String status;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 3),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF0F172A)),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                      fontSize: 29, fontWeight: FontWeight.w900),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isOn,
    required this.value,
    required this.valueLabel,
    required this.valueText,
    required this.power,
    required this.onToggle,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isOn;
  final double value;
  final String valueLabel;
  final String valueText;
  final String power;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      highlighted: isOn,
      highlightColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isOn ? 0.16 : 0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    Icon(icon, color: isOn ? color : const Color(0xFF94A3B8)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Switch(value: isOn, activeTrackColor: color, onChanged: onToggle),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(valueLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(valueText,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900)),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 100,
            activeColor: color,
            onChanged: onChanged,
          ),
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 17, color: color),
              const SizedBox(width: 4),
              Text(power,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(
                isOn ? 'ON' : 'OFF',
                style: TextStyle(
                  color:
                      isOn ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AutomationPanel extends StatelessWidget {
  const _AutomationPanel({
    required this.autoLighting,
    required this.autoClimate,
    required this.lightThreshold,
    required this.humidityThreshold,
    required this.onAutoLightingChanged,
    required this.onAutoClimateChanged,
    required this.onLightThresholdChanged,
    required this.onHumidityThresholdChanged,
  });

  final bool autoLighting;
  final bool autoClimate;
  final double lightThreshold;
  final double humidityThreshold;
  final ValueChanged<bool> onAutoLightingChanged;
  final ValueChanged<bool> onAutoClimateChanged;
  final ValueChanged<double> onLightThresholdChanged;
  final ValueChanged<double> onHumidityThresholdChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED)),
              SizedBox(width: 9),
              Text('Sensor automation',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Devices are adjusted after each sensor reading according to these rules.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final lighting = _AutomationRule(
                icon: Icons.light_mode_outlined,
                title: 'Automatic lighting',
                description:
                    'Turn on main lights below ${lightThreshold.round()} lux',
                enabled: autoLighting,
                value: lightThreshold,
                min: 100,
                max: 500,
                divisions: 8,
                onToggle: onAutoLightingChanged,
                onChanged: onLightThresholdChanged,
              );
              final climate = _AutomationRule(
                icon: Icons.water_drop_outlined,
                title: 'Humidity control',
                description:
                    'Turn on ceiling fans above ${humidityThreshold.round()}%',
                enabled: autoClimate,
                value: humidityThreshold,
                min: 40,
                max: 80,
                divisions: 8,
                onToggle: onAutoClimateChanged,
                onChanged: onHumidityThresholdChanged,
              );
              if (!wide) {
                return Column(
                    children: [lighting, const SizedBox(height: 14), climate]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: lighting),
                  const SizedBox(width: 14),
                  Expanded(child: climate),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AutomationRule extends StatelessWidget {
  const _AutomationRule({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onToggle,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF475569)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(description,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onToggle),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.round().toString(),
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.highlighted = false,
    this.highlightColor = const Color(0xFF2563EB),
  });

  final Widget child;
  final bool highlighted;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? highlightColor.withValues(alpha: 0.25)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
