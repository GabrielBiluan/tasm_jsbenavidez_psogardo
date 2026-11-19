import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isFirebaseAvailable = false;
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  // Fallback in-memory storage for offline / non-initialized state
  final List<TaskModel> _mockTasks = [];
  final StreamController<List<TaskModel>> _mockStreamController =
      StreamController<List<TaskModel>>.broadcast();

  String? _fallbackUserEmail;

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isFirebaseAvailable = true;
      } else {
        await Firebase.initializeApp();
        _isFirebaseAvailable = true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase init error (using fallback mode if needed): $e');
      }
      _isFirebaseAvailable = false;
      _seedMockData();
    }
  }

  void _seedMockData() {
    if (_mockTasks.isEmpty) {
      _mockTasks.addAll([
        TaskModel(
          id: 'demo-task-1',
          title: 'Complete Mobile App Assignment',
          description: 'Implement Flutter components: Firebase Auth, Firestore CRUD, Form validation, List/Grid views.',
          category: 'Assignment',
          assignmentType: 'Individual',
          isCompleted: false,
          isUrgent: true,
          dueDate: DateTime.now().add(const Duration(days: 2)),
          createdAt: DateTime.now(),
          userId: 'demo-user',
        ),
        TaskModel(
          id: 'demo-task-2',
          title: 'Group Design Review Meeting',
          description: 'Discuss UI layout, custom styles, drawer, and bottom navigation bar components.',
          category: 'School',
          assignmentType: 'Group Task',
          isCompleted: true,
          isUrgent: false,
          dueDate: DateTime.now().add(const Duration(days: 4)),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          userId: 'demo-user',
        ),
      ]);
      _mockStreamController.add(List.from(_mockTasks));
    }
  }

  // --- AUTHENTICATION METHODS ---

  User? get currentUser {
    if (_isFirebaseAvailable) {
      return FirebaseAuth.instance.currentUser;
    }
    return null;
  }

  String get userEmail {
    if (_isFirebaseAvailable && FirebaseAuth.instance.currentUser != null) {
      return FirebaseAuth.instance.currentUser!.email ?? 'User';
    }
    return _fallbackUserEmail ?? 'demo@taskmanager.com';
  }

  String get userId {
    if (_isFirebaseAvailable && FirebaseAuth.instance.currentUser != null) {
      return FirebaseAuth.instance.currentUser!.uid;
    }
    return 'demo-user';
  }

  Stream<User?> get authStateChanges {
    if (_isFirebaseAvailable) {
      return FirebaseAuth.instance.authStateChanges();
    }
    return Stream.value(null);
  }

  Future<void> register(String email, String password) async {
    if (_isFirebaseAvailable) {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } else {
      _fallbackUserEmail = email;
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> signIn(String email, String password) async {
    if (_isFirebaseAvailable) {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } else {
      _fallbackUserEmail = email;
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> signOut() async {
    if (_isFirebaseAvailable) {
      await FirebaseAuth.instance.signOut();
    } else {
      _fallbackUserEmail = null;
    }
  }

  // --- FIRESTORE CRUD & STREAM BUILDER METHODS ---

  Stream<List<TaskModel>> getTasksStream() {
    if (_isFirebaseAvailable) {
      final uid = userId;
      return FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: uid)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs.map((doc) => TaskModel.fromSnapshot(doc)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    } else {
      // Return stream of mock data
      Future.microtask(() => _mockStreamController.add(List.from(_mockTasks)));
      return _mockStreamController.stream;
    }
  }

  Future<void> addTask(TaskModel task, File? imageFile) async {
    String? imageUrl = task.imageUrl;

    if (imageFile != null && _isFirebaseAvailable) {
      imageUrl = await _uploadImageToStorage(imageFile);
    } else if (imageFile != null && !_isFirebaseAvailable) {
      imageUrl = imageFile.path;
    }

    final newTask = task.copyWith(
      userId: userId,
      imageUrl: imageUrl,
    );

    if (_isFirebaseAvailable) {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(newTask.id)
          .set(newTask.toMap());
    } else {
      _mockTasks.insert(0, newTask);
      _mockStreamController.add(List.from(_mockTasks));
    }
  }

  Future<void> updateTask(TaskModel task, File? newImageFile) async {
    String? imageUrl = task.imageUrl;

    if (newImageFile != null && _isFirebaseAvailable) {
      imageUrl = await _uploadImageToStorage(newImageFile);
    } else if (newImageFile != null && !_isFirebaseAvailable) {
      imageUrl = newImageFile.path;
    }

    final updatedTask = task.copyWith(imageUrl: imageUrl);

    if (_isFirebaseAvailable) {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(updatedTask.id)
          .update(updatedTask.toMap());
    } else {
      final index = _mockTasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        _mockTasks[index] = updatedTask;
        _mockStreamController.add(List.from(_mockTasks));
      }
    }
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    if (_isFirebaseAvailable) {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({'isCompleted': isCompleted});
    } else {
      final index = _mockTasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _mockTasks[index] = _mockTasks[index].copyWith(isCompleted: isCompleted);
        _mockStreamController.add(List.from(_mockTasks));
      }
    }
  }

  Future<void> deleteTask(String taskId, String? imageUrl) async {
    if (_isFirebaseAvailable) {
      if (imageUrl != null && imageUrl.startsWith('http')) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(imageUrl);
          await ref.delete();
        } catch (_) {}
      }
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
    } else {
      _mockTasks.removeWhere((t) => t.id == taskId);
      _mockStreamController.add(List.from(_mockTasks));
    }
  }

  // --- FIREBASE STORAGE METHOD ---

  Future<String> _uploadImageToStorage(File imageFile) async {
    final fileName = 'task_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance
        .ref()
        .child('task_images')
        .child(userId)
        .child(fileName);

    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
