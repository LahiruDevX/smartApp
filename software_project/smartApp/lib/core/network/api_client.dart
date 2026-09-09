import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, {this.statusCode = 500});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    String? baseUrl,
    TokenStorage? tokenStorage,
  })  : baseUrl = baseUrl ?? _defaultBaseUrl,
        _tokenStorage = tokenStorage ?? TokenStorage();

  static const String _defaultBaseUrl = 'http://127.0.0.1:4000';

  String baseUrl;
  final TokenStorage _tokenStorage;

  // In-memory cache of logged-in user details
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get currentRole => _currentUser?['role']?.toString().toLowerCase();
  String? get currentEmail => _currentUser?['email']?.toString();
  int? get currentUserId => _currentUser?['id'] as int?;

  void setCurrentUser(Map<String, dynamic>? user) {
    _currentUser = user;
  }

  // ---------------- Helper Methods ----------------

  dynamic _decodeBody(http.Response res) {
    if (res.body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return {'message': res.body};
    }
  }

  void _ensureOk(http.Response res, dynamic data) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Request failed (${res.statusCode})';
      if (data is Map) {
        msg = (data['error'] ?? data['message'] ?? msg).toString();
      }
      throw ApiException(msg, statusCode: res.statusCode);
    }
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) {
      throw ApiException('No authentication token found. Please log in.', statusCode: 401);
    }
    return token;
  }

  // ---------------- Public Requests (No Token) ----------------

  Future<dynamic> get(String path) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: const {'Content-Type': 'application/json'},
      );
      final data = _decodeBody(res);
      _ensureOk(res, data);
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection failed: $e');
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = _decodeBody(res);
      _ensureOk(res, data);
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection failed: $e');
    }
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = _decodeBody(res);
      _ensureOk(res, data);
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection failed: $e');
    }
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl$path'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = _decodeBody(res);
      _ensureOk(res, data);
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection failed: $e');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: const {'Content-Type': 'application/json'},
      );
      final data = _decodeBody(res);
      _ensureOk(res, data);
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection failed: $e');
    }
  }

  // ---------------- Authed Requests (Token Included) ----------------

  Future<dynamic> getAuthed(String path) async {
    final token = await _requireToken();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final data = _decodeBody(res);
      _ensureOk(res, data);
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request error: $e');
    }
  }

  Future<dynamic> postAuthed(String path, Map<String, dynamic> body) async {
    final token = await _requireToken();
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      final data = _decodeBody(res);
      _ensureOk(res, data);
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request error: $e');
    }
  }

  Future<dynamic> putAuthed(String path, Map<String, dynamic> body) async {
    final token = await _requireToken();
    try {
      final res = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      final data = _decodeBody(res);
      _ensureOk(res, data);
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request error: $e');
    }
  }

  Future<dynamic> patchAuthed(String path, Map<String, dynamic> body) async {
    final token = await _requireToken();
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      final data = _decodeBody(res);
      _ensureOk(res, data);
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request error: $e');
    }
  }

  Future<dynamic> deleteAuthed(String path) async {
    final token = await _requireToken();
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final data = _decodeBody(res);
      _ensureOk(res, data);
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request error: $e');
    }
  }

  // ---------------- Token & Session Management ----------------

  Future<void> saveToken(String token) => _tokenStorage.save(token);
  Future<String?> getToken() => _tokenStorage.read();
  Future<void> logout() async {
    _currentUser = null;
    await _tokenStorage.clear();
  }
}
