import 'package:flutter/material.dart';

class AppColors {

  
  // ===== PRIMARY BRAND COLORS =====

  /// Vanguard Clinical Cyan (Primary Brand) - CLIENT SPEC
  /// Hex: #00B8A4
  static const Color primary = Color(0xFF008B94);

  /// Bio-Glass Accent (Interactive highlights) - CLIENT SPEC
  /// Hex: #20C6DA
  static const Color accent = Color(0xFF20C6DA);

  /// Cyan Tonal 100 (Material 3) - CLIENT SPEC
  /// Light cyan for selected chips, card backgrounds
  static const Color primaryLight = Color(0xFFB2EBF2);

  /// Cyan Tonal 900 (Material 3) - CLIENT SPEC
  /// Dark cyan for text on light cyan backgrounds (WCAG AAA contrast)
  static const Color primaryDark = Color(0xFF004D47);

  // ===== SURFACE & BACKGROUND (LIGHT MODE) =====

  /// Sterile Surface – Day Mode - CLIENT SPEC
  /// Hex: #F5F9FA
  static const Color background = Color(0xFFF5F9FA);



  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDark(context) ? backgroundDark : background;

  static Color cardColor(BuildContext context) =>
      isDark(context) ? cardDark : card;

  static Color text(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimary;

  static Color textSecondaryColor(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondary;

  static Color borderColor(BuildContext context) =>
      isDark(context)
          ? primary.withOpacity(0.5)
          : const Color(0xFF7F92A0);
   static Color borderColor1(BuildContext context) =>
      isDark(context)
          ? primary.withOpacity(0.5)
          : const Color(0xFF8A9A9A);        


  /// Card / Elevated Surface - CLIENT SPEC
  /// Pure white with elevation (tonal shifts for depth)
  static const Color card = Color(0xFFFFFFFF);

  // ===== SURFACE & BACKGROUND (DARK MODE) =====

  /// Dark Mode Base Surface - CLIENT SPEC
  /// Hex: #121F21 (NOT pure black - reduces OLED smearing)
  static const Color backgroundDark = Color(0xFF121F21);

  /// Dark Mode Card Surface
  static const Color cardDark = Color(0xFF1E2E30);

  /// Dark Mode Desaturated Cyan (prevents vibration) - CLIENT SPEC
  /// Hex: #4DD0E1 (Shifted from #00B8A4 for dark mode comfort)
  static const Color primaryDarkMode = Color(0xFF4DD0E1);

  // ===== TEXT COLORS (LIGHT MODE) =====

  /// Primary text (Dark Grey – NOT pure black) - CLIENT SPEC
  /// Hex: #263238 (Pairs with San Francisco Pro Heavy weight)
  static const Color textPrimary = Color(0xFF263238);

  /// Secondary text (Subtitles, labels)
  static const Color textSecondary = Color(0xFF546E7A);

  /// Muted / Disabled text
  static const Color textTertiary = Color(0xFF90A4AE);

  // ===== TEXT COLORS (DARK MODE) =====

  /// Dark Mode Primary Text
  static const Color textPrimaryDark = Color(0xFFF5F5F5);

  /// Dark Mode Secondary Text
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  /// Dark Mode Tertiary Text
  static const Color textTertiaryDark = Color(0xFF707070);

  /// Dark Mode Accent (Adjusted)
static const Color accentDarkMode = Color(0xFF26D5E3);


  // ===== TEXT ON COLORED SURFACES =====

  /// Text on primary buttons (Light mode)
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Text on primary buttons (Dark mode) - CLIENT SPEC
  /// Ensures WCAG AAA contrast on desaturated primary
  static const Color textOnPrimaryDark = Color(0xFF121F21);

  /// Text on accent (Light)
  static const Color textOnAccent = Color(0xFF263238);

  /// Text on accent (Dark mode)
  static const Color textOnAccentDark = Color(0xFF121F21);

  // ===== SEMANTIC STATUS COLORS =====

  /// Success (Teal-Green) - CLIENT SPEC
  /// Hex: #00A98F (Harmonized with brand cyan, distinct and medical-grade)
  static const Color success = Color(0xFF00A98F);

  /// Critical/Error - CLIENT SPEC
  /// Hex: #E57373 (Softened red for clinical contexts, not harsh #D32F2F)
  static const Color error = Color(0xFFE57373);

  /// Error background (Softened red)
  static const Color errorBackground = Color(0xFFE57373);

  /// Warning (Muted amber – used sparingly)
  static const Color warning = Color(0xFFFFB74D);

  /// Info (Uses accent cyan instead of blue) - CLIENT SPEC
  static const Color info = accent;

  // ===== BUTTON COLORS =====

  /// Primary CTA Button - CLIENT SPEC
  /// Uses brand primary cyan
  static const Color btnPrimary = primary;

  /// Hover / Focus - CLIENT SPEC
  /// Slightly lighter shade for interaction feedback
  static const Color btnPrimaryHover = Color(0xFF00A598);

  /// Active / Pressed - CLIENT SPEC
  /// Darker shade for tactile feedback
  static const Color btnPrimaryActive = Color(0xFF008F7E);

  /// Disabled button
  static const Color btnDisabled = Color(0xFFCFD8DC);

  /// Secondary CTA (Bio-Glass Accent) - CLIENT SPEC
  static const Color btnSecondary = accent;

  /// Secondary Hover
  static const Color btnSecondaryHover = Color(0xFF1EB6CA);

  // ===== BORDERS & DIVIDERS (LIGHT MODE) =====

  /// Border color (Soft, subtle)
  static const Color border = Color(0xFFDDE6EA);

  /// Divider color
  static const Color divider = Color(0xFFE0E7EA);

  // ===== BORDERS & DIVIDERS (DARK MODE) =====

  /// Dark Mode Border
  static const Color borderDark = Color(0xFF2E3E40);

  /// Dark Mode Divider
  static const Color dividerDark = Color(0xFF2A3A3C);

  // ===== DATA VISUALIZATION COLORS =====

  /// Safe Zone Fill (Cyan with 10% opacity) - CLIENT SPEC
  /// Used for healthy range backgrounds on charts/vitals
  static const Color dataVisualizationSafeZone = Color(0x1A00B8A4);

  /// Heart Rate / Critical Alert
  static const Color dataVisualizationAlert = Color(0xFFE57373);

  /// Glucose / Warning Zone
  static const Color dataVisualizationWarning = Color(0xFFFFB74D);

  // ===== GRADIENTS =====

  /// Primary Premium CTA Gradient (STRICTLY VERTICAL) - CLIENT SPEC
  /// Creates "gem-like" tactile button appearance
  /// Start: Bio-Glass (#20C6DA) → End: Vanguard (#00B8A4)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      accent,   // #20C6DA (Bio-Glass)
      primary,  // #00B8A4 (Vanguard)
    ],
  );

