import 'package:flutter/material.dart';

class AppColors {

  static const background = Color(0xFF1B1B1F);
  static const surface = Color(0xFF232329);
  static const surfaceAlt = Color(0xFF2B2B33);
  static const card = Color(0xFF2E2E38);
  static const border = Color(0xFF3D3D4A);
  static const accent = Color(0xFF6C8CFF);
  static const accentDim = Color(0xFF4A5FA8);
  static const onAccent = Color(0xFFFFFFFF);
  static const text = Color(0xFFEBEBF0);
  static const textSecondary = Color(0xFF9C9CA8);
  static const green = Color(0xFF4BA04F);
  static const mediumSeaGreen = Color(0xFF6CCB5F);
  static const red = Color(0xFFF44336);
  static const darkRed = Color(0xFFC2362E);
  static const orange = Color(0xFFFF9800);
  static const eldenOrange = Color(0xFFFF4F00);
  static const amber = Color(0xFFFFC107);
  static const teal = Color(0xFF009688);
  static const purple = Color(0xFF9C27B0);
  static const deepPurple = Color(0xFF673AB7);
  static const blue = Color(0xFF2196F3);
  static const lightBlue = Color(0xFF03A9F4);
  static const pink = Color(0xFFE91E63);
  static const grey = Color(0xFF9E9E9E);
}

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    const scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.lightBlue,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.red,
      surfaceContainerHighest: AppColors.surfaceAlt,
      outline: AppColors.border,
    );
    return base.copyWith(
      colorScheme: scheme,
      textTheme: base.textTheme.apply(fontFamily: 'Inter'),
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: const CardThemeData(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        selectedIconTheme: IconThemeData(color: AppColors.accent),
        unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.accent,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.accent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: TextStyle(color: AppColors.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.border,
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(AppColors.border),
        thickness: WidgetStatePropertyAll(8),
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        textStyle: TextStyle(color: AppColors.text, fontSize: 12),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.accentDim,
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
