import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/task_service.dart';
import '../../../shared/models/task_model.dart';
import '../../../shared/widgets/aashraya_text_field.dart';
import '../../auth/screens/role_selection_screen.dart';
import '../../auth/screens/link_caretaker_screen.dart';

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
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));

    if (mounted) {
      setState(() {
        _userData = doc.data();
        _loadingUser = false;
      });

      if (_userData != null && _userData!['firstLogin'] != false) {
        await _taskService.addDefaultTasks(uid);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'firstLogin': false});
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

  void _switchToTasksTab() {
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(
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
                onSeeAllTasks: _switchToTasksTab,
              ),
              _TasksTab(
                uid: _authService.currentUser?.uid ?? '',
                taskService: _taskService,
              ),
              _ProfileTab(
                userData: _userData,
                authService: _authService,
                onLogout: _logout,
              ),
            ],
          ),
          Positioned(
            bottom: 23,
            right: 16,
            child: _SathiFloatingButton(userName: _firstName),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Future<void> _handleSos() async {
    HapticFeedback.heavyImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🆘', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 14),
              Text(
                'Send Emergency Alert?',
                style: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.walnut,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your caretaker will be immediately notified.',
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
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Send SOS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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

    if (confirmed != true || !mounted) return;

    HapticFeedback.heavyImpact();

    final uid = _authService.currentUser?.uid;
    final userData = await _authService.getUserData();
    final caretakerUid = userData?['linkedTo'] as String?;

    if (uid != null) {
      await FirebaseFirestore.instance.collection('sos_alerts').add({
        'elderUid': uid,
        'elderName': userData?['name'] ?? 'Elder',
        'caretakerUid': caretakerUid,
        'resolved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🆘 Alert sent to your caretaker!',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildBottomNav() {
    const items = [
      {'emoji': '🏠', 'label': 'Home'},
      {'emoji': '📋', 'label': 'Tasks'},
      {'emoji': '👤', 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = _currentIndex == i;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _currentIndex = i),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        items[i]['emoji']!,
                        style: TextStyle(fontSize: active ? 26 : 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
                          color:
                              active ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool loadingUser;
  final String greeting;
  final String greetingEmoji;
  final String firstName;
  final TaskService taskService;
  final AuthService authService;
  final VoidCallback onSosPressed;
  final VoidCallback onSeeAllTasks;

  const _HomeTab({
    required this.userData,
    required this.loadingUser,
    required this.greeting,
    required this.greetingEmoji,
    required this.firstName,
    required this.taskService,
    required this.authService,
    required this.onSosPressed,
    required this.onSeeAllTasks,
  });

  @override
  Widget build(BuildContext context) {
    final uid = authService.currentUser?.uid ?? '';

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: StreamBuilder<List<TaskModel>>(
              stream: taskService.getTodayTasks(uid),
              builder: (context, snap) {
                final tasks = snap.data ?? [];
                final wellness = TaskService.calculateWellness(tasks);
                final todayTasks = tasks.take(3).toList();

                return SliverList(
                  delegate: SliverChildListDelegate([
                    _WellnessCard(wellness: wellness, tasks: tasks)
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 20),
                    _SectionHeader(title: 'Quick Actions', link: ''),
                    const SizedBox(height: 10),
                    _QuickActionsGrid()
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 500.ms),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: "Today's Tasks",
                      link: 'See all →',
                      onLinkTap: onSeeAllTasks,
                    ),
                    const SizedBox(height: 10),
                    if (snap.connectionState == ConnectionState.waiting)
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
                      ...todayTasks.map(
                        (task) => _TaskCard(
                          task: task,
                          onMarkDone: () => taskService.markDone(task.id),
                        )
                            .animate(
                              delay: Duration(
                                milliseconds: 50 * todayTasks.indexOf(task),
                              ),
                            )
                            .fadeIn(duration: 400.ms),
                      ),
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
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
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
          GestureDetector(
            onTap: onSosPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.sosPale,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sosBorder, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🆘', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    'SOS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.sos,
                      letterSpacing: 0.8,
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

class _WellnessCard extends StatelessWidget {
  final int wellness;
  final List<TaskModel> tasks;

  const _WellnessCard({required this.wellness, required this.tasks});

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
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              children: [
                SizedBox(
                  width: 62,
                  height: 62,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation(Colors.transparent),
                  ),
                ),
                SizedBox(
                  width: 62,
                  height: 62,
                  child: CircularProgressIndicator(
                    value: wellness / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFE8A87C)),
                    strokeCap: StrokeCap.round,
                  ),
                ),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: wellness / 100,
                    backgroundColor: Colors.white.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFE8A87C)),
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
          onTap: i == 3
              ? () {
                  final dashboardState =
                      context.findAncestorStateOfType<_ElderDashboardState>();
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => _SathiVoiceSheet(
                      userName: dashboardState?._firstName ?? 'Friend',
                      getResponse: _SathiFloatingButtonState.getStaticResponse,
                    ),
                  );
                }
              : () {},
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: a['bg'] as Color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: a['border'] as Color, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(a['emoji'] as String, style: const TextStyle(fontSize: 26)),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(task.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            const Text('🌸', style: TextStyle(fontSize: 36)),
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

class _ProfileTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final AuthService authService;
  final VoidCallback onLogout;

  const _ProfileTab({
    required this.userData,
    required this.authService,
    required this.onLogout,
  });

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  Map<String, dynamic>? _caretakerData;
  bool _loadingCaretaker = true;

  @override
  void initState() {
    super.initState();
    _loadCaretaker();
  }

  Future<void> _loadCaretaker() async {
    setState(() => _loadingCaretaker = true);

    final uid = widget.authService.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingCaretaker = false);
      return;
    }

    final elderDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));

    final linkedTo = elderDoc.data()?['linkedTo'] as String?;

    if (linkedTo != null && linkedTo.isNotEmpty) {
      final caretakerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(linkedTo)
          .get(const GetOptions(source: Source.server));

      if (mounted) {
        setState(() {
          _caretakerData = caretakerDoc.data();
          _loadingCaretaker = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _caretakerData = null;
          _loadingCaretaker = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userData?['name'] ?? 'Elder User';
    final email = widget.userData?['email'] ?? '';
    final phone = widget.userData?['phone'] ?? '';
    final initials = name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    final isLinked = _caretakerData != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.walnutGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
            const SizedBox(height: 24),
            _card(
              child: Column(
                children: [
                  _infoRow('📧', 'Email', email),
                  Divider(color: AppColors.border, height: 24),
                  _infoRow('📱', 'Phone', phone),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _loadingCaretaker
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : isLinked
                    ? _caretakerCard(context)
                    : _linkButton(context),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: widget.onLogout,
              child: _card(
                color: AppColors.errorPale,
                border: AppColors.errorBorder,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 18,
                    ),
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

  Widget _caretakerCard(BuildContext context) {
    final cName = _caretakerData?['name'] ?? 'Caretaker';
    final cEmail = _caretakerData?['email'] ?? '';
    final cPhone = _caretakerData?['phone'] ?? '';
    final cInitials = cName
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return _card(
      color: AppColors.surfaceGreen,
      border: AppColors.borderGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.sagePale,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🤝  Your Caretaker',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.sage,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.sageGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    cInitials,
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.walnut,
                      ),
                    ),
                    if (cEmail.isNotEmpty)
                      Text(
                        cEmail,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    if (cPhone.isNotEmpty)
                      Text(
                        cPhone,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LinkCaretakerScreen(isFromProfile: true),
                ),
              );
              setState(() => _loadingCaretaker = true);
              await _loadCaretaker();
            },
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.sageLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGreen),
              ),
              child: Center(
                child: Text(
                  'Change Caretaker',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sage,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const LinkCaretakerScreen(isFromProfile: true),
          ),
        );
        setState(() => _loadingCaretaker = true);
        await _loadCaretaker();
      },
      child: _card(
        color: const Color(0xFFFFF8F0),
        border: const Color(0xFFF0D5BC),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤝', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'Link a Caretaker',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child, Color? color, Color? border}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border ?? AppColors.border),
      ),
      child: child,
    );
  }

  Widget _infoRow(String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textHint,
                fontWeight: FontWeight.w300,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.walnut,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TasksTab extends StatefulWidget {
  final String uid;
  final TaskService taskService;

  const _TasksTab({
    required this.uid,
    required this.taskService,
  });

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  bool _showAddTask = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Tasks',
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.walnut,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showAddTask = !_showAddTask),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _showAddTask
                          ? AppColors.primaryPale
                          : AppColors.walnut,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _showAddTask ? 'Cancel' : '+ Add Task',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _showAddTask
                            ? AppColors.primaryDeep
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showAddTask)
            _AddTaskForm(
              uid: widget.uid,
              taskService: widget.taskService,
              onDone: () => setState(() => _showAddTask = false),
            ),
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: widget.taskService.getTodayTasks(widget.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  );
                }

                final tasks = snap.data ?? [];

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📋', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'No tasks today',
                          style: GoogleFonts.lora(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.walnut,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + Add Task to get started',
                          style: AppTextStyles.bodyMedium(),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) => _FullTaskCard(
                    task: tasks[i],
                    taskService: widget.taskService,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTaskForm extends StatefulWidget {
  final String uid;
  final TaskService taskService;
  final VoidCallback onDone;

  const _AddTaskForm({
    required this.uid,
    required this.taskService,
    required this.onDone,
  });

  @override
  State<_AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<_AddTaskForm> {
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
    final due = DateTime(
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );

    final cat = _categories.firstWhere((c) => c['label'] == _category);

    await FirebaseFirestore.instance.collection('tasks').add({
      'userId': widget.uid,
      'title': _titleCtrl.text.trim(),
      'category': _category.toLowerCase(),
      'emoji': cat['emoji'],
      'dueTime': Timestamp.fromDate(due),
      'status': 'pending',
      'isCompleted': false,
      'completedAt': null,
      'notes': '',
    });

    setState(() => _saving = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AashrayaTextField(
            label: 'Task Name',
            hint: 'e.g. Take morning medicine',
            controller: _titleCtrl,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 14),
          Text(
            'Category',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.walnut,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isSelected = _category == cat['label'];

                return GestureDetector(
                  onTap: () => setState(() => _category = cat['label']!),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.walnut : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.walnut : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '${cat['emoji']} ${cat['label']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.walnut,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (picked != null) setState(() => _time = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Due time: ${_time.format(context)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.walnut,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.walnut,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Task',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullTaskCard extends StatelessWidget {
  final TaskModel task;
  final TaskService taskService;

  const _FullTaskCard({
    required this.task,
    required this.taskService,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.errorPale,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.error,
          size: 24,
        ),
      ),
      onDismissed: (_) =>
          FirebaseFirestore.instance.collection('tasks').doc(task.id).delete(),
      child: GestureDetector(
        onTap: task.isCompleted ? null : () => taskService.markDone(task.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                task.isCompleted ? const Color(0xFFF5FBF8) : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  task.isCompleted ? AppColors.borderGreen : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: 200.ms,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: task.isCompleted ? AppColors.sage : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        task.isCompleted ? AppColors.sage : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: task.isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(task.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
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
                        decoration:
                            task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.isCompleted && task.completedAt != null
                          ? 'Done · ${DateFormat('h:mm a').format(task.completedAt!)}'
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: task.isCompleted
                      ? AppColors.sagePale
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.isCompleted ? 'Done' : 'Pending',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color:
                        task.isCompleted ? AppColors.sage : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SathiFloatingButton extends StatefulWidget {
  final String userName;

  const _SathiFloatingButton({required this.userName});

  @override
  State<_SathiFloatingButton> createState() => _SathiFloatingButtonState();
}

class _SathiFloatingButtonState extends State<_SathiFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  static const Map<String, String> _responses = {
    'hello': 'Namaste! How are you feeling today?',
    'hi': 'Hello dear! How can I help you?',
    'lonely': 'You are never alone. I am always here with you.',
    'sad': 'I am sorry you feel sad. Would you like to talk about it?',
    'pain': 'Please inform your caretaker about the pain. Press SOS if urgent.',
    'medicine': 'Have you taken your medicines today? Check your task list.',
    'walk': 'A walk is great for health! Have you gone for your walk today?',
    'water': 'Please drink some water. Staying hydrated is very important!',
    'help': 'I am here to help you. You can ask me anything.',
    'task': 'Check your tasks in the Tasks section. How many have you completed?',
    'good': 'Wonderful! I am so happy to hear that!',
    'happy': 'Your happiness makes my day! Keep smiling!',
    'tired': 'Please rest. Your health comes first.',
    'sleep': 'Good sleep is very important. Rest well tonight.',
    'thank': 'You are so welcome! It is my joy to help you.',
    'bye': 'Take care! Remember your medicines and water. Goodbye!',
  };

  static const List<String> _defaultResponses = [
    'I hear you. Tell me more.',
    'I am here for you always.',
    'Thank you for talking to me.',
    'How can I help you today?',
    'You are not alone. I am with you.',
  ];

  static String getStaticResponse(String input) {
    final lower = input.toLowerCase();
    for (final key in _responses.keys) {
      if (lower.contains(key)) return _responses[key]!;
    }
    return _defaultResponses[
        DateTime.now().millisecond % _defaultResponses.length];
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onSathiTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SathiVoiceSheet(
        userName: widget.userName,
        getResponse: getStaticResponse,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onSathiTap,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, child) => Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.walnut,
            boxShadow: [
              BoxShadow(
                color: AppColors.walnut.withOpacity(
                  0.3 + _pulseCtrl.value * 0.2,
                ),
                blurRadius: 16 + _pulseCtrl.value * 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
        child: const Center(
          child: Text('🤗', style: TextStyle(fontSize: 32)),
        ),
      ),
    ).animate().scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }
}

class _SathiVoiceSheet extends StatefulWidget {
  final String userName;
  final String Function(String) getResponse;

  const _SathiVoiceSheet({
    required this.userName,
    required this.getResponse,
  });

  @override
  State<_SathiVoiceSheet> createState() => _SathiVoiceSheetState();
}

class _SathiVoiceSheetState extends State<_SathiVoiceSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveCtrl;
  late stt.SpeechToText _speech;
  late FlutterTts _tts;

  bool _isListening = false;
  bool _isResponding = false;
  bool _speechAvailable = false;
  String _statusText = 'Tap the mic and speak to Sathi';
  String _heardText = '';
  String _responseText = '';

  final List<String> _quickPrompts = [
    'I feel lonely',
    'I took my medicine',
    'I need help',
    'Good morning',
    'I feel happy',
    'I am tired',
  ];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _speech = stt.SpeechToText();
    _tts = FlutterTts();

    _initSpeech();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.1);
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) => setState(() {
        _isListening = false;
        _statusText = 'Could not hear. Try again.';
      }),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleListen() async {
    await _tts.stop();

    if (!_speechAvailable) {
      setState(() => _statusText = 'Microphone not available on this device.');
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() {
      _isListening = true;
      _statusText = 'Listening... speak now 🎙️';
      _heardText = '';
      _responseText = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _heardText = result.recognizedWords;
          _statusText = 'You said: "$_heardText"';
        });

        if (result.finalResult && _heardText.isNotEmpty) {
          _respond(_heardText);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_IN',
      cancelOnError: true,
    );
  }

  Future<void> _respond(String input) async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _isResponding = true;
      _responseText = '';
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final response = widget.getResponse(input);

    setState(() {
      _isResponding = false;
      _responseText = response;
      _statusText = 'Sathi says:';
    });

    await _tts.speak(response);
  }

  Future<void> _handlePrompt(String prompt) async {
    setState(() {
      _heardText = prompt;
      _statusText = 'You said: "$prompt"';
      _responseText = '';
    });
    await _respond(prompt);
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBF7F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.walnutGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤗', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sathi',
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.walnut,
            ),
          ),
          Text(
            'Your voice companion 💛',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textHint,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(minHeight: 70),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isListening ? AppColors.primary : AppColors.border,
                width: _isListening ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color:
                        _isListening ? AppColors.primary : AppColors.textHint,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (_isResponding)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                if (_responseText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _responseText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: AppColors.walnut,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _toggleListen,
            child: AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, child) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? AppColors.error : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening
                              ? AppColors.error
                              : AppColors.primary)
                          .withOpacity(0.3 + _waveCtrl.value * 0.25),
                      blurRadius:
                          _isListening ? 30 + _waveCtrl.value * 15 : 20,
                      spreadRadius: _isListening ? 4 : 2,
                    ),
                  ],
                ),
                child: child,
              ),
              child: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isListening ? 'Tap to stop' : 'Tap mic to speak',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: _isListening ? AppColors.error : AppColors.textHint,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickPrompts
                  .map(
                    (p) => GestureDetector(
                      onTap: () => _handlePrompt(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          p,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.walnut,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
