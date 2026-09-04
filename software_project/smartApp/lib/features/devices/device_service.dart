import '../../core/network/api_client.dart';
import 'device_model.dart';

class DeviceService {
  DeviceService(this.api);
  final ApiClient api;

  Future<List<DeviceModel>> fetchDevices() async {
    final res = await api.getAuthed('/api/devices');
    final list = (res['devices'] as List?) ?? [];
    return list
        .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateDevice({
    required String id,
    required bool isOn,
    int? sliderValue,
  }) async {
    await api.patchAuthed('/api/devices/$id', {
      'isOn': isOn,
      'sliderValue': sliderValue,
    });
  }
}
