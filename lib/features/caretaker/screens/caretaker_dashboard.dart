import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/task_service.dart';
import '../../../services/report_service.dart';
import '../../../services/notification_service.dart';
import '../../../shared/models/task_model.dart';
import '../../auth/screens/role_selection_screen.dart';
import 'elder_detail_screen.dart';

class CaretakerDashboard extends StatefulWidget {
  const CaretakerDashboard({super.key});

  @override
  State<CaretakerDashboard> createState() => _CaretakerDashboardState();
}

class _CaretakerDashboardState extends State<CaretakerDashboard> {
  int _tab = 0;
  final _auth = AuthService();
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _elders = [];
  Stream<QuerySnapshot>? _sosStream;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _auth.getUserData();
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final linkedElders = List<String>.from(data?['linkedElders'] ?? []);
    final elders = <Map<String, dynamic>>[];

    for (final elderUid in linkedElders) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(elderUid)
          .get(const GetOptions(source: Source.server));

      if (doc.exists) {
        elders.add({'uid': elderUid, ...doc.data()!});
      }
    }

    Stream<QuerySnapshot>? sosStream;
    if (elders.isNotEmpty) {
      final uids = elders.map((e) => e['uid'] as String).toList();
      sosStream = FirebaseFirestore.instance
          .collection('sos_alerts')
          .where('elderUid', whereIn: uids)
          .where('resolved', isEqualTo: false)
          .snapshots();
    }

    if (mounted) {
      setState(() {
        _userData = data;
        _elders = elders;
        _sosStream = sosStream;
        _loading = false;
      });
    }

    await NotificationService.scheduleDailyReportReminder();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _firstName =>
      (_userData?['name'] as String? ?? 'Caretaker').split(' ').first;

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _tab,
        children: [
          _HomeTab(
            greeting: _greeting,
            firstName: _firstName,
            elders: _elders,
            sosStream: _sosStream,
            loading: _loading,
          ),
          _EldersTab(elders: _elders, loading: _loading),
          _ReportsTab(
            elders: _elders,
            caretakerUid: _auth.currentUser?.uid ?? '',
          ),
          _CaretakerProfileTab(userData: _userData, onLogout: _logout),
        ],
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    const items = [
      {'e': '🏠', 'l': 'Home'},
      {'e': '👥', 'l': 'Elders'},
      {'e': '📊', 'l': 'Reports'},
      {'e': '👤', 'l': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _tab == i;
          return GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  items[i]['e']!,
                  style: TextStyle(fontSize: active ? 22 : 20),
                ),
                const SizedBox(height: 3),
                Text(
                  items[i]['l']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? AppColors.sage : AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: 200.ms,
                  width: active ? 4 : 0,
                  height: active ? 4 : 0,
                  decoration: const BoxDecoration(
                    color: AppColors.sage,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final String greeting;
  final String firstName;
  final List<Map<String, dynamic>> elders;
  final Stream<QuerySnapshot>? sosStream;
  final bool loading;

  const _HomeTab({
    required this.greeting,
    required this.firstName,
    required this.elders,
    required this.sosStream,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SosSection(elders: elders, sosStream: sosStream),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Elders',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.walnut,
                      ),
                    ),
                    Text(
                      '${elders.length} linked',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (loading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.sage,
                      strokeWidth: 2,
                    ),
                  )
                else if (elders.isEmpty)
                  _NoElders()
                else
                  ...elders.map(
                    (e) => GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ElderDetailScreen(elder: e),
                        ),
                      ),
                      child: _ElderCard(elder: e),
                    )
                        .animate(
                          delay: Duration(
                            milliseconds: 50 * elders.indexOf(e),
                          ),
                        )
                        .fadeIn(duration: 400.ms),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting ☀️',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Namaste, ',
                          style: GoogleFonts.lora(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.walnut,
                          ),
                        ),
                        TextSpan(
                          text: '$firstName Ji 🙏',
                          style: GoogleFonts.lora(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.sage,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceGreen,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderGreen),
                ),
                child: const Center(
                  child: Text('🔔', style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _StatsRow(elders: elders),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _StatsRow extends StatelessWidget {
  final List<Map<String, dynamic>> elders;

  const _StatsRow({required this.elders});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(value: '${elders.length}', label: 'Elders'),
        const SizedBox(width: 8),
        _StatBox(value: '${elders.length * 4}', label: 'Tasks Today'),
        const SizedBox(width: 8),
        _StatBox(value: '75%', label: 'Avg Wellness'),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.walnut,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _SosSection extends StatelessWidget {
  final List<Map<String, dynamic>> elders;
  final Stream<QuerySnapshot>? sosStream;

  const _SosSection({
    required this.elders,
    required this.sosStream,
  });

  @override
  Widget build(BuildContext context) {
    if (elders.isEmpty || sosStream == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: sosStream,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final alerts = snap.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🆘 SOS Alerts',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            ...alerts.map((a) {
              final data = a.data() as Map<String, dynamic>;
              final elderName = elders.firstWhere(
                (e) => e['uid'] == data['elderUid'],
                orElse: () => {'name': 'Elder'},
              )['name'] as String;

              final time = data['createdAt'] != null
                  ? DateFormat('h:mm a').format(
                      (data['createdAt'] as Timestamp).toDate(),
                    )
                  : 'Just now';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.sosPale,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sosBorder, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Text('🆘', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$elderName needs help!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                          Text(
                            'Emergency · $time',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => FirebaseFirestore.instance
                          .collection('sos_alerts')
                          .doc(a.id)
                          .update({'resolved': true}),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Resolve',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ELDER CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ElderCard extends StatelessWidget {
  final Map<String, dynamic> elder;

  const _ElderCard({required this.elder});

  @override
  Widget build(BuildContext context) {
    final name = elder['name'] as String? ?? 'Elder';
    final phone = elder['phone'] as String? ?? '';
    final uid = elder['uid'] as String;
    final initials = name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return StreamBuilder<List<TaskModel>>(
      stream: TaskService().getTodayTasks(uid),
      builder: (context, snap) {
        final tasks = snap.data ?? [];
        final wellness = TaskService.calculateWellness(tasks);
        final done = tasks.where((t) => t.isCompleted).length;
        final urgent = tasks.where((t) => t.status == TaskStatus.urgent).length;
        final pending = tasks
            .where((t) => t.status == TaskStatus.pending && !t.isCompleted)
            .length;

        Color pillColor = AppColors.sagePale;
        Color pillText = AppColors.sage;

        if (wellness < 50) {
          pillColor = AppColors.errorPale;
          pillText = AppColors.error;
        } else if (wellness < 75) {
          pillColor = AppColors.primaryPale;
          pillText = AppColors.primaryDeep;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.walnutGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
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
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.walnut,
                          ),
                        ),
                        if (phone.isNotEmpty)
                          Text(
                            '📱 $phone',
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$wellness%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: pillText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: wellness / 100,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(
                    wellness >= 75
                        ? AppColors.sage
                        : wellness >= 50
                            ? AppColors.primary
                            : AppColors.error,
                  ),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Chip('✓ $done Done', AppColors.sagePale, AppColors.sage),
                  const SizedBox(width: 6),
                  if (urgent > 0) ...[
                    _Chip(
                      '! $urgent Urgent',
                      AppColors.primaryPale,
                      AppColors.primaryDeep,
                    ),
                    const SizedBox(width: 6),
                  ],
                  _Chip(
                    '~ $pending Pending',
                    AppColors.background,
                    AppColors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color text;

  const _Chip(this.label, this.bg, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: text,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ELDERS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _EldersTab extends StatelessWidget {
  final List<Map<String, dynamic>> elders;
  final bool loading;

  const _EldersTab({
    required this.elders,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              'All Elders',
              style: GoogleFonts.lora(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.walnut,
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.sage,
                      strokeWidth: 2,
                    ),
                  )
                : elders.isEmpty
                    ? _NoElders()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: elders.length,
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ElderDetailScreen(
                                elder: elders[i],
                              ),
                            ),
                          ),
                          child: _ElderCard(elder: elders[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REPORTS TAB  ← FIX 2: force server fetch, reload after generate/elder change
// ─────────────────────────────────────────────────────────────────────────────

class _ReportsTab extends StatefulWidget {
  final List<Map<String, dynamic>> elders;
  final String caretakerUid;

  const _ReportsTab({
    required this.elders,
    required this.caretakerUid,
  });

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  String? _selectedElderUid;
  bool _generating = false;
  final _reportService = ReportService();

  // ── Fix 2: replace StreamBuilder with manual server fetch ──
  List<QueryDocumentSnapshot> _reportDocs = [];
  bool _loadingReports = false;

  @override
  void initState() {
    super.initState();
    if (widget.elders.isNotEmpty) {
      _selectedElderUid = widget.elders.first['uid'];
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReports());
  }

  Future<void> _loadReports() async {
    if (_selectedElderUid == null) return;
    setState(() => _loadingReports = true);

    final snap = await FirebaseFirestore.instance
        .collection('reports')
        .where('elderUid', isEqualTo: _selectedElderUid)
        .get(const GetOptions(source: Source.server)); // force server

    final filtered = snap.docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return data['caretakerUid'] == widget.caretakerUid;
    }).toList();

    // Sort by date descending
    filtered.sort((a, b) {
      final aDate =
          ((a.data() as Map<String, dynamic>)['date'] as Timestamp?)?.toDate();
      final bDate =
          ((b.data() as Map<String, dynamic>)['date'] as Timestamp?)?.toDate();
      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate);
    });

    if (mounted) {
      setState(() {
        _reportDocs = filtered;
        _loadingReports = false;
      });
    }
  }

  Future<void> _generateForElder() async {
    if (_selectedElderUid == null) return;
    setState(() => _generating = true);

    final elder = widget.elders.firstWhere(
        (e) => e['uid'] == _selectedElderUid,
        orElse: () => {});

    await _reportService.generateDailyReport(
      elderUid: _selectedElderUid!,
      elderName: elder['name'] ?? 'Elder',
      caretakerUid: widget.caretakerUid,
    );

    setState(() => _generating = false);

    // Reload reports after generating
    await _loadReports();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📊 Report generated!',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppColors.sage,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reports',
                    style: GoogleFonts.lora(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.walnut,
                    )),
                const SizedBox(height: 14),

                // Elder selector chips
                if (widget.elders.length > 1)
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.elders.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final e = widget.elders[i];
                        final sel = _selectedElderUid == e['uid'];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedElderUid = e['uid']);
                            _loadReports(); // reload when elder changes
                          },
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.walnut
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? AppColors.walnut
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              e['name']?.toString().split(' ').first ?? 'Elder',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : AppColors.walnut,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 14),

                // Generate button
                GestureDetector(
                  onTap: _generating ? null : _generateForElder,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _generating ? null : AppColors.sageGradient,
                      color: _generating ? AppColors.border : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _generating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ))
                          : Text(
                              '📄 Generate Today\'s Report',
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
          ),

          // ── Reports list (Fix 2: FutureBuilder-style with _reportDocs) ──
          Expanded(
            child: _selectedElderUid == null
                ? Center(
                    child: Text('No elders linked',
                        style: AppTextStyles.bodyMedium()))
                : _loadingReports
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.sage, strokeWidth: 2))
                    : _reportDocs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('📊',
                                    style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 12),
                                Text('No reports yet',
                                    style: GoogleFonts.lora(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.walnut,
                                    )),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap "Generate Today\'s Report"\nto create one now',
                                  style: AppTextStyles.bodyMedium(),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: _reportDocs.length,
                            itemBuilder: (_, i) {
                              final doc = _reportDocs[i];
                              final data =
                                  doc.data() as Map<String, dynamic>;
                              final date =
                                  (data['date'] as Timestamp).toDate();
                              final isToday =
                                  DateFormat('ddMMyyyy').format(date) ==
                                      DateFormat('ddMMyyyy')
                                          .format(DateTime.now());

                              return Dismissible(
                                key: Key(doc.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorPale,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding:
                                      const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                    size: 24,
                                  ),
                                ),
                                onDismissed: (_) async {
                                  await FirebaseFirestore.instance
                                      .collection('reports')
                                      .doc(doc.id)
                                      .delete();
                                  await _loadReports();
                                },
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: AppColors.border),
                                  ),
                                  child: Column(children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: AppColors.border),
                                          ),
                                          child: const Center(
                                            child: Text('📊',
                                                style: TextStyle(
                                                    fontSize: 22)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(children: [
                                                Text(
                                                  DateFormat(
                                                          'EEEE, d MMM yyyy')
                                                      .format(date),
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: AppColors.walnut,
                                                  ),
                                                ),
                                                if (isToday) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          AppColors.sagePale,
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(6),
                                                    ),
                                                    child: Text('Today',
                                                        style: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontSize: 9,
                                                          color:
                                                              AppColors.sage,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        )),
                                                  ),
                                                ],
                                              ]),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${data['completedTasks']}/${data['totalTasks']} done · ${data['wellness']}% wellness'
                                                '${(data['sosCount'] ?? 0) > 0 ? ' · 🆘 ${data['sosCount']} SOS' : ''}',
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                  fontSize: 11,
                                                  color: AppColors.textHint,
                                                  fontWeight:
                                                      FontWeight.w300,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]),
                                    ),

                                    // Download PDF button
                                    GestureDetector(
                                      onTap: () => _reportService
                                          .generateAndSharePdf(data),
                                      child: Container(
                                        margin: const EdgeInsets.fromLTRB(
                                            14, 0, 14, 14),
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: AppColors.border),
                                        ),
                                        child: Center(
                                          child: Text('📥 Download PDF',
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.walnut,
                                              )),
                                        ),
                                      ),
                                    ),
                                  ]),
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

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE TAB
// ─────────────────────────────────────────────────────────────────────────────

class _CaretakerProfileTab extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onLogout;

  const _CaretakerProfileTab({
    required this.userData,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final name = userData?['name'] as String? ?? 'Caretaker';
    final email = userData?['email'] as String? ?? '';
    final phone = userData?['phone'] as String? ?? '';
    final initials = name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.sageGradient,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.sagePale,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '👩‍⚕️ Caretaker',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.sage,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                  _PRow('📧', 'Email', email),
                  Divider(color: AppColors.border, height: 24),
                  _PRow('📱', 'Phone', phone),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onLogout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorPale,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.errorBorder),
                ),
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
}

class _PRow extends StatelessWidget {
  final String e;
  final String l;
  final String v;

  const _PRow(this.e, this.l, this.v);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(e, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textHint,
                fontWeight: FontWeight.w300,
              ),
            ),
            Text(
              v,
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

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _NoElders extends StatelessWidget {
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
              'No elders linked yet',
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.walnut,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Elders will appear here\nonce they link to your account',
              style: AppTextStyles.bodyMedium(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}