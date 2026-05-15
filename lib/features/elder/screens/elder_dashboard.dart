import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/task_service.dart';
import '../../../shared/models/task_model.dart';
import '../../auth/screens/role_selection_screen.dart';

class ElderDashboard extends StatefulWidget {
  const ElderDashboard({super.key});

  @override
  State<ElderDashboard> createState() => _ElderDashboardState();
}

class _ElderDashboardState extends State<ElderDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userData;
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await _authService.getUserData();
    if (mounted) {
      setState(() {
        _userData = data;
        _loadingUser = false;
      });
      // Add default tasks if first login
      if (data != null && data['firstLogin'] != false) {
        final uid = _authService.currentUser?.uid;
        if (uid != null) {
          await _taskService.addDefaultTasks(uid);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({'firstLogin': false});
        }
      }
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _greetingEmoji {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  String get _firstName {
    final name = _userData?['name'] as String? ?? 'Friend';
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(
            userData: _userData,
            loadingUser: _loadingUser,
            greeting: _greeting,
            greetingEmoji: _greetingEmoji,
            firstName: _firstName,
            taskService: _taskService,
            authService: _authService,
            onSosPressed: _handleSos,
          ),
          _PlaceholderTab(
              emoji: '📋', label: 'Tasks', sublabel: 'Coming soon!'),
          _PlaceholderTab(
              emoji: '💊', label: 'Medicine', sublabel: 'Coming soon!'),
          _PlaceholderTab(
              emoji: '💬', label: 'Sathi', sublabel: 'Your AI companion'),
          _ProfileTab(
            userData: _userData,
            authService: _authService,
            onLogout: _logout,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  void _handleSos() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SosDialog(
        onConfirm: () async {
          Navigator.pop(context);
          // SOS logic — Phase 6
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🆘 SOS Alert sent to your caretaker!',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontSize: 13),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ),
          );
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildBottomNav() {
    const items = [
      {'emoji': '🏠', 'label': 'Home'},
      {'emoji': '📋', 'label': 'Tasks'},
      {'emoji': '💊', 'label': 'Medicine'},
      {'emoji': '💬', 'label': 'Sathi'},
      {'emoji': '👤', 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
            top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isActive = _currentIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    items[i]['emoji']!,
                    style: TextStyle(
                        fontSize: isActive ? 22 : 20),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i]['label']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isActive ? 4 : 0,
                    height: isActive ? 4 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool loadingUser;
  final String greeting;
  final String greetingEmoji;
  final String firstName;
  final TaskService taskService;
  final AuthService authService;
  final VoidCallback onSosPressed;

  const _HomeTab({
    required this.userData,
    required this.loadingUser,
    required this.greeting,
    required this.greetingEmoji,
    required this.firstName,
    required this.taskService,
    required this.authService,
    required this.onSosPressed,
  });

  @override
  Widget build(BuildContext context) {
    final uid = authService.currentUser?.uid ?? '';

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),

          // ── Body ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: StreamBuilder<List<TaskModel>>(
              stream: taskService.getTodayTasks(uid),
              builder: (context, snap) {
                final tasks = snap.data ?? [];
                final wellness =
                    TaskService.calculateWellness(tasks);
                final todayTasks = tasks.take(3).toList();

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Wellness card
                    _WellnessCard(
                      wellness: wellness,
                      tasks: tasks,
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 20),

                    // Quick actions
                    _SectionHeader(
                        title: 'Quick Actions', link: ''),
                    const SizedBox(height: 10),
                    _QuickActionsGrid()
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 500.ms),

                    const SizedBox(height: 20),

                    // Tasks
                    _SectionHeader(
                      title: "Today's Tasks",
                      link: 'See all →',
                      onLinkTap: () {},
                    ),
                    const SizedBox(height: 10),

                    if (snap.connectionState ==
                        ConnectionState.waiting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else if (tasks.isEmpty)
                      _EmptyTasks()
                    else
                      ...todayTasks.map((task) =>
                          _TaskCard(
                            task: task,
                            onMarkDone: () =>
                                taskService.markDone(task.id),
                          ).animate(
                            delay: Duration(
                                milliseconds: 50 *
                                    todayTasks.indexOf(task)),
                          ).fadeIn(duration: 400.ms)),

                    const SizedBox(height: 20),

                    // Medicine reminder
                    _SectionHeader(
                        title: 'Medicine Reminder', link: ''),
                    const SizedBox(height: 10),
                    _MedicineReminderCard()
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 500.ms),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
            bottom: BorderSide(
                color: AppColors.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting $greetingEmoji',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 2),
                loadingUser
                    ? Container(
                        width: 160,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      )
                    : RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Namaste, ',
                              style: GoogleFonts.lora(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.walnut,
                              ),
                            ),
                            TextSpan(
                              text: '$firstName Ji 🙏',
                              style: GoogleFonts.lora(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('EEEE, d MMMM yyyy')
                      .format(DateTime.now()),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // SOS Button
          GestureDetector(
            onTap: onSosPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.sosPale,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.sosBorder, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🆘',
                      style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    'SOS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sos,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────
// WELLNESS CARD
// ─────────────────────────────────────────────
class _WellnessCard extends StatelessWidget {
  final int wellness;
  final List<TaskModel> tasks;

  const _WellnessCard({
    required this.wellness,
    required this.tasks,
  });

  String get _wellnessMessage {
    if (wellness >= 80) return 'Amazing! Keep it up! 🌟';
    if (wellness >= 60) return 'Great job today! 👍';
    if (wellness >= 40) return 'Good progress! 💪';
    if (wellness > 0) return "Let's do a bit more! 🌸";
    return 'Start your day well! ☀️';
  }

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => t.isCompleted).length;
    final total = tasks.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.walnutGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              children: [
                // Track
                SizedBox(
                  width: 62,
                  height: 62,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation(
                        Colors.transparent),
                  ),
                ),
                // Fill
                SizedBox(
                  width: 62,
                  height: 62,
                  child: CircularProgressIndicator(
                    value: wellness / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFE8A87C)),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Center text
                Center(
                  child: Text(
                    '$wellness%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF2C4A0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Wellness",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  total > 0
                      ? '$done of $total tasks completed'
                      : 'No tasks yet today',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 10),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: wellness / 100,
                    backgroundColor:
                        Colors.white.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFE8A87C)),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _wellnessMessage,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// QUICK ACTIONS GRID
// ─────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'emoji': '💊',
        'label': 'Medicine Scan',
        'sub': 'Verify your tablet',
        'bg': const Color(0xFFFFF8F0),
        'border': const Color(0xFFF0D5BC),
      },
      {
        'emoji': '💧',
        'label': 'Log Water',
        'sub': 'Track your intake',
        'bg': const Color(0xFFF0F7FF),
        'border': const Color(0xFFBFE0F5),
      },
      {
        'emoji': '🚶',
        'label': 'Start Walk',
        'sub': '20 min recommended',
        'bg': AppColors.surfaceGreen,
        'border': AppColors.borderGreen,
      },
      {
        'emoji': '💬',
        'label': 'Talk to Sathi',
        'sub': 'Your AI companion',
        'bg': const Color(0xFFF8F0FF),
        'border': const Color(0xFFE8D5F0),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) {
        final a = actions[i];
        return GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: a['bg'] as Color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: a['border'] as Color, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(a['emoji'] as String,
                    style: const TextStyle(fontSize: 26)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.walnut,
                      ),
                    ),
                    Text(
                      a['sub'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// TASK CARD
// ─────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onMarkDone;

  const _TaskCard({required this.task, required this.onMarkDone});

  Color get _borderColor {
    switch (task.status) {
      case TaskStatus.done:
        return AppColors.borderGreen;
      case TaskStatus.urgent:
        return const Color(0xFFF0D5BC);
      case TaskStatus.missed:
        return AppColors.errorBorder;
      default:
        return AppColors.border;
    }
  }

  Color get _bgColor {
    switch (task.status) {
      case TaskStatus.done:
        return const Color(0xFFF5FBF8);
      case TaskStatus.urgent:
        return const Color(0xFFFFFAF5);
      case TaskStatus.missed:
        return const Color(0xFFFFF5F5);
      default:
        return AppColors.surface;
    }
  }

  Color get _iconBg {
    switch (task.status) {
      case TaskStatus.done:
        return AppColors.sagePale;
      case TaskStatus.urgent:
        return AppColors.primaryPale;
      case TaskStatus.missed:
        return AppColors.errorPale;
      default:
        return AppColors.background;
    }
  }

  String get _chipLabel {
    switch (task.status) {
      case TaskStatus.done:
        return 'Done';
      case TaskStatus.urgent:
        return 'Urgent';
      case TaskStatus.missed:
        return 'Missed';
      default:
        return 'Pending';
    }
  }

  Color get _chipBg {
    switch (task.status) {
      case TaskStatus.done:
        return AppColors.sagePale;
      case TaskStatus.urgent:
        return AppColors.primaryPale;
      case TaskStatus.missed:
        return AppColors.errorPale;
      default:
        return AppColors.background;
    }
  }

  Color get _chipText {
    switch (task.status) {
      case TaskStatus.done:
        return AppColors.sage;
      case TaskStatus.urgent:
        return AppColors.primaryDeep;
      case TaskStatus.missed:
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: task.status != TaskStatus.done ? onMarkDone : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor, width: 1),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(task.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.walnut,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    task.isCompleted && task.completedAt != null
                        ? 'Completed · ${DateFormat('h:mm a').format(task.completedAt!)}'
                        : 'Due · ${DateFormat('h:mm a').format(task.dueTime)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            // Chip
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _chipBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _chipLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _chipText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MEDICINE REMINDER CARD
// ─────────────────────────────────────────────
class _MedicineReminderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFFF0D5BC), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('💊',
                  style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evening Tablet Due',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.walnut,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Metformin 500mg · 6:00 PM',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Scan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EMPTY TASKS
// ─────────────────────────────────────────────
class _EmptyTasks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Text('🌸',
                style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(
              'No tasks for today',
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.walnut,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your caretaker will add tasks for you',
              style: AppTextStyles.bodyMedium(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String link;
  final VoidCallback? onLinkTap;

  const _SectionHeader({
    required this.title,
    required this.link,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.walnut,
          ),
        ),
        if (link.isNotEmpty)
          GestureDetector(
            onTap: onLinkTap,
            child: Text(
              link,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PROFILE TAB
// ─────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final AuthService authService;
  final VoidCallback onLogout;

  const _ProfileTab({
    required this.userData,
    required this.authService,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final name = userData?['name'] ?? 'Elder User';
    final email = userData?['email'] ?? '';
    final phone = userData?['phone'] ?? '';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join()
        : 'E';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.walnutGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials.toUpperCase(),
                  style: GoogleFonts.lora(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Text(
              name,
              style: GoogleFonts.lora(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.walnut,
              ),
            ),

            const SizedBox(height: 4),

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '👴 Elder',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.primaryDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _InfoRow(
                      emoji: '📧',
                      label: 'Email',
                      value: email),
                  Divider(color: AppColors.border, height: 24),
                  _InfoRow(
                      emoji: '📱',
                      label: 'Phone',
                      value: phone),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout
            GestureDetector(
              onTap: onLogout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorPale,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.errorBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String emoji, label, value;
  const _InfoRow(
      {required this.emoji,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w300,
                )),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.walnut,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PLACEHOLDER TAB
// ─────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  final String emoji, label, sublabel;
  const _PlaceholderTab(
      {required this.emoji,
      required this.label,
      required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(label,
              style: GoogleFonts.lora(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.walnut,
              )),
          const SizedBox(height: 6),
          Text(sublabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textHint,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SOS DIALOG
// ─────────────────────────────────────────────
class _SosDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _SosDialog(
      {required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🆘',
                style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text(
              'Send SOS Alert?',
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.walnut,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will immediately alert your caretaker that you need help.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.border),
                      ),
                      child: Center(
                        child: Text('Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text('Send SOS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}