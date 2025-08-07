import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/constants.dart';

/// زر تبديل الثيم بين الوضع الداكن والفاتح
class ThemeSwitcher extends StatelessWidget {
  final bool showLabel;
  final double size;

  const ThemeSwitcher({Key? key, this.showLabel = false, this.size = 24.0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return InkWell(
      borderRadius: BorderRadius.circular(AppBorderRadius.circle),
      onTap: () {
        themeProvider.toggleThemeMode();
      },
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.small),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: size,
              color: isDarkMode ? AppColors.warning : AppColors.grey,
            ),
            if (showLabel)
              Padding(
                padding: const EdgeInsets.only(right: AppPadding.small),
                child: Text(
                  isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
                  style: TextStyle(
                    fontSize: size * 0.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// زر للتبديل بين أوضاع الثيم الثلاثة: فاتح، داكن، نظام
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return PopupMenuButton<String>(
      icon: Icon(
        themeProvider.useSystemTheme
            ? Icons.brightness_auto
            : (isDarkMode ? Icons.dark_mode : Icons.light_mode),
        color: isDarkMode ? Colors.amber : AppColors.accent,
      ),
      onSelected: (value) {
        switch (value) {
          case 'light':
            themeProvider.setLightMode();
            break;
          case 'dark':
            themeProvider.setDarkMode();
            break;
          case 'system':
            themeProvider.setSystemTheme();
            break;
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      tooltip: 'تغيير الثيم',
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'light',
          child: _buildMenuItem(
            icon: Icons.light_mode,
            text: 'وضع فاتح',
            isSelected: !themeProvider.useSystemTheme && !isDarkMode,
            context: context,
          ),
        ),
        PopupMenuItem<String>(
          value: 'dark',
          child: _buildMenuItem(
            icon: Icons.dark_mode,
            text: 'وضع داكن',
            isSelected: !themeProvider.useSystemTheme && isDarkMode,
            context: context,
          ),
        ),
        PopupMenuItem<String>(
          value: 'system',
          child: _buildMenuItem(
            icon: Icons.brightness_auto,
            text: 'وضع النظام',
            isSelected: themeProvider.useSystemTheme,
            context: context,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required bool isSelected,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
        const SizedBox(width: AppPadding.small),
        Text(
          text,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
