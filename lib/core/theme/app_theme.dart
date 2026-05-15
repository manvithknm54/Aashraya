import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Warm Parchment Background System ──
  static const Color background      = Color(0xFFF5EFE6);
  static const Color surface         = Color(0xFFFBF7F2);
  static const Color surfaceWarm     = Color(0xFFFFF8F0);
  static const Color surfaceGreen    = Color(0xFFF0F7F4);
  static const Color border          = Color(0xFFEAD9C8);
  static const Color borderGreen     = Color(0xFFC2DDD4);

  // ── Brand — Warm Terracotta ──
  static const Color primary         = Color(0xFFD4845A);
  static const Color primaryLight    = Color(0xFFE8A87C);
  static const Color primaryPale     = Color(0xFFFDE8D0);
  static const Color primaryDeep     = Color(0xFFC4703A);

  // ── Deep Walnut — for headers, dark surfaces ──
  static const Color walnut          = Color(0xFF3D2B1F);
  static const Color walnutMid       = Color(0xFF6B4226);
  static const Color walnutLight     = Color(0xFF9E8472);

  // ── Caretaker — Sage Green ──
  static const Color sage            = Color(0xFF2E7D6A);
  static const Color sagePale        = Color(0xFFDFF0EA);
  static const Color sageLight       = Color(0xFFD6EDE6);

  // ── Text ──
  static const Color textPrimary     = Color(0xFF3D2B1F);
  static const Color textSecondary   = Color(0xFFB8987A);
  static const Color textHint        = Color(0xFFC4A882);
  static const Color textMuted       = Color(0xFF9E8472);

  // ── Status ──
  static const Color success         = Color(0xFF2E7D6A);
  static const Color successPale     = Color(0xFFDFF0EA);
  static const Color warning         = Color(0xFFE8A87C);
  static const Color warningPale     = Color(0xFFFDE8D0);
  static const Color error           = Color(0xFFDC2626);
  static const Color errorPale       = Color(0xFFFEF2F2);
  static const Color errorBorder     = Color(0xFFFECACA);

  // ── SOS ──
  static const Color sos             = Color(0xFFDC2626);
  static const Color sosPale         = Color(0xFFFEF2F2);
  static const Color sosBorder       = Color(0xFFFECACA);

  // ── Gradients ──
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF2C4A0), Color(0xFFE8A87C)],
  );

  static const LinearGradient walnutGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D2B1F), Color(0xFF6B4226)],
  );

  static const LinearGradient sageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D6A), Color(0xFF4CAF93)],
  );
}

class AppTextStyles {
  // Lora serif — for display/headings (warmth + trust)
  static TextStyle displayLarge() => GoogleFonts.lora(
    fontSize: 38, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: 0.5,
  );

  static TextStyle displayMedium() => GoogleFonts.lora(
    fontSize: 28, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle headingLarge() => GoogleFonts.lora(
    fontSize: 24, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.25,
  );

  static TextStyle headingMedium() => GoogleFonts.lora(
    fontSize: 20, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle headingItalic() => GoogleFonts.lora(
    fontSize: 28, fontWeight: FontWeight.w600,
    color: AppColors.primary, fontStyle: FontStyle.italic,
  );

  // Plus Jakarta Sans — for body/UI (clean, modern)
  static TextStyle bodyLarge() => GoogleFonts.plusJakartaSans(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.6,
  );

  static TextStyle bodyMedium() => GoogleFonts.plusJakartaSans(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.55,
  );

  static TextStyle bodySmall() => GoogleFonts.plusJakartaSans(
    fontSize: 11, fontWeight: FontWeight.w300,
    color: AppColors.textHint,
  );

  static TextStyle labelLarge() => GoogleFonts.plusJakartaSans(
    fontSize: 15, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary, letterSpacing: 0.2,
  );

  static TextStyle labelMedium() => GoogleFonts.plusJakartaSans(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle labelSmall() => GoogleFonts.plusJakartaSans(
    fontSize: 10, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 1.5,
  );

  static TextStyle caption() => GoogleFonts.plusJakartaSans(
    fontSize: 11, fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );

  static TextStyle buttonText() => GoogleFonts.plusJakartaSans(
    fontSize: 15, fontWeight: FontWeight.w500,
    color: Colors.white, letterSpacing: 0.3,
  );

  static TextStyle eyebrow() => GoogleFonts.plusJakartaSans(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textHint, letterSpacing: 2.0,
  );
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        background: AppColors.background,
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.sage,
        error: AppColors.error,
        onBackground: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onPrimary: Colors.white,
        outline: AppColors.border,
      ),

      textTheme: TextTheme(
        displayLarge:  AppTextStyles.displayLarge(),
        displayMedium: AppTextStyles.displayMedium(),
        headlineLarge: AppTextStyles.headingLarge(),
        headlineMedium:AppTextStyles.headingMedium(),
        titleLarge:    AppTextStyles.labelLarge(),
        titleMedium:   AppTextStyles.labelMedium(),
        bodyLarge:     AppTextStyles.bodyLarge(),
        bodyMedium:    AppTextStyles.bodyMedium(),
        bodySmall:     AppTextStyles.bodySmall(),
        labelLarge:    AppTextStyles.labelLarge(),
        labelSmall:    AppTextStyles.labelSmall(),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headingMedium(),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        surfaceTintColor: Colors.transparent,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.walnut,
          foregroundColor: AppColors.surface,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: AppTextStyles.buttonText(),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.labelLarge(),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18, vertical: 16,
        ),
        hintStyle: AppTextStyles.bodyMedium(),
        labelStyle: AppTextStyles.bodyMedium(),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        surfaceTintColor: Colors.transparent,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 10, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 10, fontWeight: FontWeight.w400,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        side: const BorderSide(color: AppColors.border, width: 1),
        labelStyle: AppTextStyles.caption(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}