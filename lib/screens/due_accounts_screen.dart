import 'package:flutter/material.dart';
import 'package:taqeb/models/account.dart';
import 'package:taqeb/services/database_service.dart';
import 'package:taqeb/utils/constants.dart';
import 'package:taqeb/widgets/common_widgets.dart';
import 'package:taqeb/screens/accounts_screen.dart';

/// شاشة عرض الحسابات غير المسددة (المتبقية)
class DueAccountsScreen extends StatelessWidget {
  const DueAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب جميع الحسابات التي فيها مبلغ متبقٍ
    final List<AccountModel> dueAccounts = DatabaseService.getAllAccounts()
        .where((a) => a.remaining > 0)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const PageTitle('المستحقات', icon: Icons.notifications_active),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: dueAccounts.isEmpty
          ? const EmptyState(
              message: 'لا توجد حسابات مستحقة حالياً',
              icon: Icons.notifications_off,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dueAccounts.length,
              itemBuilder: (context, index) {
                final account = dueAccounts[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      account.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المتبقي: ${account.remaining.toStringAsFixed(2)} ريال',
                          style: TextStyle(
                            color: account.remaining > 0
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'تاريخ الاستحقاق: ${account.dueDate.year}/${account.dueDate.month}/${account.dueDate.day}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      // فتح صفحة تعديل الحساب
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AccountFormPage(accountToEdit: account),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
