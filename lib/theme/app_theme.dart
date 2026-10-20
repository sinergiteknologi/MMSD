import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const navy = Color(0xFF12263A);
  static const navyDeep = Color(0xFF0B1824);
  static const ink = Color(0xFF1C1917);
  static const cream = Color(0xFFF6F1E8);
  static const sand = Color(0xFFE7DCCB);
  static const mist = Color(0xFFFAF7F2);
  static const terracotta = Color(0xFFC45C26);
  static const gold = Color(0xFFC4A35A);
  static const sage = Color(0xFF4A7C6F);
  static const muted = Color(0xFF7A7067);
  static const line = Color(0xFFDDD4C6);
}

class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.navy,
      onPrimary: Colors.white,
      secondary: AppColors.terracotta,
      onSecondary: Colors.white,
      tertiary: AppColors.gold,
      onTertiary: AppColors.navy,
      error: Color(0xFFB42318),
      onError: Colors.white,
      surface: AppColors.mist,
      onSurface: AppColors.ink,
      outline: AppColors.line,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.sand),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.sand),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.sand),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navyDeep,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.sand, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.terracotta,
        linearTrackColor: AppColors.sand,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.mist,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: AppColors.ink,
          height: 1.15,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: AppColors.ink),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
