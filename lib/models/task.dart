import 'user.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final User? createdBy;
  final List<User> assignees;
  final String? primaryAssigneeId;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String priority; // 'low', 'medium', 'high'
  final String status;   // 'todo', 'in_progress', 'completed'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.createdBy,
    this.assignees = const [],
    this.primaryAssigneeId,
    this.startDate,
    this.dueDate,
    required this.priority,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    User? creator;
    if (json['createdBy'] != null) {
      if (json['createdBy'] is Map) {
        creator = User.fromJson(Map<String, dynamic>.from(json['createdBy']));
      } else {
        creator = User(id: json['createdBy'].toString(), fullName: '', email: '');
      }
    }

    List<User> assigneeList = [];
    if (json['assigneeIds'] != null && json['assigneeIds'] is List) {
      for (var item in json['assigneeIds']) {
        if (item is Map) {
          assigneeList.add(User.fromJson(Map<String, dynamic>.from(item)));
        } else if (item != null) {
          assigneeList.add(User(id: item.toString(), fullName: '', email: ''));
        }
      }
    }

    return Task(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdBy: creator,
      assignees: assigneeList,
      primaryAssigneeId: json['primaryAssigneeId']?.toString(),
      startDate: json['startDate'] == null ? null : DateTime.tryParse(json['startDate'].toString()),
      dueDate: json['dueDate'] == null ? null : DateTime.tryParse(json['dueDate'].toString()),
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'todo',
      createdAt: json['createdAt'] == null ? null : DateTime.tryParse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null ? null : DateTime.tryParse(json['updatedAt'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'todo':
        return 'Chưa thực hiện';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Đã hoàn thành';
      default:
        return status;
    }
  }

  static String priorityLabel(String priority) {
    switch (priority) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      default:
        return priority;
    }
  }
}
