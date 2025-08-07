import 'package:flutter/material.dart';

// أسلوب جديد موحد للنصوص
class AppTextStyles {
  // عناوين الصفحات
  static const sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryDark,
  );

  // تسميات الحقول
  static const fieldLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // عناوين البطاقات
  static const cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryDark,
  );

  // رسائل الصفحة
  static const pageMessage = TextStyle(
    fontSize: 18,
    color: AppColors.textLight,
    fontWeight: FontWeight.w600,
  );
}

// ألوان النظام
class AppColors {
  // ألوان رئيسية
  static const primary = Color(0xFF4CAF50);
  static const primaryLight = Color(0xFF81C784);
  static const primaryDark = Color(0xFF2E7D32);

  // ألوان ثانوية
  static const accent = Color(0xFF1976D2);
  static const accentLight = Color(0xFF64B5F6);
  static const accentDark = Color(0xFF0D47A1);

  // ألوان خلفية
  static const background = Color(0xFFF7F9F6);
  static const cardBackground = Colors.white;

  // ألوان النص
  static const textDark = Color(0xFF333333);
  static const textLight = Color(0xFF666666);

  // ألوان الوضع الداكن
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF222222);
  static const darkCard = Color(0xFF2C2C2C);

  // ألوان الحالة
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFA000);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);

  // ألوان الفلترة والتنبيهات
  static const urgentRed = Color(0xFFF44336); // 7 أيام
  static const warningOrange = Color(0xFFFF9800); // 14 يوم
  static const cautionAmber = Color(0xFFFFC107); // شهر
  static const infoBlue = Color(0xFF2196F3); // 3 أشهر

  // ألوان حالة الوثائق
  static const expired = Color(0xFFD32F2F);
  static const expiringSoon = Color(0xFFFF8F00);
  static const valid = Color(0xFF388E3C);

  // ألوان أخرى
  static const divider = Color(0xFFE0E0E0);
  static const grey = Color(0xFF9E9E9E);
  static const lightGrey = Color(0xFFEEEEEE);
  static const darkGrey = Color(0xFF757575);

  // دالة للحصول على لون شفاف
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}

// ألوان الفلترة المحددة
class FilterColors {
  static const Map<int, Color> filterMap = {
    -1: AppColors.primary, // الكل - لون أساسي
    7: AppColors.urgentRed, // 7 أيام - أحمر
    14: AppColors.warningOrange, // 14 يوم - برتقالي
    30: AppColors.cautionAmber, // شهر - عنبري
    90: AppColors.infoBlue, // 3 أشهر - أزرق
  };

  static const Map<int, String> filterLabels = {
    -1: 'الكل',
    7: '7 أيام',
    14: '14 يوم',
    30: 'شهر',
    90: '3 أشهر',
  };

  // دالة للحصول على لون الحالة حسب الأيام المتبقية
  static Color getStatusColor(int daysLeft) {
    if (daysLeft <= 7) return AppColors.urgentRed;
    if (daysLeft <= 14) return AppColors.warningOrange;
    if (daysLeft <= 30) return AppColors.cautionAmber;
    return AppColors.infoBlue;
  }
}

// أحجام النص
class AppSizes {
  static const double headline1 = 28.0;
  static const double headline2 = 24.0;
  static const double headline = 24.0;
  static const double title = 20.0;
  static const double subtitle = 18.0;
  static const double body = 16.0;
  static const double caption = 14.0;
  static const double small = 12.0;
  static const double tiny = 10.0;
}

// مسافات
class AppPadding {
  static const double tiny = 4.0;
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;
  static const double xxl = 48.0;
}

// نصف أقطار الزوايا
class AppBorderRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double extraLarge = 24.0;
  static const double circle = 50.0;
}

// أحجام العناصر
class AppSizing {
  static const double buttonHeight = 48.0;
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeSmall = 18.0;
  static const double avatarSize = 40.0;
  static const double maxContentWidth = 1200.0;
}

// زمن الرسوم المتحركة
class AppAnimationDuration {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
}
