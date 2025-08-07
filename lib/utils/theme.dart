import 'package:flutter/material.dart';
import 'constants.dart';

/// نظام الألوان والثيم المتكامل للتطبيق
/// يدعم الوضع الداكن والوضع الفاتح
class AppTheme {
  // تحديد ما إذا كان الجهاز في الوضع الداكن
  static bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  // الحصول على الثيم المناسب حسب وضع الجهاز
  static ThemeData getTheme(BuildContext context) {
    return isDarkMode(context) ? darkTheme : lightTheme;
  }

  // ثيم الوضع الفاتح
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Arial',
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      background: AppColors.background,
      surface: AppColors.cardBackground,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textDark,
      onBackground: AppColors.textDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppBorderRadius.medium),
        ),
      ),
      titleTextStyle: TextStyle(
        fontSize: AppSizes.title,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
      displaySmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: AppColors.textDark,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textDark,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textLight,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textLight,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textLight,
      ),
      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
      errorStyle: const TextStyle(fontWeight: FontWeight.w500),
      suffixIconColor: AppColors.primary,
      prefixIconColor: AppColors.primary,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 24,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.circle),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textLight,
      indicatorColor: AppColors.primary,
      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(width: 2.0, color: AppColors.primary),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return Colors.transparent;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return Colors.grey;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.5);
      }),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
      ),
      titleTextStyle: const TextStyle(
        fontSize: AppSizes.title,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
      contentTextStyle: const TextStyle(
        fontSize: AppSizes.body,
        color: AppColors.textDark,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.large),
        ),
      ),
      modalElevation: 8,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.cardBackground,
      indicatorColor: AppColors.primary.withOpacity(0.2),
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      iconTheme: MaterialStateProperty.all(
        const IconThemeData(color: AppColors.textDark),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textDark,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: AppSizes.body,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    ),
  );

  // ثيم الوضع الداكن
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Arial',
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      background: const Color(0xFF121212),
      surface: const Color(0xFF222222),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppBorderRadius.medium),
        ),
      ),
      titleTextStyle: TextStyle(
        fontSize: AppSizes.title,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displaySmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.white,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Colors.grey,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
        elevation: 4,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF333333),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.grey,
      ),
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.grey),
      errorStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        color: AppColors.error,
      ),
      suffixIconColor: AppColors.primary,
      prefixIconColor: AppColors.primary,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF444444),
      thickness: 1,
      space: 24,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.circle),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: Colors.grey[400],
      indicatorColor: AppColors.primary,
      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(width: 2.0, color: AppColors.primary),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return Colors.transparent;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return Colors.grey;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.5);
      }),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
      ),
      titleTextStyle: const TextStyle(
        fontSize: AppSizes.title,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      contentTextStyle: const TextStyle(
        fontSize: AppSizes.body,
        color: Colors.white,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: const Color(0xFF222222),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.large),
        ),
      ),
      modalElevation: 8,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF222222),
      indicatorColor: AppColors.primary.withOpacity(0.2),
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      iconTheme: MaterialStateProperty.all(
        const IconThemeData(color: Colors.white),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF333333),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: AppSizes.body,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    ),
  );
}
