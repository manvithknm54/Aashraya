import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _role;

  void _proceed() {
    if (_role == null) return;
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => LoginScreen(role: _role!),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    'WELCOME',
                    style: AppTextStyles.eyebrow(),
                  )
                  .animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 8),

                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Who are\nyou, ',
                          style: GoogleFonts.lora(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: AppColors.walnut,
                            height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: 'dear?',
                          style: GoogleFonts.lora(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 500.ms)
                  .slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 10),

                  Text(
                    "We'll shape Aashraya just for you.",
                    style: AppTextStyles.bodyMedium(),
                  )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 500.ms),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Role Cards + CTA ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [

                    // Elder card
                    _RoleCard(
                      role: AppConstants.roleElder,
                      title: 'I am an Elder',
                      subtitle:
                          'Tasks, gentle reminders & a\ncompanion always with you',
                      emoji: '👴',
                      pill: '🌸  Made with love for you',
                      cardBg: AppColors.surfaceWarm,
                      cardBorder: const Color(0xFFF0D5BC),
                      emojiBg: AppColors.primaryPale,
                      pillBg: AppColors.primaryPale,
                      pillText: AppColors.primaryDeep,
                      selectedAccent: AppColors.primary,
                      isSelected: _role == AppConstants.roleElder,
                      onTap: () =>
                          setState(() => _role = AppConstants.roleElder),
                    )
                    .animate(delay: 350.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: 14),

                    // Caretaker card
                    _RoleCard(
                      role: AppConstants.roleCaretaker,
                      title: 'I am a Caretaker',
                      subtitle:
                          'Monitor, get alerts & read\ndaily health reports',
                      emoji: '👩‍⚕️',
                      pill: '🌿  Stay close from afar',
                      cardBg: AppColors.surfaceGreen,
                      cardBorder: AppColors.borderGreen,
                      emojiBg: AppColors.sagePale,
                      pillBg: AppColors.sageLight,
                      pillText: AppColors.sage,
                      selectedAccent: AppColors.sage,
                      isSelected: _role == AppConstants.roleCaretaker,
                      onTap: () =>
                          setState(() => _role = AppConstants.roleCaretaker),
                    )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

                    const Spacer(),

                    // ── Continue Button ──
                    GestureDetector(
                      onTap: _proceed,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _role != null
                              ? AppColors.walnut
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: _role != null
                                    ? AppColors.surface
                                    : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 10),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(
                                  _role != null ? 0.15 : 0.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '→',
                                  style: TextStyle(
                                    color: _role != null
                                        ? AppColors.surface
                                        : Colors.transparent,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate(delay: 650.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 36),
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

// ─────────────────────────────────────────────
// Role Card Widget — emoji box FIXED (no AnimatedContainer)
// ─────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final String role, title, subtitle, emoji, pill;
  final Color cardBg, cardBorder, emojiBg;
  final Color pillBg, pillText, selectedAccent;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.pill,
    required this.cardBg,
    required this.cardBorder,
    required this.emojiBg,
    required this.pillBg,
    required this.pillText,
    required this.selectedAccent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? selectedAccent.withOpacity(0.7)
                : cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedAccent.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ✅ FIXED — plain Container, zero color animation
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: emojiBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? selectedAccent
                              : AppColors.walnut,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textMuted,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ Check mark — only shows when selected
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selectedAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),

              ],
            ),

            const SizedBox(height: 14),

            // Pill tag
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                pill,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: pillText,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}