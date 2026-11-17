import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';
  static const String _mockUserKey = 'mock_user';
  static const String _mockTasksKey = 'mock_tasks';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, String>> _getHeaders({bool needAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (needAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<dynamic> _handleMockRequest(String path, String method, Map<String, dynamic>? body) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (path.startsWith('/auth/login') || path.startsWith('/auth/register')) {
      final email = body?['email'] ?? 'user@example.com';
      final name = body?['fullName'] ?? 'Người dùng';
      final mockUser = {
        'id': 'mock_user_1',
        'fullName': name,
        'email': email,
        'avatarUrl': '',
      };
      await prefs.setString(_mockUserKey, jsonEncode(mockUser));
      return {
        'message': 'Thành công (Mock Mode)',
        'token': 'mock_jwt_token_12345',
        'user': mockUser,
      };
    }

    if (path.startsWith('/auth/me')) {
      final userStr = prefs.getString(_mockUserKey);
      final user = userStr != null ? jsonDecode(userStr) : {
        'id': 'mock_user_1',
        'fullName': 'Mai Lê Huy Hoàng',
        'email': 'huyhoang0106@gmail.com',
        'avatarUrl': '',
      };
      return {'user': user};
    }

    if (path.startsWith('/auth/change-password') || path.startsWith('/auth/me')) {
      if (method == 'PUT' && body != null && body['fullName'] != null) {
        final userStr = prefs.getString(_mockUserKey);
        final user = userStr != null ? jsonDecode(userStr) : {};
        user['fullName'] = body['fullName'];
        await prefs.setString(_mockUserKey, jsonEncode(user));
        return {'message': 'Cập nhật thành công', 'user': user};
      }
      return {'message': 'Thành công'};
    }

    List<dynamic> getStoredTasks() {
      final tasksStr = prefs.getString(_mockTasksKey);
      if (tasksStr == null) {
        final defaultTasks = [
          {
            '_id': 'task_1',
            'title': 'Hoàn thành Case Study 2 - Phần B',
            'description': 'Phát triển ứng dụng Quản lý công việc Flutter & Node.js API',
            'priority': 'high',
            'status': 'in_progress',
            'startDate': DateTime.now().toIso8601String(),
            'dueDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
            'createdAt': DateTime.now().toIso8601String(),
            'createdBy': {'_id': 'mock_user_1', 'fullName': 'Mai Lê Huy Hoàng', 'email': 'huyhoang0106@gmail.com'},
          }
        ];
        prefs.setString(_mockTasksKey, jsonEncode(defaultTasks));
        return defaultTasks;
      }
      return jsonDecode(tasksStr);
    }

    if (path.startsWith('/tasks') && method == 'GET' && !path.contains('/activities')) {
      var tasks = getStoredTasks();
      return {'tasks': tasks};
    }

    if (path.startsWith('/tasks') && method == 'POST') {
      var tasks = getStoredTasks();
      final newTask = {
        '_id': 'task_${DateTime.now().millisecondsSinceEpoch}',
        'title': body?['title'] ?? 'Công việc mới',
        'description': body?['description'] ?? '',
        'priority': body?['priority'] ?? 'medium',
        'status': body?['status'] ?? 'todo',
        'startDate': body?['startDate'],
        'dueDate': body?['dueDate'],
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': {'_id': 'mock_user_1', 'fullName': 'Mai Lê Huy Hoàng', 'email': 'huyhoang0106@gmail.com'},
      };
      tasks.insert(0, newTask);
      await prefs.setString(_mockTasksKey, jsonEncode(tasks));
      return {'message': 'Tạo thành công', 'task': newTask};
    }

    if (path.contains('/status') && method == 'PATCH') {
      var tasks = getStoredTasks();
      final id = path.split('/')[2];
      for (var t in tasks) {
        if (t['_id'] == id) {
          t['status'] = body?['status'] ?? t['status'];
        }
      }
      await prefs.setString(_mockTasksKey, jsonEncode(tasks));
      return {'message': 'Cập nhật trạng thái thành công'};
    }

    if (path.startsWith('/tasks/') && method == 'PUT') {
      var tasks = getStoredTasks();
      final id = path.split('/')[2];
      for (var t in tasks) {
        if (t['_id'] == id) {
          t['title'] = body?['title'] ?? t['title'];
          t['description'] = body?['description'] ?? t['description'];
          t['priority'] = body?['priority'] ?? t['priority'];
          t['status'] = body?['status'] ?? t['status'];
          t['startDate'] = body?['startDate'];
          t['dueDate'] = body?['dueDate'];
        }
      }
      await prefs.setString(_mockTasksKey, jsonEncode(tasks));
      return {'message': 'Cập nhật thành công'};
    }

    if (path.startsWith('/tasks/') && method == 'DELETE') {
      var tasks = getStoredTasks();
      final id = path.split('/')[2];
      tasks.removeWhere((t) => t['_id'] == id);
      await prefs.setString(_mockTasksKey, jsonEncode(tasks));
      return {'message': 'Xóa thành công'};
    }

    if (path.startsWith('/tasks/') && method == 'GET') {
      var tasks = getStoredTasks();
      final id = path.split('/')[2];
      final task = tasks.firstWhere((t) => t['_id'] == id, orElse: () => tasks.first);
      return {'task': task};
    }

    return {'message': 'Thành công'};
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = response.body.isEmpty ? {} : jsonDecode(response.body);
    } catch (_) {
      body = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String message = 'Đã xảy ra lỗi (${response.statusCode})';
    if (body is Map && body.containsKey('message')) {
      message = body['message'].toString();
    }
    throw Exception(message);
  }

  static Future<dynamic> get(String path, {bool auth = true}) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}$path'),
            headers: await _getHeaders(needAuth: auth),
          )
          .timeout(const Duration(seconds: 5));
      return _handleResponse(response);
    } catch (_) {
      return await _handleMockRequest(path, 'GET', null);
    }
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}$path'),
            headers: await _getHeaders(needAuth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
      return _handleResponse(response);
    } catch (_) {
      return await _handleMockRequest(path, 'POST', body);
    }
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body, {bool auth = true}) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppConfig.baseUrl}$path'),
            headers: await _getHeaders(needAuth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
      return _handleResponse(response);
    } catch (_) {
      return await _handleMockRequest(path, 'PUT', body);
    }
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body, {bool auth = true}) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${AppConfig.baseUrl}$path'),
            headers: await _getHeaders(needAuth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
      return _handleResponse(response);
    } catch (_) {
      return await _handleMockRequest(path, 'PATCH', body);
    }
  }

  static Future<dynamic> delete(String path, {bool auth = true}) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${AppConfig.baseUrl}$path'),
            headers: await _getHeaders(needAuth: auth),
          )
          .timeout(const Duration(seconds: 5));
      return _handleResponse(response);
    } catch (_) {
      return await _handleMockRequest(path, 'DELETE', null);
    }
  }
}
