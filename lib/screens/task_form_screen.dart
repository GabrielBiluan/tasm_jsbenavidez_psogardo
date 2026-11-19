import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/task_model.dart';
import '../services/firebase_service.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskModel? taskToEdit;

  const TaskFormScreen({super.key, this.taskToEdit});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  final List<String> _categories = [
    'Work',
    'School',
    'Personal',
    'Assignment',
    'Project'
  ];

  late String _selectedCategory;
  late String _assignmentType; // Radio selection: "Individual" vs "Group Task"
  late bool _isCompleted; // Checkbox selection
  late bool _isUrgent; // Switch selection 1
  late bool _enableReminder; // Switch selection 2
  late DateTime _selectedDueDate;

  File? _pickedImageFile;
  String? _existingImageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');

    _selectedCategory = task?.category ?? 'Assignment';
    _assignmentType = task?.assignmentType ?? 'Individual';
    _isCompleted = task?.isCompleted ?? false;
    _isUrgent = task?.isUrgent ?? false;
    _enableReminder = true;
    _selectedDueDate = task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _existingImageUrl = task?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _pickedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final isEdit = widget.taskToEdit != null;
    final task = TaskModel(
      id: isEdit ? widget.taskToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      assignmentType: _assignmentType,
      isCompleted: _isCompleted,
      isUrgent: _isUrgent,
      dueDate: _selectedDueDate,
      imageUrl: _existingImageUrl,
      createdAt: isEdit ? widget.taskToEdit!.createdAt : DateTime.now(),
      userId: FirebaseService().userId,
    );

    try {
      if (isEdit) {
        await FirebaseService().updateTask(task, _pickedImageFile);
      } else {
        await FirebaseService().addTask(task, _pickedImageFile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? 'Task updated successfully!' : 'New task created successfully!',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.taskToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Task' : 'Add New Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g., Prepare Presentation for Mobile Dev',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Add notes or detailed instructions...',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // --- SELECTION CONTROL 1: DropdownButtonFormField ---
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              // --- SELECTION CONTROL 2: Radio & RadioListTile ---
              const Text(
                'Assignment Type (Radio)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Individual'),
                      value: 'Individual',
                      groupValue: _assignmentType,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _assignmentType = val;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Group Task'),
                      value: 'Group Task',
                      groupValue: _assignmentType,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _assignmentType = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // --- SELECTION CONTROL 3: Switch & SwitchListTile ---
              SwitchListTile(
                secondary: const Icon(Icons.warning_amber, color: Colors.red),
                title: const Text('Mark as Urgent'),
                subtitle: const Text('Highlight task in list & grid view'),
                value: _isUrgent,
                onChanged: (val) {
                  setState(() {
                    _isUrgent = val;
                  });
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active),
                title: const Text('Enable Due Date Reminder'),
                value: _enableReminder,
                onChanged: (val) {
                  setState(() {
                    _enableReminder = val;
                  });
                },
              ),
              const SizedBox(height: 8),
              // --- SELECTION CONTROL 4: Checkbox & CheckboxListTile ---
              CheckboxListTile(
                secondary: const Icon(Icons.check_circle_outline),
                title: const Text('Task Completed'),
                value: _isCompleted,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _isCompleted = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // --- DUE DATE PICKER ---
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month, color: Colors.indigo),
                  title: const Text('Due Date'),
                  subtitle: Text(
                    '${_selectedDueDate.year}-${_selectedDueDate.month.toString().padLeft(2, '0')}-${_selectedDueDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: TextButton(
                    onPressed: _selectDueDate,
                    child: const Text('Change'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // --- IMAGE UPLOAD (FIREBASE STORAGE) ---
              const Text(
                'Attachment Image (Firebase Storage)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (_pickedImageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_pickedImageFile!, height: 160, width: double.infinity, fit: BoxFit.cover),
                )
              else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _existingImageUrl!.startsWith('http')
                      ? Image.network(_existingImageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover)
                      : Image.file(File(_existingImageUrl!), height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // --- BUTTONS: ElevatedButton & OutlinedButton ---
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveForm,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEdit ? 'Update Task' : 'Save Task',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
