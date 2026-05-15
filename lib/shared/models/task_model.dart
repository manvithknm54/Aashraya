import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { pending, done, urgent, missed }
enum TaskCategory { medicine, exercise, water, walk, food, sleep, other }

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String emoji;
  final DateTime dueTime;
  final TaskStatus status;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? notes;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.emoji,
    required this.dueTime,
    required this.status,
    required this.isCompleted,
    this.completedAt,
    this.notes,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? 'other',
      emoji: data['emoji'] ?? '📋',
      dueTime: (data['dueTime'] as Timestamp).toDate(),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => TaskStatus.pending,
      ),
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'emoji': emoji,
      'dueTime': Timestamp.fromDate(dueTime),
      'status': status.name,
      'isCompleted': isCompleted,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'notes': notes,
    };
  }

  TaskModel copyWith({
    TaskStatus? status,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id,
      userId: userId,
      title: title,
      category: category,
      emoji: emoji,
      dueTime: dueTime,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      notes: notes,
    );
  }
}