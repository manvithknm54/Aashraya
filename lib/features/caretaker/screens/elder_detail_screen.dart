import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/task_service.dart';
import '../../../shared/models/task_model.dart';
import '../../../shared/widgets/aashraya_text_field.dart';

class ElderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> elder;
  const ElderDetailScreen({super.key, required this.elder});

  void _showAddTaskSheet(
      BuildContext context, String elderUid, String elderName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CaretakerAddTaskSheet(
        elderUid: elderUid,
        elderName: elderName,
      ),
    );
  }

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context, uid, name),
        backgroundColor: AppColors.walnut,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Task',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            )),
      ),
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

class _CaretakerAddTaskSheet extends StatefulWidget {
  final String elderUid;
  final String elderName;
  const _CaretakerAddTaskSheet({
    required this.elderUid,
    required this.elderName,
  });

  @override
  State<_CaretakerAddTaskSheet> createState() =>
      _CaretakerAddTaskSheetState();
}

class _CaretakerAddTaskSheetState
    extends State<_CaretakerAddTaskSheet> {
  final _titleCtrl = TextEditingController();
  String _category = 'Medicine';
  TimeOfDay _time = TimeOfDay.now();
  bool _saving = false;

  final _categories = [
    {'label': 'Medicine', 'emoji': '💊'},
    {'label': 'Walk', 'emoji': '🚶'},
    {'label': 'Water', 'emoji': '💧'},
    {'label': 'Exercise', 'emoji': '🏃'},
    {'label': 'Food', 'emoji': '🍽️'},
    {'label': 'Sleep', 'emoji': '😴'},
    {'label': 'Other', 'emoji': '📋'},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final reminderTime = DateTime(
      now.year, now.month, now.day,
      _time.hour, _time.minute,
    );

    final cat = _categories.firstWhere(
        (c) => c['label'] == _category);

    await FirebaseFirestore.instance
        .collection('tasks')
        .add({
      'userId': widget.elderUid,
      'title': _titleCtrl.text.trim(),
      'category': _category.toLowerCase(),
      'emoji': cat['emoji'],
      'dueTime': Timestamp.fromDate(reminderTime),
      'status': 'pending',
      'isCompleted': false,
      'completedAt': null,
      'notes': '',
      'addedBy': 'caretaker',
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '✅ Task added for ${widget.elderName}!',
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white),
        ),
        backgroundColor: AppColors.sage,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20, right: 20, top: 8,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF7F2),
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'Add task for ',
                style: GoogleFonts.lora(
                  fontSize: 20, fontWeight: FontWeight.w600,
                  color: AppColors.walnut,
                ),
              ),
              TextSpan(
                text: widget.elderName.split(' ').first,
                style: GoogleFonts.lora(
                  fontSize: 20, fontWeight: FontWeight.w600,
                  color: AppColors.sage,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // Title
          AashrayaTextField(
            label: 'Task Name',
            hint: 'e.g. Take morning medicine',
            controller: _titleCtrl,
            textInputAction: TextInputAction.done,
          ),

          const SizedBox(height: 14),

          // Category
          Text('Category',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.walnut,
              )),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final sel = _category == cat['label'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _category = cat['label']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.walnut
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel
                            ? AppColors.walnut
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '${cat['emoji']} ${cat['label']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: sel
                            ? Colors.white
                            : AppColors.walnut,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Time picker
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (picked != null) setState(() => _time = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.access_time_rounded,
                    color: AppColors.textHint, size: 20),
                const SizedBox(width: 10),
                Text('Reminder time: ${_time.format(context)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: AppColors.walnut,
                    )),
              ]),
            ),
          ),

          const SizedBox(height: 20),

          // Save
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.sageGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                    : Text('Add Task for Elder',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}