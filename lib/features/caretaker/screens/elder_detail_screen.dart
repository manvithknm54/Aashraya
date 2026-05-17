import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/task_service.dart';
import '../../../shared/models/task_model.dart';

class ElderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> elder;
  const ElderDetailScreen({super.key, required this.elder});

  @override
  Widget build(BuildContext context) {
    final name = elder['name'] as String? ?? 'Elder';
    final phone = elder['phone'] as String? ?? '';
    final email = elder['email'] as String? ?? '';
    final uid = elder['uid'] as String;
    final initials = name.trim().split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                    bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16, color: AppColors.walnut),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.walnutGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text(initials,
                          style: GoogleFonts.lora(
                            fontSize: 16, fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: GoogleFonts.lora(
                                fontSize: 18, fontWeight: FontWeight.w600,
                                color: AppColors.walnut,
                              )),
                          if (phone.isNotEmpty)
                            Text('📱 $phone',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: AppColors.textHint,
                                  fontWeight: FontWeight.w300,
                                )),
                        ],
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            // Task list
            Expanded(
              child: StreamBuilder<List<TaskModel>>(
                stream: TaskService().getTodayTasks(uid),
                builder: (context, snap) {
                  if (snap.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.sage, strokeWidth: 2),
                    );
                  }

                  final tasks = snap.data ?? [];
                  final done = tasks.where((t) => t.isCompleted).toList();
                  final pending = tasks.where((t) => !t.isCompleted).toList();
                  final wellness = TaskService.calculateWellness(tasks);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // Wellness summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.walnutGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          SizedBox(
                            width: 56, height: 56,
                            child: Stack(children: [
                              SizedBox(
                                width: 56, height: 56,
                                child: CircularProgressIndicator(
                                  value: wellness / 100,
                                  strokeWidth: 5,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.15),
                                  valueColor:
                                      const AlwaysStoppedAnimation(
                                          Color(0xFFE8A87C)),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Center(
                                child: Text('$wellness%',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF2C4A0),
                                    )),
                              ),
                            ]),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Today's Wellness",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14, fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  )),
                              Text('${done.length} done · ${pending.length} pending',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6),
                                  )),
                            ],
                          ),
                        ]),
                      ),

                      const SizedBox(height: 20),

                      // Completed tasks
                      if (done.isNotEmpty) ...[
                        _SectionHead(
                            '✅ Completed (${done.length})'),
                        const SizedBox(height: 8),
                        ...done.map((t) => _DetailTaskCard(task: t)),
                        const SizedBox(height: 16),
                      ],

                      // Pending tasks
                      if (pending.isNotEmpty) ...[
                        _SectionHead(
                            '⏳ Pending (${pending.length})'),
                        const SizedBox(height: 8),
                        ...pending.map((t) => _DetailTaskCard(task: t)),
                      ],

                      if (tasks.isEmpty)
                        Center(
                          child: Column(children: [
                            const SizedBox(height: 40),
                            const Text('🌸',
                                style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 12),
                            Text('No tasks today',
                                style: GoogleFonts.lora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.walnut,
                                )),
                          ]),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  final String title;
  const _SectionHead(this.title);
  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: AppColors.walnut,
        ));
  }
}

class _DetailTaskCard extends StatelessWidget {
  final TaskModel task;
  const _DetailTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: task.isCompleted
            ? const Color(0xFFF5FBF8)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isCompleted
              ? AppColors.borderGreen
              : AppColors.border,
        ),
      ),
      child: Row(children: [
        Text(task.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: AppColors.walnut,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  )),
              Text(
                task.isCompleted && task.completedAt != null
                    ? 'Done at ${DateFormat('h:mm a').format(task.completedAt!)}'
                    : 'Due at ${DateFormat('h:mm a').format(task.dueTime)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: AppColors.textHint,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: task.isCompleted
                ? AppColors.sagePale
                : AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            task.isCompleted ? '✓ Done' : '⏳',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: task.isCompleted
                  ? AppColors.sage
                  : AppColors.textMuted,
            ),
          ),
        ),
      ]),
    );
  }
}