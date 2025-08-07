import 'package:flutter/material.dart';
import 'package:taqeb/models/account.dart';
import 'package:taqeb/models/company.dart';
import 'package:taqeb/services/database_service.dart';
import 'package:taqeb/widgets/common_widgets.dart';

/// شاشة عرض الوثائق القريبة من الانتهاء
class ExpiringSoonScreen extends StatelessWidget {
  const ExpiringSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب جميع الحسابات والمؤسسات
    final List<AccountModel> allAccounts = DatabaseService.getAllAccounts();
    final List<Company> allCompanies = DatabaseService.getAllCompanies();

    // جمع الإقامات والوثائق القريبة من الانتهاء
    List<Map<String, dynamic>> expiringSoonItems = [];

    // فحص الحسابات
    for (final account in allAccounts) {
      // فحص تاريخ انتهاء الإقامة الأساسية
      final now = DateTime.now();
      final difference = account.dueDate.difference(now);

      if (difference.inDays <= 90 && difference.inDays >= 0) {
        expiringSoonItems.add({
          'type': 'إقامة',
          'accountName': account.name,
          'expiryDate': account.dueDate,
          'daysLeft': difference.inDays,
          'account': account,
        });
      }

      // فحص الوثائق الإضافية في الحسابات
      for (final document in account.documents) {
        if (document.isExpiringSoon) {
          expiringSoonItems.add({
            'type': document.name,
            'accountName': account.name,
            'expiryDate': document.expiryDate,
            'daysLeft': document.expiryDate.difference(now).inDays,
            'account': account,
            'document': document,
          });
        }
      }
    }

    // فحص العمال في المؤسسات
    for (final company in allCompanies) {
      for (final worker in company.workers) {
        final now = DateTime.now();

        // فحص إقامة العامل
        if (worker['expiry'] != null) {
          try {
            DateTime expiryDate;
            if (worker['expiry'] is DateTime) {
              expiryDate = worker['expiry'];
            } else if (worker['expiry'] is String) {
              expiryDate = DateTime.parse(worker['expiry']);
            } else {
              continue;
            }

            final difference = expiryDate.difference(now);
            if (difference.inDays <= 90 && difference.inDays >= 0) {
              expiringSoonItems.add({
                'type': 'إقامة',
                'accountName': '${worker['name']} - ${company.name}',
                'expiryDate': expiryDate,
                'daysLeft': difference.inDays,
                'company': company,
                'worker': worker,
              });
            }
          } catch (e) {
            // تجاهل التواريخ غير الصحيحة
          }
        }

        // فحص الوثائق الإضافية للعامل
        if (worker['documents'] != null && worker['documents'] is List) {
          final workerDocs = worker['documents'] as List;
          for (final doc in workerDocs) {
            if (doc['expiryDate'] != null) {
              try {
                final expiryDate = DateTime.parse(doc['expiryDate']);
                final difference = expiryDate.difference(now);

                if (difference.inDays <= 90 && difference.inDays >= 0) {
                  expiringSoonItems.add({
                    'type': doc['name'] ?? 'وثيقة',
                    'accountName': '${worker['name']} - ${company.name}',
                    'expiryDate': expiryDate,
                    'daysLeft': difference.inDays,
                    'company': company,
                    'worker': worker,
                    'document': doc,
                  });
                }
              } catch (e) {
                // تجاهل التواريخ غير الصحيحة
              }
            }
          }
        }
      }
    }

    // ترتيب القائمة حسب الأقرب انتهاءً
    expiringSoonItems.sort(
      (a, b) => (a['daysLeft'] as int).compareTo(b['daysLeft'] as int),
    );

    return Scaffold(
      appBar: AppBar(
        title: const PageTitle('قاربت على الانتهاء', icon: Icons.warning_amber),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: expiringSoonItems.isEmpty
          ? const EmptyState(
              message: 'لا توجد وثائق قاربت على الانتهاء',
              icon: Icons.check_circle_outline,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: expiringSoonItems.length,
              itemBuilder: (context, index) {
                final item = expiringSoonItems[index];
                final daysLeft = item['daysLeft'] as int;
                final expiryDate = item['expiryDate'] as DateTime;

                // تحديد اللون حسب عدد الأيام المتبقية
                Color statusColor = Colors.green;
                IconData statusIcon = Icons.info_outline;

                if (daysLeft <= 7) {
                  statusColor = Colors.red;
                  statusIcon = Icons.dangerous;
                } else if (daysLeft <= 30) {
                  statusColor = Colors.deepOrange;
                  statusIcon = Icons.warning;
                } else if (daysLeft <= 60) {
                  statusColor = Colors.orange;
                  statusIcon = Icons.warning_amber;
                } else {
                  statusColor = Colors.blue;
                  statusIcon = Icons.schedule;
                }

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.1),
                      child: Icon(statusIcon, color: statusColor),
                    ),
                    title: Text(
                      item['accountName'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${item['type']} • ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          daysLeft == 0
                              ? 'تنتهي اليوم!'
                              : daysLeft == 1
                              ? 'تنتهي غداً'
                              : daysLeft <= 7
                              ? 'متبقي $daysLeft أيام فقط!'
                              : daysLeft <= 30
                              ? 'متبقي $daysLeft يوم'
                              : daysLeft <= 60
                              ? 'متبقي ${(daysLeft / 30).ceil()} شهر تقريباً'
                              : 'متبقي ${(daysLeft / 30).ceil()} أشهر',
                          style: TextStyle(color: statusColor, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$daysLeft',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () {
                      // الانتقال إلى تفاصيل الحساب
                      Navigator.pop(context);
                      // يمكن إضافة التنقل إلى صفحة تفاصيل الحساب هنا
                    },
                  ),
                );
              },
            ),
    );
  }
}
