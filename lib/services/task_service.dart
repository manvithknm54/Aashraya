import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/models/task_model.dart';
import '../core/constants/app_constants.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get today's tasks for a user
  Stream<List<TaskModel>> getTodayTasks(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _db
        .collection(AppConstants.colTasks)
        .where('userId', isEqualTo: userId)
        .where(
          'dueTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'dueTime',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
        )
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => TaskModel.fromFirestore(d))
              .toList()
            ..sort((a, b) => a.dueTime.compareTo(b.dueTime)),
        );
  }

  // Mark task as done
  Future<void> markDone(String taskId) async {
    await _db.collection(AppConstants.colTasks).doc(taskId).update({
      'status': TaskStatus.done.name,
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // Mark all pending tasks as missed at midnight
  Future<void> markMidnightReset(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final snap = await _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: false)
        .get();

    // Filter tasks from yesterday
    final yesterday = today.subtract(const Duration(days: 1));
    final oldTasks = snap.docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final due = (data['dueTime'] as Timestamp).toDate();
      return due.isBefore(today) &&
          due.isAfter(yesterday.subtract(const Duration(seconds: 1)));
    }).toList();

    final batch = _db.batch();
    for (final doc in oldTasks) {
      batch.update(doc.reference, {
        'status': 'missed',
        'isCompleted': false,
      });
    }
    if (oldTasks.isNotEmpty) await batch.commit();
  }

  // Add default tasks for new elder
  Future<void> addDefaultTasks(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final defaults = [
      {
        'userId': userId,
        'title': 'Morning Medicine',
        'category': 'medicine',
        'emoji': '💊',
        'dueTime': Timestamp.fromDate(today.add(const Duration(hours: 8))),
        'status': 'pending',
        'isCompleted': false,
        'completedAt': null,
        'notes': 'Take with water after breakfast',
      },
      {
        'userId': userId,
        'title': 'Morning Walk',
        'category': 'walk',
        'emoji': '🚶',
        'dueTime': Timestamp.fromDate(today.add(const Duration(hours: 7))),
        'status': 'pending',
        'isCompleted': false,
        'completedAt': null,
        'notes': '20 minutes recommended',
      },
      {
        'userId': userId,
        'title': 'Drink Water',
        'category': 'water',
        'emoji': '💧',
        'dueTime': Timestamp.fromDate(today.add(const Duration(hours: 10))),
        'status': 'pending',
        'isCompleted': false,
        'completedAt': null,
        'notes': 'Stay hydrated throughout the day',
      },
      {
        'userId': userId,
        'title': 'Evening Exercise',
        'category': 'exercise',
        'emoji': '🏃',
        'dueTime': Timestamp.fromDate(today.add(const Duration(hours: 17))),
        'status': 'pending',
        'isCompleted': false,
        'completedAt': null,
        'notes': 'Light stretching or yoga',
      },
    ];

    final batch = _db.batch();
    for (final task in defaults) {
      final ref = _db.collection(AppConstants.colTasks).doc();
      batch.set(ref, task);
    }
    await batch.commit();
  }

  // Calculate wellness score
  static int calculateWellness(List<TaskModel> tasks) {
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => t.isCompleted).length;
    return ((done / tasks.length) * 100).round();
  }
}