import 'package:flutter/material.dart';
import 'app_shell.dart';

import '../../core/di/app_di.dart';
import '../../features/devices/device_service.dart';
import '../../features/devices/device_model.dart';
 



class DeviceControlScreen extends StatefulWidget {
  const DeviceControlScreen({super.key});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;
  bool _mid(BuildContext c) => MediaQuery.of(c).size.width >= 680;

  late final DeviceService _deviceService;

  bool _loading = true;
  String? _error;

  // Devices from backend
  List<DeviceModel> _devices = [];

  // UI metadata for cards (icons, slider ranges, power usage, etc.)
  final Map<String, _DeviceUiMeta> _ui = {
    'main_lights': _DeviceUiMeta(
      subtitle: 'light',
      icon: Icons.lightbulb_outline,
      hasSlider: true,
      sliderLabel: 'Brightness',
      sliderUnit: '%',
      sliderMin: 0,
      sliderMax: 100,
      powerWhenOn: 120,
    ),
    'board_lights': _DeviceUiMeta(
      subtitle: 'light',
      icon: Icons.lightbulb_outline,
      hasSlider: true,
      sliderLabel: 'Brightness',
      sliderUnit: '%',
      sliderMin: 0,
      sliderMax: 100,
      powerWhenOn: 60,
    ),
    'projector': _DeviceUiMeta(
      subtitle: 'projector',
      icon: Icons.tv_outlined,
      hasSlider: false,
      powerWhenOn: 300,
    ),
    'hvac': _DeviceUiMeta(
      subtitle: 'hvac',
      icon: Icons.air_outlined,
      hasSlider: true,
      sliderLabel: 'Temperature',
      sliderUnit: '°C',
      sliderMin: 16,
      sliderMax: 30,
      powerWhenOn: 1500,
    ),
    'audio': _DeviceUiMeta(
      subtitle: 'audio',
      icon: Icons.volume_up_outlined,
      hasSlider: false,
      powerWhenOn: 250,
    ),
    'emergency_lights': _DeviceUiMeta(
      subtitle: 'light',
      icon: Icons.lightbulb_outline,
      hasSlider: true,
      sliderLabel: 'Brightness',
      sliderUnit: '%',
      sliderMin: 0,
      sliderMax: 100,
      powerWhenOn: 40,
    ),
  };

