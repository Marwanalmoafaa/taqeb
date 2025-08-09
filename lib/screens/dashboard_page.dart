import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taqeb/utils/constants.dart';
import 'package:taqeb/utils/theme_provider.dart';

// استيراد الشاشات المطلوبة
import 'package:taqeb/screens/companies_screen.dart';
import 'package:taqeb/screens/transactions_screen.dart';
import 'package:taqeb/screens/accounts_screen.dart';
import 'package:taqeb/screens/due_notifications_screen.dart';
import 'package:taqeb/screens/settings_screen.dart';

/// الصفحة الرئيسية التي تحتوي على القائمة الجانبية والمحتوى
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // قائمة الشاشات في لوحة التحكم
  final List<Widget> _screens = [
    const CompaniesScreen(),
    const TransactionsScreen(),
    const AccountsScreen(),
    const DueNotificationsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // فحص حجم الشاشة
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    // تحديد ألوان القائمة بناءً على الثيم
    final sidebarColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final selectedItemColor = AppColors.primary;
    final unselectedItemColor = isDarkMode
        ? Colors.white70
        : AppColors.textLight;
    final dividerColor = isDarkMode ? Colors.white24 : AppColors.divider;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        // إضافة AppBar للشاشات الصغيرة
        appBar: isMobile
            ? AppBar(
                title: const Text('تعقيب'),
                backgroundColor: sidebarColor,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              )
            : null,
        // قائمة جانبية للشاشات الصغيرة
        drawer: isMobile
            ? _buildDrawerContent(
                sidebarColor,
                selectedItemColor,
                unselectedItemColor,
                dividerColor,
                isDarkMode,
              )
            : null,
        body: isMobile
            ?
              // تخطيط للشاشات الصغيرة (الجوال)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _screens[_selectedIndex],
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
              )
            :
              // تخطيط للشاشات الكبيرة (سطح المكتب)
              Row(
                children: [
                  // القائمة الجانبية المحسنة للشاشات الكبيرة
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: sidebarColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            isDarkMode ? 0.5 : 0.1,
                          ),
                          blurRadius: 10,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: _buildSidebarContent(
                      selectedItemColor,
                      unselectedItemColor,
                      dividerColor,
                      isDarkMode,
                    ),
                  ),
                  // محتوى الصفحة
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _screens[_selectedIndex],
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // بناء عنصر قائمة
  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String title,
    required Color selectedColor,
    required Color unselectedColor,
  }) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? selectedColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          // إغلاق القائمة الجانبية على الشاشات الصغيرة
          final screenWidth = MediaQuery.of(context).size.width;
          if (screenWidth < 768) {
            Navigator.of(context).pop();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? selectedColor : unselectedColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // بناء محتوى القائمة الجانبية للشاشات الصغيرة (Drawer)
  Widget _buildDrawerContent(
    Color sidebarColor,
    Color selectedItemColor,
    Color unselectedItemColor,
    Color dividerColor,
    bool isDarkMode,
  ) {
    return Container(
      width: 280,
      color: sidebarColor,
      child: _buildSidebarContent(
        selectedItemColor,
        unselectedItemColor,
        dividerColor,
        isDarkMode,
      ),
    );
  }

  // بناء محتوى القائمة الجانبية
  Widget _buildSidebarContent(
    Color selectedItemColor,
    Color unselectedItemColor,
    Color dividerColor,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        const SizedBox(height: 32),
        // شعار النظام المحسن
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // الشعار
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF45A049)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تعقيب',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.white
                                : AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'نظام إدارة المؤسسات',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.white70
                                : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Divider(height: 1, color: dividerColor),
        const SizedBox(height: 20),
        // قائمة العناصر
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildMenuItem(
                index: 0,
                icon: Icons.business,
                title: 'المؤسسات',
                selectedColor: selectedItemColor,
                unselectedColor: unselectedItemColor,
              ),
              _buildMenuItem(
                index: 1,
                icon: Icons.receipt_long,
                title: 'المعاملات',
                selectedColor: selectedItemColor,
                unselectedColor: unselectedItemColor,
              ),
              _buildMenuItem(
                index: 2,
                icon: Icons.account_balance_wallet,
                title: 'الحسابات',
                selectedColor: selectedItemColor,
                unselectedColor: unselectedItemColor,
              ),
              Divider(
                height: 32,
                color: dividerColor,
                indent: 20,
                endIndent: 20,
              ),
              _buildMenuItem(
                index: 3,
                icon: Icons.notifications,
                title: 'الإشعارات',
                selectedColor: selectedItemColor,
                unselectedColor: unselectedItemColor,
              ),
              Divider(
                height: 32,
                color: dividerColor,
                indent: 20,
                endIndent: 20,
              ),
              _buildMenuItem(
                index: 4,
                icon: Icons.settings,
                title: 'الإعدادات',
                selectedColor: selectedItemColor,
                unselectedColor: unselectedItemColor,
              ),
            ],
          ),
        ),

        // معلومات التطبيق في الأسفل
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Divider(height: 1, color: dividerColor),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isDarkMode
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.lightGrey,
                    radius: 20,
                    child: const Icon(Icons.settings, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'الإصدار 1.5.0+6',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.white70
                            : AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
