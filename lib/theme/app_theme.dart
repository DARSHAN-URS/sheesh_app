import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Master Brand Kit Palette (Harmonized with Splash Screen & Official Logo) ──
  static const Color plum = Color(0xFF5A1629); // Deep Berry Wine (Logo background & luxury brand anchor)
  static const Color wine = Color(0xFF5A1629); // Official logo wine tone
  static const Color wineLight = Color(0xFF6E1B31); // Highlight wine tone
  static const Color wineDark = Color(0xFF45101E); // Shadow wine tone
  static const Color coral = Color(0xFFD64438); // Terracotta Coral Red ("श", arch, star & primary CTA)
  static const Color coralLight = Color(0xFFE8695F); // Soft coral highlight
  static const Color coralDark = Color(0xFFB83228); // Rich crimson coral
  static const Color blush = Color(0xFFF8EDE7); // Soft Warm Blush (Cards & organic splash blobs)
  static const Color blushLight = Color(0xFFFAF1E8);
  static const Color cream = Color(0xFFFAF3EC); // Warm Ivory Cream (Canvas background)
  static const Color creamLight = Color(0xFFFFFBF7); // Center glow cream
  static const Color nearBlack = Color(0xFF261017); // Luxury Espresso Wine-Black (Body & "She" text)
  static const Color pureWhite = Color(0xFFFFFFFF);

  // ── Core Theme Aliases ──────────────────────────────────────────
  static const Color primary = coral; // Terracotta Coral Red as dynamic action color
  static const Color primaryDark = wine; // Deep Berry Wine as primary brand surface
  static const Color primaryLight = coralLight; // Soft coral as interactive accent

  // ── Secondary Gold & Brass Palette (Artisan Heritage Accents) ───
  static const Color gold = Color(0xFFC89B3C); // Antique Indian brass gold
  static const Color goldLight = Color(0xFFE8C87A); // Warm shimmer gold
  static const Color goldDark = Color(0xFFA6761A); // Antique bronze

  // ── Accent & Neutral Tones ──────────────────────────────────────
  static const Color accentTeal = Color(0xFF2A7B54); // Forest sage accent
  static const Color background = cream; // Warm cream background
  static const Color surface = pureWhite;
  static const Color surfaceElevated = blush; // Soft blush card surface
  
  // ── Text Colors ─────────────────────────────────────────────────
  static const Color textPrimary = nearBlack; // Near-black luxury espresso text
  static const Color textSecondary = Color(0xFF6D5262); // Muted plum brown
  static const Color textLight = Color(0xFF8A6B7E); // Soft plum slate
  
  // ── Functional Colors ───────────────────────────────────────────
  static const Color success = Color(0xFF2A7B54);
  static const Color warning = Color(0xFFC07D2B);
  static const Color error = Color(0xFFD64438);
  static const Color border = Color(0xFFF0DDD4); // Soft warm border
  static const Color divider = Color(0xFFF0DDD4);

  // ── Convenience Aliases ─────────────────────────────────────────
  static const Color textDark = textPrimary;
  static const Color accent = gold;
  static const Color accentColor = gold;
  static const Color backgroundLight = creamLight;

  // ── Atmospheric Background Asset Paths ──────────────────────────
  static const String ambientStudioBg = 'assets/images/backgrounds/app-ambient.jpg';
  static const String craftStudioBg = 'assets/images/backgrounds/craft-studio.jpg';
  static const String potteryClayBg = 'assets/images/backgrounds/pottery-clay.jpg';

  // ── Gradients (Founder-Approved Palette) ────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [wineLight, coral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient wineGradient = LinearGradient(
    colors: [wineLight, wineDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coralGradient = LinearGradient(
    colors: [coral, coralDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [wine, wineDark, coral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [wine, nearBlack],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softWarmGradient = LinearGradient(
    colors: [cream, creamLight, blushLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldLight, gold, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Ambient Background Decoration
  static BoxDecoration ambientBackground({String? imagePath, double opacity = 0.94}) {
    return BoxDecoration(
      color: AppColors.background,
      image: DecorationImage(
        image: AssetImage(imagePath ?? ambientStudioBg),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          AppColors.background.withValues(alpha: opacity),
          BlendMode.srcOver,
        ),
      ),
    );
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.gold,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          color: AppColors.textPrimary,
          height: 1.45,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          color: AppColors.textLight,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textLight, fontSize: 14),
      ),
    );
  }
}
