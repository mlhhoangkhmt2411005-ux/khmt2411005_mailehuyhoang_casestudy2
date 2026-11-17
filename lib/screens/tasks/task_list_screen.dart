import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/api_service.dart';
import '../../widgets/task_card.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _loading = true;

  // Filters & Search
  final _searchController = TextEditingController();
  String _selectedScope = '';
  String _selectedStatus = '';
  String _selectedPriority = '';
  String _selectedSortBy = 'createdAt';
  final String _selectedOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final queryParams = <String, String>{};
      if (_selectedScope.isNotEmpty) queryParams['scope'] = _selectedScope;
      if (_selectedStatus.isNotEmpty) queryParams['status'] = _selectedStatus;
      if (_selectedPriority.isNotEmpty) queryParams['priority'] = _selectedPriority;
      if (_searchController.text.trim().isNotEmpty) {
        queryParams['q'] = _searchController.text.trim();
      }
      queryParams['sortBy'] = _selectedSortBy;
      queryParams['order'] = _selectedOrder;

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      final path = '/tasks${queryString.isEmpty ? '' : '?$queryString'}';
      final res = await ApiService.get(path);

      if (res['tasks'] != null && res['tasks'] is List) {
        final list = res['tasks'] as List;
        _tasks = list.map((e) => Task.fromJson(Map<String, dynamic>.from(e))).toList();
      } else {
        _tasks = [];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateTaskStatus(Task task, String newStatus) async {
    try {
      await ApiService.patch('/tasks/${task.id}/status', {'status': newStatus});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chuyển trạng thái sang "${Task.statusLabel(newStatus)}"'),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa công việc "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('HỦY'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('XÓA'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.delete('/tasks/${task.id}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa công việc.')),
      );
      _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _openForm([Task? task]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    );

    if (changed == true) {
      _loadTasks();
    }
  }

  Future<void> _openDetail(Task task) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
    );

    if (changed == true) {
      _loadTasks();
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('HỦY'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ĐĂNG XUẤT'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Công Việc'),
        backgroundColor: const Color(0xFF3659D9),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
          IconButton(
            tooltip: 'Thông tin cá nhân',
            icon: const Icon(Icons.account_circle),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              _loadTasks();
            },
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF3659D9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm công việc', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter & Search Header Panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm công việc theo tên...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadTasks();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onSubmitted: (_) => _loadTasks(),
                ),
                const SizedBox(height: 10),

                // Filters Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'todo', child: Text('Chưa làm')),
                          DropdownMenuItem(value: 'in_progress', child: Text('Đang làm')),
                          DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedStatus = val ?? '');
                          _loadTasks();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedPriority,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Ưu tiên',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'low', child: Text('Thấp')),
                          DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
                          DropdownMenuItem(value: 'high', child: Text('Cao')),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedPriority = val ?? '');
                          _loadTasks();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSortBy,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Sắp xếp theo',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'createdAt', child: Text('Ngày tạo')),
                          DropdownMenuItem(value: 'dueDate', child: Text('Hạn hoàn thành')),
                          DropdownMenuItem(value: 'priority', child: Text('Mức ưu tiên')),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedSortBy = val ?? 'createdAt');
                          _loadTasks();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Task List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: _tasks.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Icon(Icons.inbox, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'Chưa có công việc nào.\nNhấn nút "Thêm công việc" bên dưới để bắt đầu.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 88),
                            itemCount: _tasks.length,
                            itemBuilder: (context, index) {
                              final task = _tasks[index];
                              return TaskCard(
                                task: task,
                                onTap: () => _openDetail(task),
                                onEdit: () => _openForm(task),
                                onDelete: () => _deleteTask(task),
                                onStatusChanged: (newStatus) => _updateTaskStatus(task, newStatus),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
