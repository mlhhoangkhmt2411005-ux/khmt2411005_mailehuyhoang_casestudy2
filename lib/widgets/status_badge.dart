import 'package:flutter/material.dart';
import '../models/task.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData iconData;

    switch (status) {
      case 'completed':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        iconData = Icons.check_circle_outline;
        break;
      case 'in_progress':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        iconData = Icons.sync;
        break;
      case 'todo':
      default:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        iconData = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            Task.statusLabel(status),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
