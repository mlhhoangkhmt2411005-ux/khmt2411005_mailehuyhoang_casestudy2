import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../services/api_service.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_badge.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Task? _task;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTaskDetail();
  }

  Future<void> _loadTaskDetail() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/tasks/${widget.taskId}');
      if (res['task'] != null) {
        _task = Task.fromJson(Map<String, dynamic>.from(res['task']));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_task == null) return;
    try {
      await ApiService.patch('/tasks/${_task!.id}/status', {'status': newStatus});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật trạng thái: ${Task.statusLabel(newStatus)}')),
      );
      await _loadTaskDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _deleteTask() async {
    if (_task == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa công việc "${_task!.title}"?'),
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
      await ApiService.delete('/tasks/${_task!.id}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa công việc thành công.')),
      );
      Navigator.pop(context, true); // Return true to indicate change
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _navigateToEdit() async {
    if (_task == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(task: _task),
      ),
    );

    if (updated == true) {
      _loadTaskDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final dateOnlyFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        actions: [
          if (_task != null) ...[
            IconButton(
              tooltip: 'Chỉnh sửa',
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEdit,
            ),
            IconButton(
              tooltip: 'Xóa công việc',
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _deleteTask,
            ),
          ]
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _task == null
              ? const Center(child: Text('Không tìm thấy thông tin công việc.'))
              : RefreshIndicator(
                  onRefresh: _loadTaskDetail,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Header Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _task!.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  StatusBadge(status: _task!.status),
                                  PriorityBadge(priority: _task!.priority),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Status Change Section
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cập nhật nhanh trạng thái',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SegmentedButton<String>(
                                selected: {_task!.status},
                                onSelectionChanged: (Set<String> newSelection) {
                                  _updateStatus(newSelection.first);
                                },
                                segments: const [
                                  ButtonSegment<String>(
                                    value: 'todo',
                                    label: Text('Chưa làm'),
                                    icon: Icon(Icons.schedule, size: 16),
                                  ),
                                  ButtonSegment<String>(
                                    value: 'in_progress',
                                    label: Text('Đang làm'),
                                    icon: Icon(Icons.sync, size: 16),
                                  ),
                                  ButtonSegment<String>(
                                    value: 'completed',
                                    label: Text('Hoàn thành'),
                                    icon: Icon(Icons.check_circle, size: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dates & Description Card
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin thời gian & Mô tả',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  const Icon(Icons.play_arrow, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ngày bắt đầu: ${_task!.startDate != null ? dateOnlyFormat.format(_task!.startDate!) : 'Chưa đặt'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.event, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Hạn hoàn thành: ${_task!.dueDate != null ? dateOnlyFormat.format(_task!.dueDate!) : 'Chưa đặt'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: (_task!.dueDate != null &&
                                              _task!.dueDate!.isBefore(DateTime.now()) &&
                                              _task!.status != 'completed')
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: (_task!.dueDate != null &&
                                              _task!.dueDate!.isBefore(DateTime.now()) &&
                                              _task!.status != 'completed')
                                          ? Colors.red
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              const Text(
                                'Mô tả chi tiết:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _task!.description.isEmpty
                                    ? '(Không có mô tả)'
                                    : _task!.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _task!.description.isEmpty
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // User Info Card
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin liên quan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_task!.createdBy != null)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text('Người tạo: ${_task!.createdBy!.fullName}'),
                                  subtitle: Text(_task!.createdBy!.email),
                                ),
                              if (_task!.createdAt != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Thời gian tạo: ${dateFormat.format(_task!.createdAt!)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
