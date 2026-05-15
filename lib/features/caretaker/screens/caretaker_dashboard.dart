import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../auth/screens/role_selection_screen.dart';

class CaretakerDashboard extends StatelessWidget {
  const CaretakerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👩‍⚕️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Caretaker Dashboard',
                style: GoogleFonts.lora(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.walnut,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Firebase Auth ✅ Working!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () async {
                  await AuthService().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const RoleSelectionScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.errorPale,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.errorBorder),
                  ),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
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