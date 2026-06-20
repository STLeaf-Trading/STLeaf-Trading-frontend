import 'package:flutter/material.dart';

class AppColors {
  // Primary Greens
  static const Color primary = Color(0xFF1B6B35);
  static const Color primaryLight = Color(0xFF2E8B4A);
  static const Color accent = Color(0xFF4CAF50);
  static const Color accentHover = Color(0xFF388E3C);
  static const Color primaryDark = Color(0xFF0D4A22);

  // Backgrounds
  static const Color mint = Color(0xFFE8F5E9);
  static const Color mintDark = Color(0xFFC8E6C9);
  static const Color surface = Color(0xFFF9FDF9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A2E1A);
  static const Color textSecondary = Color(0xFF4A6741);
  static const Color textMuted = Color(0xFF8FAE8B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Sidebar
  static const Color sidebarBg = Color(0xFF0D4A22);
  static const Color sidebarActive = Color(0xFF1B6B35);
  static const Color sidebarHover = Color(0xFF1A5C2E);
  static const Color sidebarText = Color(0xFFB8DEC4);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFF8F00);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color danger = Color(0xFFE53935);
  static const Color dangerLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF0288D1);
  static const Color infoLight = Color(0xFFE1F5FE);
  static const Color pending = Color(0xFFFF9800);
  static const Color pendingLight = Color(0xFFFFF3E0);

  // Borders
  static const Color border = Color(0xFFDCEDDC);
  static const Color borderDark = Color(0xFFB2CCAD);
  static const Color divider = Color(0xFFEEF7EE);

  // Chart Colors
  static const Color chart1 = Color(0xFF1B6B35);
  static const Color chart2 = Color(0xFF4CAF50);
  static const Color chart3 = Color(0xFF81C784);
  static const Color chart4 = Color(0xFFA5D6A7);
  static const Color chart5 = Color(0xFFC8E6C9);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1B6B35), Color(0xFF2E8B4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0D4A22), Color(0xFF1B6B35), Color(0xFF2E8B4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1B6B35), Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
