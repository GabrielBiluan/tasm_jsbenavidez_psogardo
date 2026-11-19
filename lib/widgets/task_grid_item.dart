import 'dart:io';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/firebase_service.dart';

class TaskGridItem extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TaskGridItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isGroup = task.assignmentType == 'Group Task';

    return Card(
      elevation: task.isUrgent ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: task.isUrgent
            ? const BorderSide(color: Colors.redAccent, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(task.category).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(task.category),
                      ),
                    ),
                  ),
                  Checkbox(
                    value: task.isCompleted,
                    activeColor: Theme.of(context).colorScheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      if (val != null) {
                        FirebaseService().toggleTaskCompletion(task.id, val);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? Colors.grey : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  task.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (task.imageUrl != null && task.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: task.imageUrl!.startsWith('http')
                        ? Image.network(task.imageUrl!, fit: BoxFit.cover)
                        : Image.file(File(task.imageUrl!), fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isGroup ? Icons.groups : Icons.person,
                        size: 14,
                        color: isGroup ? Colors.indigo : Colors.teal,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.assignmentType,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isGroup ? Colors.indigo : Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  if (task.isUrgent)
                    const Icon(Icons.warning_amber, size: 16, color: Colors.red),
                ],
              ),
            ],
          ),
        ),
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
