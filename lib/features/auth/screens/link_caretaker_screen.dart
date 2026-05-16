import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../shared/widgets/aashraya_text_field.dart';
import '../../elder/screens/elder_dashboard.dart';

class LinkCaretakerScreen extends StatefulWidget {
  final bool isFromProfile; // true = from profile "Change Caretaker"
  const LinkCaretakerScreen({super.key, this.isFromProfile = false});

  @override
  State<LinkCaretakerScreen> createState() => _LinkCaretakerScreenState();
}

class _LinkCaretakerScreenState extends State<LinkCaretakerScreen> {
  final _emailCtrl = TextEditingController();
  final AuthService _auth = AuthService();

  bool _searching = false;
  bool _linking = false;
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selected;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_onType);
  }

  @override
  void dispose() {
    _emailCtrl.removeListener(_onType);
    _emailCtrl.dispose();
    super.dispose();
  }

  void _onType() {
    if (_emailCtrl.text.trim().length >= 3) {
      _search();
    } else {
      setState(() {
        _results = [];
        _selected = null;
        _searchError = null;
      });
    }
  }

  Future<void> _search() async {
    setState(() {
      _searching = true;
      _searchError = null;
      _selected = null;
    });

    final results = await _auth.searchCaretakers(_emailCtrl.text);

    if (mounted) {
      setState(() {
        _searching = false;
        _results = results;
        if (results.isEmpty && _emailCtrl.text.trim().length >= 3) {
          _searchError =
              'No caretakers found. Ask your caretaker to register first.';
        }
      });
    }
  }

  Future<void> _link(Map<String, dynamic> caretaker) async {
    setState(() => _linking = true);

    final elderUid = _auth.currentUser?.uid;
    if (elderUid == null) {
      setState(() => _linking = false);
      return;
    }

    if (widget.isFromProfile) {
      final userData = await _auth.getUserData();
      final oldUid = userData?['linkedTo'] as String?;
      if (oldUid != null && oldUid.isNotEmpty) {
        await _auth.unlinkCaretaker(
          elderUid: elderUid,
          caretakerUid: oldUid,
        );
      }
    }

    final error = await _auth.linkToCaretaker(
      elderUid: elderUid,
      caretakerUid: caretaker['uid'],
    );

    setState(() => _linking = false);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error,
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      if (widget.isFromProfile) {
        Navigator.pop(context);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ElderDashboard()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isFromProfile)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: AppColors.walnut,
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms),

              if (widget.isFromProfile) const SizedBox(height: 24),

              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '🤝',
                      style: TextStyle(fontSize: 40),
                    ),
                  ),
                ).animate().scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
              ),

              const SizedBox(height: 24),

              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: widget.isFromProfile
                            ? 'Change your\n'
                            : 'Connect with your\n',
                        style: GoogleFonts.lora(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: AppColors.walnut,
                          height: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: 'Caretaker 🌸',
                        style: GoogleFonts.lora(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  'Search by name, email or phone number',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              AashrayaTextField(
                label: 'Search Caretaker',
                hint: 'Name, email or phone...',
                controller: _emailCtrl,
                keyboardType: TextInputType.text,
                prefixIcon: _searching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.search_rounded,
                        color: AppColors.textHint,
                        size: 20,
                      ),
              ),

              const SizedBox(height: 12),

              if (_searchError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorPale,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.errorBorder),
                  ),
                  child: Text(
                    _searchError!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms),

              ..._results.map(
                (c) => _ResultCard(
                  caretaker: c,
                  isLinking: _linking,
                  onLink: () => _link(c),
                ).animate().fadeIn(duration: 400.ms).slideY(
                      begin: 0.1,
                      end: 0,
                    ),
              ),

              if (!widget.isFromProfile) ...[
                const SizedBox(height: 32),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const ElderDashboard()),
                      (route) => false,
                    ),
                    child: Text(
                      'Skip for now →',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textHint,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> caretaker;
  final bool isLinking;
  final VoidCallback onLink;

  const _ResultCard({
    required this.caretaker,
    required this.isLinking,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    final name = caretaker['name'] ?? 'Caretaker';
    final email = caretaker['email'] ?? '';
    final phone = caretaker['phone'] ?? '';
    final initials = name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderGreen,
          width: 1.5,
        ),
      ),
      child: Row(
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.walnut,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isLinking ? null : onLink,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isLinking
                    ? AppColors.sage.withOpacity(0.5)
                    : AppColors.sage,
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLinking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Link',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
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
