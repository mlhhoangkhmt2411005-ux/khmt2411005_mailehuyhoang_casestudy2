import 'user.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final User? createdBy;
  final List<User> assignees;
  final User? primaryAssignee;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String priority; // low, medium, high
  final String status; // todo, in_progress, completed
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.createdBy,
    required this.assignees,
    this.primaryAssignee,
    this.startDate,
    this.dueDate,
    required this.priority,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    var assigneesList = <User>[];
    if (json['assignees'] != null) {
      assigneesList = (json['assignees'] as List)
          .map((item) => item is Map<String, dynamic> ? User.fromJson(item) : User(id: item.toString(), fullName: '', email: ''))
          .toList();
    }

    User? creator;
    if (json['createdBy'] != null) {
      if (json['createdBy'] is Map<String, dynamic>) {
        creator = User.fromJson(json['createdBy']);
      } else {
        creator = User(id: json['createdBy'].toString(), fullName: '', email: '');
      }
    }

    User? primary;
    if (json['primaryAssignee'] != null) {
      if (json['primaryAssignee'] is Map<String, dynamic>) {
        primary = User.fromJson(json['primaryAssignee']);
      } else {
        primary = User(id: json['primaryAssignee'].toString(), fullName: '', email: '');
      }
    }

    return Task(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdBy: creator,
      assignees: assigneesList,
      primaryAssignee: primary,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'todo',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdBy': createdBy?.toJson(),
      'assignees': assignees.map((e) => e.toJson()).toList(),
      'primaryAssignee': primaryAssignee?.toJson(),
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
