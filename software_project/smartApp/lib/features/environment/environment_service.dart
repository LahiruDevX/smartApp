import '../../core/network/api_client.dart';

class SensorReading {
  const SensorReading({
    required this.type,
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
  });

  final String type;
  final String label;
  final double value;
  final String unit;
  final String status;

  bool get isWarning => status.toLowerCase() == 'warning';

  factory SensorReading.fromJson(Map<String, dynamic> j) => SensorReading(
        type: j['type'] as String,
        label: (j['label'] ?? j['type']) as String,
        value: (j['value'] as num).toDouble(),
        unit: j['unit'] as String,
        status: (j['status'] ?? 'normal') as String,
      );
}

class EnvironmentLatest {
  const EnvironmentLatest({required this.sensors, required this.updatedAt});

  final List<SensorReading> sensors;
  final DateTime? updatedAt;

  SensorReading? byType(String type) {
    for (final s in sensors) {
      if (s.type == type) return s;
    }
    return null;
  }
}

/// A single point on a sensor history chart. [t] is minutes on a 0..window axis
/// (0 = oldest, window = now).
class SeriesPoint {
  const SeriesPoint(this.t, this.value);
  final double t;
  final double value;
}

class EnvironmentService {
  EnvironmentService(this.api);
  final ApiClient api;

  Future<EnvironmentLatest> latest() async {
    final res = await api.getAuthed('/api/environment/latest');
    final list = (res['sensors'] as List?) ?? const [];
    return EnvironmentLatest(
      sensors: list
          .map((e) => SensorReading.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt: res['updatedAt'] == null
          ? null
          : DateTime.tryParse(res['updatedAt'] as String),
    );
  }

  /// Returns `{ 'temperature': [SeriesPoint...], 'humidity': [...], ... }`.
  Future<Map<String, List<SeriesPoint>>> history({int minutes = 20}) async {
    final res = await api.getAuthed('/api/environment/history?minutes=$minutes');
    final series = (res['series'] as Map?) ?? const {};
    return series.map((key, value) {
      final pts = (value as List)
          .map((p) => SeriesPoint(
                (p['t'] as num).toDouble(),
                (p['value'] as num).toDouble(),
              ))
          .toList();
      return MapEntry(key as String, pts);
    });
  }
}
