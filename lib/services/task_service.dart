import '../models/task.dart';
import 'api_client.dart';

class TaskService {
  static Future<List<Task>> getTasks({String? status, String? priority, String? search}) async {
    String query = '';
    List<String> params = [];
    if (status != null && status.isNotEmpty) params.add('status=$status');
    if (priority != null && priority.isNotEmpty) params.add('priority=$priority');
    if (search != null && search.isNotEmpty) params.add('search=$search');
    if (params.isNotEmpty) {
      query = '?${params.join('&')}';
    }

    final response = await ApiClient.get('/tasks$query');
    if (response is List) {
      return response.map((e) => Task.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Task> getTaskById(String id) async {
    final response = await ApiClient.get('/tasks/$id');
    return Task.fromJson(response);
  }

  static Future<Task> createTask(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/tasks', data);
    return Task.fromJson(response);
  }

  static Future<Task> updateTask(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.post('/tasks/$id', data);
    return Task.fromJson(response);
  }

  static Future<void> deleteTask(String id) async {
    await ApiClient.get('/tasks/$id/delete');
  }

  static Future<Task> updateStatus(String id, String status) async {
    final response = await ApiClient.post('/tasks/$id/status', {'status': status});
    return Task.fromJson(response);
  }

  static Future<List<dynamic>> getTaskActivities(String id) async {
    final response = await ApiClient.get('/tasks/$id/activities');
    if (response is List) return response;
    return [];
  }
}
