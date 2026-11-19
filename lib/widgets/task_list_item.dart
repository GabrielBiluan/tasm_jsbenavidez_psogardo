import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/firebase_service.dart';

class TaskListItem extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isGroup = task.assignmentType == 'Group Task';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: task.isUrgent ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: task.isUrgent
            ? const BorderSide(color: Colors.redAccent, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Checkbox(
              value: task.isCompleted,
              activeColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (val) {
                if (val != null) {
                  FirebaseService().toggleTaskCompletion(task.id, val);
                }
              },
            ),
            if (task.imageUrl != null && task.imageUrl!.isNotEmpty)
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.image, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildBadge(
                  label: task.category,
                  color: _getCategoryColor(task.category),
                  icon: Icons.category,
                ),
                _buildBadge(
                  label: task.assignmentType,
                  color: isGroup ? Colors.indigo : Colors.teal,
                  icon: isGroup ? Icons.groups : Icons.person,
                ),
                if (task.isUrgent)
                  _buildBadge(
                    label: 'URGENT',
                    color: Colors.red,
                    icon: Icons.warning_amber,
                  ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: task.dueDate.isBefore(DateTime.now()) && !task.isCompleted
                  ? Colors.red
                  : Colors.grey[600],
            ),
            const SizedBox(height: 2),
            Text(
              '${task.dueDate.month}/${task.dueDate.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: task.dueDate.isBefore(DateTime.now()) && !task.isCompleted
                    ? Colors.red
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'work':
        return Colors.blue;
      case 'school':
        return Colors.orange;
      case 'assignment':
        return Colors.purple;
      case 'personal':
        return Colors.green;
      case 'project':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
