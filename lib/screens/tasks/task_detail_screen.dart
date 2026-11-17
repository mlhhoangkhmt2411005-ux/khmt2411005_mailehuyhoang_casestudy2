import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_badge.dart';
import 'task_edit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Task? _task;
  bool _isLoading = true;
  List<dynamic> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadTaskDetail();
  }

  void _loadTaskDetail() async {
    setState(() => _isLoading = true);
    try {
      final task = await TaskService.getTaskById(widget.taskId);
      final activities = await TaskService.getTaskActivities(widget.taskId);
      setState(() {
        _task = task;
        _activities = activities;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateStatus(String status) async {
    try {
      final updated = await TaskService.updateStatus(widget.taskId, status);
      setState(() => _task = updated);
      _loadTaskDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa công việc này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TaskService.deleteTask(widget.taskId);
        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    if (_task == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Không tìm thấy công việc')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_task!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TaskEditScreen(task: _task!)),
              );
              if (updated == true) _loadTaskDetail();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(status: _task!.status),
                PriorityBadge(priority: _task!.priority),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Mô tả:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_task!.description, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Bắt đầu: ${DateFormatter.formatDate(_task!.startDate)}'),
                const SizedBox(width: 24),
                const Icon(Icons.event, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Hạn: ${DateFormatter.formatDate(_task!.dueDate)}'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Cập nhật trạng thái:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: const Text('Chưa làm'),
                  selected: _task!.status == 'todo',
                  onSelected: (selected) {
                    if (selected) _updateStatus('todo');
                  },
                ),
                ChoiceChip(
                  label: const Text('Đang làm'),
                  selected: _task!.status == 'in_progress',
                  onSelected: (selected) {
                    if (selected) _updateStatus('in_progress');
                  },
                ),
                ChoiceChip(
                  label: const Text('Hoàn thành'),
                  selected: _task!.status == 'completed',
                  onSelected: (selected) {
                    if (selected) _updateStatus('completed');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Lịch sử hoạt động:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final act = _activities[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.history, size: 16),
                  title: Text(act['action'] ?? ''),
                  subtitle: Text(DateFormatter.formatDateTime(DateTime.tryParse(act['createdAt'] ?? ''))),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
