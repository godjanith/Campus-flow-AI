import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Official Royal & Light Color Palette ──────────────────────────────
  static const Color primaryRoyalNavy = Color(0xFF0F294A);
  static const Color primary = Color(0xFF0F294A);
  static const Color primaryDark = Color(0xFF0A1C33);
  static const Color primaryLight = Color(0xFF1B3D6B);

  static const Color secondaryRoyalGold = Color(0xFFC59B27);
  static const Color goldAccent = Color(0xFFC59B27);
  static const Color accent = Color(0xFFC59B27); // Backward compatibility
  static const Color goldLight = Color(0xFFFBF4E4);

  static const Color crispIvory = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFFF8FAFC); // Harmonized for daytime readability
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFF1F5F9);

  static const Color purePorcelain = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color cardBorderLight = Color(0xFFCBD5E1);

  // Typography Colors
  static const Color textPrimary = Color(0xFF1E293B); // Deep Slate
  static const Color textSecondary = Color(0xFF64748B); // Muted Steel
  static const Color textMuted = Color(0xFF94A3B8);

  // Status & Severity Colors (Soft pastel fills with rich royal/semantic text)
  static const Color criticalBg = Color(0xFFFEF2F2);
  static const Color criticalBorder = Color(0xFFFECACA);
  static const Color criticalText = Color(0xFF991B1B);
  static const Color critical = Color(0xFF991B1B);

  static const Color highBg = Color(0xFFFFFBEB);
  static const Color highText = Color(0xFF92400E);
  static const Color high = Color(0xFF92400E);

  static const Color mediumBg = Color(0xFFEFF6FF);
  static const Color mediumText = Color(0xFF1E40AF);
  static const Color medium = Color(0xFF1E40AF);

  static const Color lowBg = Color(0xFFECFDF5);
  static const Color lowText = Color(0xFF065F46);
  static const Color low = Color(0xFF065F46);
  static const Color resolved = Color(0xFF065F46);

  // ── Royal Institutional Gradients ────────────────────────────────────
  static const LinearGradient royalGradient = LinearGradient(
    colors: [Color(0xFF0F294A), Color(0xFF1B3D6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFC59B27), Color(0xFFE2BC52)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = royalGradient;
  static const LinearGradient accentGradient = goldGradient;

  // ── Semantic Helpers ──────────────────────────────────────────────────
  static Color severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return criticalText;
      case 'HIGH':
        return highText;
      case 'MEDIUM':
        return mediumText;
      case 'LOW':
        return lowText;
      default:
        return mediumText;
    }
  }

  static Color severityBgColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return criticalBg;
      case 'HIGH':
        return highBg;
      case 'MEDIUM':
        return mediumBg;
      case 'LOW':
        return lowBg;
      default:
        return mediumBg;
    }
  }

  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return highText;
      case 'IN_PROGRESS':
        return mediumText;
      case 'RESOLVED':
        return lowText;
      default:
        return textSecondary;
    }
  }

  static Color statusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return highBg;
      case 'IN_PROGRESS':
        return mediumBg;
      case 'RESOLVED':
        return lowBg;
      default:
        return surfaceLight;
    }
  }

  // ── Box Decoration Helpers ───────────────────────────────────────────
  static BoxDecoration cardDecoration({
    Color? color,
    double radius = 12,
    Color? borderColor,
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: color ?? purePorcelain,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? cardBorder, width: 1),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: primaryRoyalNavy.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ]
          : [
              BoxShadow(
                color: primaryRoyalNavy.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
    );
  }

  // ── Global ThemeData (Refined Light Mode) ────────────────────────────
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: primaryRoyalNavy,
      scaffoldBackgroundColor: crispIvory,
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.merriweather(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.merriweather(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.merriweather(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        titleMedium: GoogleFonts.inter(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 14,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 13,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryRoyalNavy,
        foregroundColor: purePorcelain,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.merriweather(
          color: purePorcelain,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: purePorcelain,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: purePorcelain,
        selectedItemColor: primaryRoyalNavy,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: purePorcelain,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryRoyalNavy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: critical, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: critical, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRoyalNavy,
          foregroundColor: purePorcelain,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryRoyalNavy,
          side: const BorderSide(color: primaryRoyalNavy, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Backward compatibility getter
  static ThemeData get darkTheme => lightTheme;
}