  /// Subtle Sterile Background Gradient - CLIENT SPEC
  /// Enhances depth without introducing visual noise
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF7FBFC),
      Color(0xFFF5F9FA), // Sterile surface
    ],
  );

  /// Success Gradient (Medical-Safe) - CLIENT SPEC
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5FD3B8),
      Color(0xFF00A98F), // Success teal
    ],
  );

  /// Error Gradient (Soft but clear) - CLIENT SPEC
  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8B4B4),
      Color(0xFFE57373), // Softened error red
    ],
  );

  /// Accent Gradient (Used sparingly) - CLIENT SPEC
  /// For toggles and highlights
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6FE3EE),
      Color(0xFF20C6DA), // Bio-Glass
    ],
  );

  /// Dark Mode Primary Gradient - CLIENT SPEC
  /// Desaturated primary to prevent vibration on dark backgrounds
  static const LinearGradient primaryGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF80DEEA),
      Color(0xFF4DD0E1), // Desaturated vanguard
    ],
  );

  static const LinearGradient primaryGradientLight = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFE8F4F6), // Soft medical cyan
    Color(0xFFF6FAFB), // Near-white
  ],
);

static const LinearGradient primaryGradientDark1 = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1E2A32), // Deep blue-gray
    Color(0xFF263238), // Soft charcoal
  ],
);
static const LinearGradient doctorImageGradientDark = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF22303A),
    Color(0xFF2C3E50),
  ],
);
static const LinearGradient doctorImageGradientLight = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFE3F2FD),
    Color(0xFFF1F8FF),
  ],
);

 static const Color carbs = Color(0xFFFB8C00);     // orange
  static const Color protein = Color(0xFF2E7D32);   // green
  static const Color fat = Color(0xFFD32F2F);       // red
  static const Color calories = Color(0xFF1976D2);  // blue
}
