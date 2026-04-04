import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // === NEON DARK THEME ===
  static ThemeData get neonTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColorsDark.mainBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColorsDark.primaryBlue,
        secondary: AppColorsDark.secondaryBlue,
        surface: AppColorsDark.cardBackground,
        error: AppColorsDark.notificationRed,
        onPrimary: Colors.black, 
        onSecondary: Colors.white,
        onSurface: AppColorsDark.primaryText,
        onError: Colors.white,
      ),
      dividerColor: AppColorsDark.dividerGray,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColorsDark.primaryText),
        bodyMedium: TextStyle(color: AppColorsDark.secondaryText),
        titleLarge: TextStyle(color: AppColorsDark.primaryText),
        titleMedium: TextStyle(color: AppColorsDark.primaryText),
        titleSmall: TextStyle(color: AppColorsDark.primaryText),
        labelLarge: TextStyle(color: AppColorsDark.primaryText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppButtonStyles.primaryButtonDark,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.primaryText,
          side: const BorderSide(color: AppColorsDark.lightBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.transparent,
          disabledForegroundColor: AppColorsDark.disabledText,
          disabledBackgroundColor: AppColorsDark.lightBorder,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.secondaryBlue,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsDark.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColorsDark.lightBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsDark.dividerGray,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // === LIGHT THEME ===
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColorsLight.mainBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColorsLight.primaryBlue,
        secondary: AppColorsLight.secondaryBlue,
        surface: AppColorsLight.cardBackground,
        error: AppColorsLight.notificationRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColorsLight.primaryText,
        onError: Colors.white,
      ),
      dividerColor: AppColorsLight.dividerGray,
      textTheme: GoogleFonts.poppinsTextTheme(const TextTheme(
        bodyLarge: TextStyle(color: AppColorsLight.primaryText),
        bodyMedium: TextStyle(color: AppColorsLight.secondaryText),
        titleLarge: TextStyle(color: AppColorsLight.primaryText, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppColorsLight.primaryText, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: AppColorsLight.primaryText, fontWeight: FontWeight.w600),
        labelLarge: TextStyle(color: AppColorsLight.primaryText),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppButtonStyles.primaryButtonLight,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsLight.primaryText,
          side: const BorderSide(color: AppColorsLight.lightBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.transparent,
          disabledForegroundColor: AppColorsLight.disabledText,
          disabledBackgroundColor: AppColorsLight.lightBorder,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsLight.secondaryBlue,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsLight.cardBackground,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.transparent),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsLight.dividerGray,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class AppButtonStyles {
  // ==== DARK BUTTONS ====
  static ButtonStyle get primaryButtonDark {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return AppColorsDark.lightBorder;
        if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) return AppColorsDark.primaryButtonHover;
        return AppColorsDark.primaryBlue;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return AppColorsDark.disabledText;
        return Colors.black; 
      }),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
    );
  }

  static ButtonStyle get secondaryButtonDark {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return AppColorsDark.lightBorder;
        if (states.contains(WidgetState.pressed)) return AppColorsDark.secondaryButtonPressed;
        return AppColorsDark.secondaryBlue;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return AppColorsDark.disabledText;
        return Colors.white;
      }),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
    );
  }

  // ==== LIGHT BUTTONS ====
  static ButtonStyle get primaryButtonLight {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return AppColorsLight.lightBorder;
        if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) return AppColorsLight.primaryButtonHover;
        return AppColorsLight.primaryBlue;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return AppColorsLight.disabledText;
        return Colors.white;
      }),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
    );
  }

  static ButtonStyle get secondaryButtonLight {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return AppColorsLight.lightBorder;
        if (states.contains(WidgetState.pressed)) return AppColorsLight.secondaryButtonPressed;
        return AppColorsLight.secondaryBlue;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return AppColorsLight.disabledText;
        return Colors.white;
      }),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
    );
  }
}
