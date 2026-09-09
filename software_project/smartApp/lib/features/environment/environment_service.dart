import '../../core/network/api_client.dart';

class EnvironmentService {
  EnvironmentService(this.api);
  final ApiClient api;

  Future<Map<String, dynamic>> latest() async {
    final res = await api.get('/api/environment/latest');
    return (res as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> history() async {
    final res = await api.get('/api/environment/history');
    return (res as Map<String, dynamic>?) ?? {};
  }
}

