import '../network/api_client.dart';
import '../../features/auth/auth_service.dart';

final apiClient = ApiClient(
  baseUrl: 'http://127.0.0.1:4000',
);

final authService = AuthService(apiClient);
