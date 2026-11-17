import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../services/api_service.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _priority = 'medium';
  String _status = 'todo';
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _loading = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.task!;
      _titleController.text = t.title;
      _descriptionController.text = t.description;
      _priority = t.priority;
      _status = t.status;
      _startDate = t.startDate;
      _dueDate = t.dueDate;
    }
  }

  Future<void> _pickDate(bool isStartDate) async {
    final initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_dueDate ?? _startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If due date is set and before new start date, update due date to start date
          if (_dueDate != null && _dueDate!.isBefore(_startDate!)) {
            _dueDate = _startDate;
          }
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate != null && _dueDate != null && _dueDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hạn hoàn thành không được nhỏ hơn ngày bắt đầu.')),
      );
      return;
    }

    setState(() => _loading = true);

    final payload = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'priority': _priority,
      'status': _status,
      'startDate': _startDate?.toIso8601String(),
      'dueDate': _dueDate?.toIso8601String(),
    };

    try {
      if (_isEditing) {
        await ApiService.put('/tasks/${widget.task!.id}', payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật công việc thành công!')),
        );
      } else {
        await ApiService.post('/tasks', payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo mới công việc thành công!')),
        );
      }
      Navigator.pop(context, true); // Return true to refresh list
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa công việc' : 'Thêm công việc mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tên công việc *',
                          hintText: 'Nhập tên công việc...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên công việc.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả chi tiết',
                          hintText: 'Nhập thông tin mô tả cho công việc...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _priority,
                              decoration: const InputDecoration(
                                labelText: 'Mức độ ưu tiên',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'low', child: Text('Thấp')),
                                DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
                                DropdownMenuItem(value: 'high', child: Text('Cao')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _priority = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: const InputDecoration(
                                labelText: 'Trạng thái',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'todo', child: Text('Chưa thực hiện')),
                                DropdownMenuItem(value: 'in_progress', child: Text('Đang thực hiện')),
                                DropdownMenuItem(value: 'completed', child: Text('Đã hoàn thành')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _status = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.grey.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.play_arrow, color: Color(0xFF3659D9)),
                                title: const Text('Ngày bắt đầu'),
                                subtitle: Text(
                                  _startDate != null
                                      ? dateFormat.format(_startDate!)
                                      : 'Chưa thiết lập',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.calendar_month),
                                  onPressed: () => _pickDate(true),
                                ),
                                onTap: () => _pickDate(true),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.event, color: Colors.orange),
                                title: const Text('Hạn hoàn thành'),
                                subtitle: Text(
                                  _dueDate != null
                                      ? dateFormat.format(_dueDate!)
                                      : 'Chưa thiết lập',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () => _pickDate(false),
                                ),
                                onTap: () => _pickDate(false),
                              ),
                              if (_startDate != null || _dueDate != null) ...[
                                const Divider(height: 1),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.clear, size: 16),
                                    label: const Text('Xóa thiết lập ngày'),
                                    onPressed: () {
                                      setState(() {
                                        _startDate = null;
                                        _dueDate = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _loading ? null : _saveTask,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3659D9),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isEditing ? 'LƯU CẬP NHẬT' : 'TẠO CÔNG VIỆC',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
