import 'package:flutter/material.dart';
import 'package:taqeb/utils/constants.dart';

/// عنوان الصفحة مع أيقونة
class PageTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final double? fontSize;

  const PageTitle(this.title, {super.key, this.icon, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize ?? AppSizes.title,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

/// بطاقة قسم رئيسي
class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppPadding.medium),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(title, style: AppTextStyles.sectionTitle),
              ],
            ),
          ),
          Padding(
            padding: padding ?? const EdgeInsets.all(AppPadding.medium),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// زر عمل رئيسي
class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool isLoading;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }
}

/// حقل إدخال مخصص
class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool isRequired;
  final TextInputType keyboardType;
  final int? maxLines;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: isRequired ? "$label *" : label,
          hintText: hint,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: AppColors.primary)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.small),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.small),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        validator:
            validator ??
            (isRequired
                ? (value) =>
                      value == null || value.isEmpty ? "هذا الحقل مطلوب" : null
                : null),
      ),
    );
  }
}

/// مربع حوار تأكيد
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'تأكيد',
  String cancelText = 'إلغاء',
  bool isDanger = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: Text(content, style: const TextStyle(fontSize: 16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText, style: const TextStyle(fontSize: 16)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmText,
            style: TextStyle(
              color: isDanger ? AppColors.error : AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

/// عرض رسالة تنبيه
void showSnackMessage(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(8),
    ),
  );
}

/// صف معلومات (اسم-قيمة)
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryDark,
                ),
              ),
              Expanded(
                child: Text(value, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

/// عنصر فارغ لعرضه عندما لا توجد بيانات
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.pageMessage,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة حالة مع لون ديناميكي
class StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? value;
  final int daysLeft;
  final IconData icon;
  final VoidCallback? onTap;

  const StatusCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.value,
    required this.daysLeft,
    required this.icon,
    this.onTap,
  });

  Color get statusColor => FilterColors.getStatusColor(daysLeft);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            border: Border.all(color: statusColor, width: 1),
          ),
          padding: const EdgeInsets.all(AppPadding.medium),
          child: Row(
            children: [
              // أيقونة الحالة
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),

              // محتوى البطاقة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        value!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // الأيام المتبقية
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      daysLeft <= 7 ? Icons.warning : Icons.schedule,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'متبقي $daysLeft يوم',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر فلتر مع لون ديناميكي
class FilterButton extends StatelessWidget {
  final int days;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const FilterButton({
    super.key,
    required this.days,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  Color get filterColor => FilterColors.filterMap[days] ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(
            isSelected ? Icons.check_circle : Icons.schedule,
            size: 18,
          ),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? filterColor
                : filterColor.withValues(alpha: 0.2),
            foregroundColor: isSelected ? Colors.white : filterColor,
            elevation: isSelected ? 4 : 1,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: filterColor, width: 1),
            ),
          ),
        ),
      ),
    );
  }
}

/// صف أزرار الفلترة
class FilterRow extends StatelessWidget {
  final int selectedFilter;
  final Function(int) onFilterChanged;

  const FilterRow({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'فلترة حسب الفترة الزمنية:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: FilterColors.filterLabels.entries.map((entry) {
            final days = entry.key;
            final label = entry.value;
            final isSelected = selectedFilter == days;

            return FilterButton(
              days: days,
              label: label,
              isSelected: isSelected,
              onPressed: () => onFilterChanged(days),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// بطاقة حساب مصغرة قابلة للنقر
class CompactAccountCard extends StatelessWidget {
  final dynamic account; // يمكن أن يكون AccountModel
  final VoidCallback onTap;
  final bool showDueDate;

  const CompactAccountCard({
    super.key,
    required this.account,
    required this.onTap,
    this.showDueDate = true,
  });

  // حساب عدد الأيام المتبقية حتى تاريخ الاستحقاق
  int _getRemainingDays() {
    final now = DateTime.now();
    return account.dueDate.difference(now).inDays;
  }

  // تحديد لون الحساب بناءً على الأيام المتبقية
  Color _getStatusColor() {
    final daysRemaining = _getRemainingDays();

    if (daysRemaining < 0) {
      return Colors.red;
    } else if (daysRemaining <= 7) {
      return Colors.orange;
    } else {
      return AppColors.primary;
    }
  }

  // تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final remainingDays = _getRemainingDays();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // أيقونة الحساب
              Icon(Icons.account_balance_wallet, color: statusColor, size: 24),
              const SizedBox(width: 12),
              // معلومات الحساب
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showDueDate) ...[
                      const SizedBox(height: 4),
                      Text(
                        'يستحق: ${_formatDate(account.dueDate)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // المعلومات المالية مصغرة
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${account.remaining.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: account.remaining > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remainingDays < 0
                        ? 'متأخر ${-remainingDays}د'
                        : remainingDays == 0
                        ? 'اليوم'
                        : '${remainingDays}د',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // أيقونة السهم
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
