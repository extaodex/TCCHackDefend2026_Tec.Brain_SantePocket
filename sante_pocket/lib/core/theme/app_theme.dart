import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Semantic Colors (Gradients & Solid)
  static const Color primaryBlueDark = Color(0xFF1E3A8A);
  static const Color primaryBlueLight = Color(0xFF3B82F6);
  
  static const Color emergencyRedDark = Color(0xFF7F1D1D);
  static const Color emergencyRedLight = Color(0xFFEF4444);

  static const Color validatedGreenDark = Color(0xFF14532D);
  static const Color validatedGreenLight = Color(0xFF22C55E);

  static const Color pendingOrangeDark = Color(0xFF7C2D12);
  static const Color pendingOrangeLight = Color(0xFFF97316);
  
  static const Color identityBlue = primaryBlueLight;
  static const Color emergencyRed = emergencyRedLight;
  static const Color validatedGreen = validatedGreenLight;
  static const Color pendingOrange = pendingOrangeLight;
  
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color glassWhite = Color(0x33FFFFFF);
  static const Color glassBorder = Color(0x4DFFFFFF);

  // Gradients for premium buttons/cards
  static const LinearGradient blueGradient = LinearGradient(
    colors: [primaryBlueLight, primaryBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [emergencyRedLight, emergencyRedDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [validatedGreenLight, validatedGreenDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [pendingOrangeLight, pendingOrangeDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Premium Shadow
  static List<BoxShadow> premiumShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.light(
        primary: primaryBlueLight,
        secondary: primaryBlueDark,
        error: emergencyRedLight,
        surface: Colors.white,
        onSurface: textDark,
      ),
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: textDark, letterSpacing: -0.5),
        titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500, color: textDark),
        bodyMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w400, color: textDark),
        labelLarge: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: textDark.withValues(alpha: 0.6)),
      ),
    );
  }
}
