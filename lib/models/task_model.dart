import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String assignmentType; // "Individual" vs "Group Task" (Radio selection)
  final bool isCompleted; // Checkbox selection
  final bool isUrgent; // Switch selection
  final DateTime dueDate;
  final String? imageUrl;
  final DateTime createdAt;
  final String userId;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.assignmentType,
    required this.isCompleted,
    required this.isUrgent,
    required this.dueDate,
    this.imageUrl,
    required this.createdAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'assignmentType': assignmentType,
      'isCompleted': isCompleted,
      'isUrgent': isUrgent,
      'dueDate': Timestamp.fromDate(dueDate),
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      if (date is int) return DateTime.fromMillisecondsSinceEpoch(date);
      return DateTime.now();
    }

    return TaskModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      assignmentType: map['assignmentType'] ?? 'Individual',
      isCompleted: map['isCompleted'] ?? false,
      isUrgent: map['isUrgent'] ?? false,
      dueDate: parseDate(map['dueDate']),
      imageUrl: map['imageUrl'],
      createdAt: parseDate(map['createdAt']),
      userId: map['userId'] ?? '',
    );
  }

  factory TaskModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TaskModel.fromMap(data, doc.id);
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? assignmentType,
    bool? isCompleted,
    bool? isUrgent,
    DateTime? dueDate,
    String? imageUrl,
    DateTime? createdAt,
    String? userId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      assignmentType: assignmentType ?? this.assignmentType,
      isCompleted: isCompleted ?? this.isCompleted,
      isUrgent: isUrgent ?? this.isUrgent,
      dueDate: dueDate ?? this.dueDate,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}
