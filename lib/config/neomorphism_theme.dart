import 'package:flutter/material.dart';

/// Neomorphism UI Theme for BemiChat
///
/// Color Palette:
/// - Primary: Deep Purple (#5B4B8A)
/// - Secondary: Light Purple (#8B7BA8)
/// - Background: Off-White (#F5F5F7)
/// - Surface: White (#FFFFFF)
/// - Accent: Vivid Purple (#7C5DFA)
class NeomorphismTheme {
  // Primary Colors
  static const Color primaryPurple = Color(0xFF5B4B8A);
  static const Color secondaryPurple = Color(0xFF8B7BA8);
  static const Color accentPurple = Color(0xFF7C5DFA);

  // Neutral Colors
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color backgroundGrey = Color(0xFFF5F5F7);
  static const Color lightGrey = Color(0xFFECECF1);
  static const Color mediumGrey = Color(0xFFB8B8C8);
  static const Color darkGrey = Color(0xFF808090);
  static const Color textDark = Color(0xFF2C2C54);

  // Shadow Colors
  static const Color shadowDark = Color(0x1A2C2C54);
  static const Color shadowLight = Color(0x0FFFFFFF);

  // Semantic Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color infoBlue = Color(0xFF3B82F6);

  /// Soft shadow for elevated elements (outer shadow)
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: shadowDark,
      offset: const Offset(4, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowLight,
      offset: const Offset(-4, -4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  /// Medium shadow for interactive elements
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: shadowDark,
      offset: const Offset(2, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowLight,
      offset: const Offset(-2, -2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  /// Inset shadow for pressed state
  static List<BoxShadow> get insetShadow => [
    const BoxShadow(
      color: Color(0x1A2C2C54),
      offset: Offset(-4, -4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    const BoxShadow(
      color: Color(0x0FFFFFFF),
      offset: Offset(4, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  /// Heavy shadow for floating elements (FABs, cards)
  static List<BoxShadow> get heavyShadow => [
    BoxShadow(
      color: shadowDark,
      offset: const Offset(8, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowLight,
      offset: const Offset(-8, -8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  /// Material Theme Data with Neomorphism
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryPurple,
      secondary: secondaryPurple,
      tertiary: accentPurple,
      surface: surfaceWhite,
      error: errorRed,
      onPrimary: surfaceWhite,
      onSecondary: surfaceWhite,
      onSurface: textDark,
    ),
    scaffoldBackgroundColor: backgroundGrey,

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundGrey,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),

    // FAB Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentPurple,
      foregroundColor: surfaceWhite,
      elevation: 0,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 32),
      extendedTextStyle: const TextStyle(
        color: surfaceWhite,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.5,
      ),
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textDark,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textDark,
        letterSpacing: -0.3,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textDark,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textDark,
        letterSpacing: 0.15,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textDark,
        letterSpacing: 0.15,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textDark,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textDark,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mediumGrey,
        letterSpacing: 0.4,
        height: 1.33,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
        letterSpacing: 0.1,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: mediumGrey,
        letterSpacing: 0.5,
      ),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentPurple,
        foregroundColor: surfaceWhite,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryPurple,
        side: const BorderSide(color: primaryPurple, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentPurple,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed, width: 2),
      ),
      hintStyle: const TextStyle(
        color: mediumGrey,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        color: primaryPurple,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: const TextStyle(
        color: errorRed,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      helperStyle: const TextStyle(
        color: mediumGrey,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      prefixIconColor: mediumGrey,
      suffixIconColor: mediumGrey,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: surfaceWhite,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: lightGrey,
      thickness: 1,
      space: 0,
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accentPurple,
      linearMinHeight: 4,
      refreshBackgroundColor: backgroundGrey,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: lightGrey,
      disabledColor: lightGrey.withValues(alpha: 0.5),
      selectedColor: accentPurple,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textDark,
      ),
      secondaryLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: surfaceWhite,
      ),
      brightness: Brightness.light,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // Drawer Theme
    drawerTheme: const DrawerThemeData(
      backgroundColor: surfaceWhite,
      elevation: 0,
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    // Snack Bar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textDark,
      contentTextStyle: const TextStyle(
        color: surfaceWhite,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    ),
  );
}

/// Neomorphism Utilities
class NeomorphismUtil {
  /// Create a neomorphic container with elevation effect
  static Container elevatedContainer({
    required Widget child,
    double width = double.infinity,
    double height = double.infinity,
    double borderRadius = 16,
    EdgeInsets padding = const EdgeInsets.all(16),
    EdgeInsets margin = EdgeInsets.zero,
    Color? backgroundColor,
    VoidCallback? onTap,
    bool pressed = false,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? NeomorphismTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: pressed
            ? NeomorphismTheme.insetShadow
            : NeomorphismTheme.softShadow,
      ),
      child: onTap != null
          ? GestureDetector(onTap: onTap, child: child)
          : child,
    );
  }

  /// Create a neomorphic button
  static GestureDetector neomorphicButton({
    required String label,
    required VoidCallback onPressed,
    bool loading = false,
    bool enabled = true,
    IconData? icon,
    double borderRadius = 12,
    double width = double.infinity,
    double height = 50,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return GestureDetector(
      onTap: enabled && !loading ? onPressed : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? NeomorphismTheme.accentPurple,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: NeomorphismTheme.softShadow,
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      textColor ?? NeomorphismTheme.surfaceWhite,
                    ),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: textColor ?? NeomorphismTheme.surfaceWhite,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor ?? NeomorphismTheme.surfaceWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Create a neomorphic input field
  static Container neomorphicInput({
    required TextEditingController controller,
    String? label,
    String? hint,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
    Function(String)? onChanged,
    double borderRadius = 12,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: NeomorphismTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: NeomorphismTheme.mediumShadow,
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        maxLines: isPassword ? 1 : maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: NeomorphismTheme.accentPurple,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: NeomorphismTheme.mediumGrey)
              : null,
          suffixIcon: suffixIcon != null
              ? GestureDetector(
                  onTap: onSuffixTap,
                  child: Icon(suffixIcon, color: NeomorphismTheme.mediumGrey),
                )
              : null,
          filled: true,
          fillColor: NeomorphismTheme.surfaceWhite,
          hintStyle: const TextStyle(
            color: NeomorphismTheme.mediumGrey,
            fontSize: 14,
          ),
          labelStyle: const TextStyle(
            color: NeomorphismTheme.primaryPurple,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