  @override
  void initState() {
    super.initState();

    _deviceService = DeviceService(apiClient);

    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final devices = await _deviceService.fetchDevices();

      // If backend doesn't send sliderValue for non-slider devices, keep it null
      setState(() {
        _devices = devices;
        _loading = false;
      });

      debugPrint('✅ Devices loaded: ${devices.length}');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      debugPrint('❌ Load devices failed: $e');
    }
  }

  int get _activeCount => _devices.where((d) => d.isOn).length;

  int get _totalPowerW {
    int sum = 0;
    for (final d in _devices) {
      final meta = _ui[d.id];
      final power = meta?.powerWhenOn ?? 0;
      if (d.isOn) sum += power;
    }
    return sum;
  }

  double get _estimatedCostPerHour {
    // Example tariff: $0.00012 per Wh
    return _totalPowerW * 0.00012;
  }

  Future<void> _turnAll(bool on) async {
    // optimistic update
    setState(() {
      for (final d in _devices) {
        d.isOn = on;
      }
    });

    // send updates to backend
    for (final d in _devices) {
      try {
        await _deviceService.updateDevice(
          id: d.id,
          isOn: d.isOn,
          sliderValue: d.sliderValue,
        );
      } catch (e) {
        debugPrint('❌ Failed update ${d.id}: $e');
      }
    }
  }

  Future<void> _toggle(DeviceModel d) async {
    final newValue = !d.isOn;

    // optimistic update
    setState(() => d.isOn = newValue);

    try {
      await _deviceService.updateDevice(
        id: d.id,
        isOn: d.isOn,
        sliderValue: d.sliderValue,
      );
      debugPrint('✅ Updated ${d.id}: isOn=${d.isOn}');
    } catch (e) {
      // revert on error
      setState(() => d.isOn = !newValue);
      debugPrint('❌ Toggle failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  Future<void> _setSlider(DeviceModel d, int value) async {
    // optimistic update
    setState(() => d.sliderValue = value);

    try {
      await _deviceService.updateDevice(
        id: d.id,
        isOn: d.isOn,
        sliderValue: d.sliderValue,
      );
    } catch (e) {
      debugPrint('❌ Slider update failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cols = _wide(context) ? 3 : (_mid(context) ? 2 : 1);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('❌ Failed to load devices\n\n$_error'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadDevices,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppShell(
      title: 'Device Control Center',
      subtitle: 'Manage and monitor all classroom devices',
      selectedRoute: '/device-control',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Grid(
            columns: _wide(context) ? 3 : (_mid(context) ? 2 : 1),
            children: [
              _SummaryCard(title: 'Total Power', value: '$_totalPowerW W'),
              _SummaryCard(
                title: 'Active Devices',
                value: '$_activeCount/${_devices.length}',
              ),
              _SummaryCard(
                title: 'Estimated Cost',
                value: '\$${_estimatedCostPerHour.toStringAsFixed(2)} /hr',
              ),
            ],
          ),
          const SizedBox(height: 14),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionButton(
                label: 'Turn All On',
                color: const Color(0xFF16A34A),
                onTap: () => _turnAll(true),
              ),
              _ActionButton(
                label: 'Turn All Off',
                color: const Color(0xFFDC2626),
                onTap: () => _turnAll(false),
              ),
              _ActionButton(
                label: 'Refresh',
                color: const Color(0xFF2D66F6),
                onTap: _loadDevices,
              ),
            ],
          ),

          const SizedBox(height: 14),

          _Grid(
            columns: cols,
            children: _devices.map((d) {
              final meta = _ui[d.id] ??
                  _DeviceUiMeta(
                    subtitle: 'device',
                    icon: Icons.devices_other,
                    hasSlider: d.sliderValue != null,
                    sliderLabel: 'Value',
                    sliderUnit: '',
                    sliderMin: 0,
                    sliderMax: 100,
                    powerWhenOn: 0,
                  );

              return _DeviceCard(
                device: d,
                meta: meta,
                onToggle: () => _toggle(d),
                onSlider: (v) => _setSlider(d, v.round()),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/* ---------------- widgets ---------------- */

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
        children: children.map((e) => SizedBox(width: itemW, child: e)).toList(),
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 14),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.60),
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
        ),
        child: Text(label),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.meta,
    required this.onToggle,
    required this.onSlider,
  });

  final DeviceModel device;
  final _DeviceUiMeta meta;
  final VoidCallback onToggle;
  final ValueChanged<double> onSlider;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF2D66F6);
    final hasSlider = meta.hasSlider;

    // Ensure sliderValue exists for slider devices
    final sliderValue = (device.sliderValue ?? meta.sliderMin).clamp(meta.sliderMin, meta.sliderMax);

    return Container(
      height: hasSlider ? 220 : 175,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 14),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _IconTile(icon: meta.icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.prettyTitle(device.title),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withOpacity(0.55),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _PowerButton(isOn: device.isOn, onTap: onToggle, accent: accent),
            ],
          ),
          const SizedBox(height: 12),
          if (hasSlider) ...[
            Row(
              children: [
                Text(
                  meta.sliderLabel ?? 'Value',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.black.withOpacity(0.6),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '$sliderValue${meta.sliderUnit}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: sliderValue.toDouble(),
                min: meta.sliderMin.toDouble(),
                max: meta.sliderMax.toDouble(),
                onChanged: device.isOn ? onSlider : null,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Text(
                'Power Usage',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.black.withOpacity(0.6),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                device.isOn ? '${meta.powerWhenOn}W' : '0W',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF2D66F6)),
    );
  }
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.isOn,
    required this.onTap,
    required this.accent,
  });

  final bool isOn;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isOn ? accent : const Color(0xFFEFF2F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.power_settings_new,
          color: isOn ? Colors.white : Colors.black.withOpacity(0.55),
          size: 20,
        ),
      ),
    );
  }
}

/* ---------------- UI meta ---------------- */

class _DeviceUiMeta {
  _DeviceUiMeta({
    required this.subtitle,
    required this.icon,
    required this.hasSlider,
    required this.powerWhenOn,
    this.sliderLabel,
    this.sliderUnit = '',
    this.sliderMin = 0,
    this.sliderMax = 100,
  });

  final String subtitle;
  final IconData icon;
  final bool hasSlider;

  final int powerWhenOn;

  final String? sliderLabel;
  final String sliderUnit;
  final int sliderMin;
  final int sliderMax;

  // Backend title is "Main Lights" but your UI sometimes wants "Main\nLights"
  String prettyTitle(String backendTitle) {
    // keep backend title as-is; you can customize line breaks if you want
    return backendTitle;
  }
}
