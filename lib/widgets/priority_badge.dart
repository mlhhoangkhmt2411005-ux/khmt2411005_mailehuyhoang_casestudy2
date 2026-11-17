import 'package:flutter/material.dart';
import '../models/task.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (priority) {
      case 'high':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      case 'medium':
        backgroundColor = Colors.amber.shade50;
        textColor = Colors.amber.shade900;
        break;
      case 'low':
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Ưu tiên: ${Task.priorityLabel(priority)}',
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
