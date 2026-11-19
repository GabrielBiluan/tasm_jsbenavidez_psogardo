import 'dart:io';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/firebase_service.dart';

class TaskQuickViewSheet extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onEdit;
  final VoidCallback onViewDetails;

  const TaskQuickViewSheet({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onViewDetails,
  });

  static void show(
    BuildContext context, {
    required TaskModel task,
    required VoidCallback onEdit,
    required VoidCallback onViewDetails,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => TaskQuickViewSheet(
        task: task,
        onEdit: onEdit,
        onViewDetails: onViewDetails,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (task.isUrgent)
                Chip(
                  avatar: const Icon(Icons.warning, size: 14, color: Colors.white),
                  label: const Text('URGENT', style: TextStyle(color: Colors.white, fontSize: 11)),
                  backgroundColor: Colors.redAccent,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.description.isEmpty ? 'No description provided.' : task.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[800],
                ),
          ),
          const SizedBox(height: 16),
          if (task.imageUrl != null && task.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: task.imageUrl!.startsWith('http')
                      ? Image.network(task.imageUrl!, fit: BoxFit.cover)
                      : Image.file(File(task.imageUrl!), fit: BoxFit.cover),
                ),
              ),
            ),
          Row(
            children: [
              Chip(
                label: Text('Category: ${task.category}'),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('Type: ${task.assignmentType}'),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(
                    task.isCompleted ? Icons.undo : Icons.check_circle,
                  ),
                  label: Text(
                    task.isCompleted ? 'Mark Pending' : 'Mark Completed',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    FirebaseService().toggleTaskCompletion(task.id, !task.isCompleted);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          task.isCompleted ? 'Task marked pending' : 'Task completed!',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
                onPressed: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                onViewDetails();
              },
              child: const Text('View Full Task Details →'),
            ),
          ),
        ],
      ),
    );
  }
}
