import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _goNext();
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(milliseconds: 3600));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 800),
      pageBuilder: (_, __, ___) => const RoleSelectionScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [

          // ── Petal 1 — top right warm circle ──
          Positioned(
            top: -size.height * 0.08,
            right: -size.width * 0.15,
            child: AnimatedBuilder(
              animation: _breathe,
              builder: (_, __) => Container(
                width: size.width * 0.55,
                height: size.width * 0.55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight.withOpacity(
                    0.16 + _breathe.value * 0.06,
                  ),
                ),
              ),
            ),
          ),

          // ── Petal 2 — bottom left accent ──
          Positioned(
            bottom: -size.height * 0.06,
            left: -size.width * 0.1,
            child: Container(
              width: size.width * 0.40,
              height: size.width * 0.40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.10),
              ),
            ),
          ),

          // ── Petal 3 — mid-left small ──
          Positioned(
            top: size.height * 0.18,
            left: size.width * 0.04,
            child: Container(
              width: size.width * 0.22,
              height: size.width * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryPale.withOpacity(0.55),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // Logo box
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.border, width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.15),
                          blurRadius: 28,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🏠', style: TextStyle(fontSize: 40)),
                    ),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.0, 1.0),
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms),

                  const SizedBox(height: 28),

                  // App name — Lora serif
                  Text(
                    'Aashraya',
                    style: GoogleFonts.lora(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: AppColors.walnut,
                      letterSpacing: 1.0,
                    ),
                  )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                  // Hindi script
                  Text(
                    'आश्रय',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 3,
                    ),
                  )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 500.ms),

                  const SizedBox(height: 16),

                  // Warm divider line
                  Container(
                    width: 40,
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: AppColors.warmGradient,
                    ),
                  )
                  .animate(delay: 600.ms)
                  .scaleX(begin: 0, end: 1, curve: Curves.easeOut)
                  .fadeIn(duration: 400.ms),

                  const SizedBox(height: 14),

                  // Tagline
                  Text(
                    'A place that cares for you',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.3,
                    ),
                  )
                  .animate(delay: 750.ms)
                  .fadeIn(duration: 600.ms),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}