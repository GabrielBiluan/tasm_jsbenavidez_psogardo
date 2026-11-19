import 'dart:io';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/firebase_service.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              try {
                await FirebaseService().deleteTask(task.id, task.imageUrl);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task deleted successfully')),
                  );
                  Navigator.pop(context); // Return to list screen
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete task: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Task',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => TaskFormScreen(taskToEdit: task),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            tooltip: 'Delete Task',
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.imageUrl != null && task.imageUrl!.isNotEmpty)
              SizedBox(
                height: 240,
                width: double.infinity,
                child: task.imageUrl!.startsWith('http')
                    ? Image.network(task.imageUrl!, fit: BoxFit.cover)
                    : Image.file(File(task.imageUrl!), fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.category, size: 14),
                        label: Text(task.category),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      Chip(
                        avatar: Icon(
                          task.assignmentType == 'Group Task' ? Icons.groups : Icons.person,
                          size: 14,
                        ),
                        label: Text(task.assignmentType),
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                      if (task.isUrgent)
                        const Chip(
                          avatar: Icon(Icons.warning, size: 14, color: Colors.white),
                          label: Text('URGENT', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.red,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            task.isCompleted ? Icons.check_circle : Icons.pending_actions,
                            color: task.isCompleted ? Colors.green : Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              Text(
                                task.isCompleted ? 'Completed' : 'Pending',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: task.isCompleted ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_month, color: Colors.blue),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              Text(
                                '${task.dueDate.year}-${task.dueDate.month.toString().padLeft(2, '0')}-${task.dueDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description.isEmpty
                        ? 'No additional description provided.'
                        : task.description,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(task.isCompleted ? Icons.undo : Icons.check),
                          label: Text(task.isCompleted ? 'Mark Pending' : 'Mark Completed'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            FirebaseService().toggleTaskCompletion(task.id, !task.isCompleted);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  task.isCompleted
                                      ? 'Task marked pending'
                                      : 'Task completed!',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _showDeleteConfirmation(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
