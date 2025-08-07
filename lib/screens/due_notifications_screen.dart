import 'package:flutter/material.dart';
import 'package:taqeb/models/account.dart';
import 'package:taqeb/services/database_service.dart';
import 'package:taqeb/utils/constants.dart';
import 'package:taqeb/widgets/common_widgets.dart';
import 'package:taqeb/screens/accounts_screen.dart';
import 'package:taqeb/screens/company_details.dart';

/// شاشة عرض الإشعارات والتنبيهات للتواريخ المهمة
class DueNotificationsScreen extends StatefulWidget {
  const DueNotificationsScreen({super.key});

  @override
  State<DueNotificationsScreen> createState() => _DueNotificationsScreenState();
}

class _DueNotificationsScreenState extends State<DueNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AccountModel> _dueAccounts = [];
  List<AccountModel> _allDueAccounts = []; // جميع الحسابات المديونة قبل الفلترة
  List<Map<String, dynamic>> _dueDocuments = [];
  List<Map<String, dynamic>> _allDueDocuments = []; // جميع الوثائق قبل الفلترة
  bool _isLoading = true;

  // فلاتر الفترات الزمنية
  int _selectedFilter = -1; // -1 يعني عرض الكل، بدون فلترة

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // تحديث النص عند تغيير التبويب
    });
    _loadDueItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // تحميل العناصر المستحقة
  void _loadDueItems() {
    setState(() {
      _isLoading = true;
    });

    // جلب جميع الحسابات من نفس مصدر الحسابات الرئيسية
    final allAccounts = DatabaseService.getAllAccounts();

    // فلترة الحسابات لإظهار المديونة فقط (التي بها مبلغ متبقي > 0)
    _allDueAccounts = allAccounts
        .where((account) => account.remaining > 0)
        .toList();

    // ترتيب الحسابات المديونة حسب المبلغ المتبقي (الأعلى أولاً)
    _allDueAccounts.sort((a, b) => b.remaining.compareTo(a.remaining));

    // استخراج وثائق الشركات التي ستنتهي قريبًا
    _allDueDocuments = _extractDueCompanyDocuments();
    _applyFilter();

    setState(() {
      _isLoading = false;
    });
  }

  // تطبيق الفلتر المحدد
  void _applyFilter() {
    // فلترة الوثائق بناءً على عدد الأيام
    if (_selectedFilter == -1) {
      // عرض جميع الوثائق
      _dueDocuments = _allDueDocuments;
    } else {
      _dueDocuments = _allDueDocuments.where((doc) {
        final daysLeft = doc['daysLeft'] as int;
        return daysLeft <= _selectedFilter;
      }).toList();
    }

    // فلترة الحسابات بناءً على تاريخ الاستحقاق
    if (_selectedFilter == -1) {
      // عرض جميع الحسابات المديونة
      _dueAccounts = List.from(_allDueAccounts);
    } else {
      final now = DateTime.now();
      _dueAccounts = _allDueAccounts.where((account) {
        final daysLeft = account.dueDate.difference(now).inDays;
        return daysLeft <= _selectedFilter;
      }).toList();
    }
  }

  // تغيير الفلتر
  void _changeFilter(int newFilter) {
    setState(() {
      _selectedFilter = newFilter;
      _applyFilter();
    });
  }

  // استخراج وثائق الشركات التي ستنتهي قريبًا
  List<Map<String, dynamic>> _extractDueCompanyDocuments() {
    final List<Map<String, dynamic>> dueItems = [];
    final companies = DatabaseService.getAllCompanies();
    final now = DateTime.now();
    const maxDaysThreshold = 90; // أقصى فترة للعرض (3 أشهر)

    for (final company in companies) {
      // فحص وثائق المؤسسة (السجل التجاري، الرخص، إلخ)
      for (final doc in company.companyData) {
        if (doc['expiry'] != null && doc['expiry'].toString().isNotEmpty) {
          try {
            final expiry = DateTime.parse(doc['expiry'].toString());
            final daysLeft = expiry.difference(now).inDays;

            if (daysLeft >= 0 && daysLeft <= maxDaysThreshold) {
              String docType = 'وثيقة';
              IconData docIcon = Icons.assignment;

              // تحديد نوع الوثيقة والأيقونة
              final docName = (doc['name'] ?? '').toString().toLowerCase();
              if (docName.contains('سجل') || docName.contains('تجاري')) {
                docType = 'السجل التجاري';
                docIcon = Icons.business;
              } else if (docName.contains('رخصة') ||
                  docName.contains('ترخيص')) {
                docType = 'رخصة';
                docIcon = Icons.verified_user;
              } else if (docName.contains('شهادة')) {
                docType = 'شهادة';
                docIcon = Icons.school;
              } else if (docName.contains('تأمين')) {
                docType = 'تأمين';
                docIcon = Icons.security;
              }

              dueItems.add({
                'type': 'company_document',
                'name': doc['name'] ?? 'وثيقة غير محددة',
                'number': doc['number'] ?? 'غير محدد',
                'expiry': expiry,
                'daysLeft': daysLeft,
                'company': company.name,
                'companyKey': company.key,
                'docType': docType,
                'icon': docIcon,
                'category': 'company',
              });
            }
          } catch (e) {
            // تجاهل التواريخ غير الصالحة
          }
        }
      }

      // فحص وثائق العمال (الإقامات، الجوازات، رخص العمل)
      for (final worker in company.workers) {
        // فحص تاريخ انتهاء الإقامة
        if (worker['expiry'] != null &&
            worker['expiry'].toString().isNotEmpty) {
          try {
            final expiry = DateTime.parse(worker['expiry'].toString());
            final daysLeft = expiry.difference(now).inDays;

            if (daysLeft >= 0 && daysLeft <= maxDaysThreshold) {
              dueItems.add({
                'type': 'worker_iqama',
                'name': worker['name'] ?? 'عامل غير محدد',
                'number': worker['iqama'] ?? 'غير محدد',
                'expiry': expiry,
                'daysLeft': daysLeft,
                'company': company.name,
                'companyKey': company.key,
                'workerPhone': worker['phone'] ?? '',
                'docType': 'إقامة',
                'icon': Icons.credit_card,
                'category': 'worker',
              });
            }
          } catch (e) {
            // تجاهل التواريخ غير الصالحة
          }
        }

        // فحص وثائق إضافية للعمال
        if (worker['documents'] != null && worker['documents'] is List) {
          for (final doc in worker['documents']) {
            if (doc['expiry'] != null && doc['expiry'].toString().isNotEmpty) {
              try {
                final expiry = DateTime.parse(doc['expiry'].toString());
                final daysLeft = expiry.difference(now).inDays;

                if (daysLeft >= 0 && daysLeft <= maxDaysThreshold) {
                  dueItems.add({
                    'type': 'worker_document',
                    'name':
                        '${worker['name'] ?? 'عامل غير محدد'} - ${doc['name'] ?? 'وثيقة'}',
                    'number': doc['number'] ?? 'غير محدد',
                    'expiry': expiry,
                    'daysLeft': daysLeft,
                    'company': company.name,
                    'companyKey': company.key,
                    'workerPhone': worker['phone'] ?? '',
                    'docType': doc['name'] ?? 'وثيقة عامل',
                    'icon': Icons.description,
                    'category': 'worker',
                  });
                }
              } catch (e) {
                // تجاهل التواريخ غير الصالحة
              }
            }
          }
        }
      }
    }

    // ترتيب العناصر حسب عدد الأيام المتبقية
    dueItems.sort((a, b) => a['daysLeft'].compareTo(b['daysLeft']));

    return dueItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PageTitle('قاربت على الانتهاء', icon: Icons.warning),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // زر تحديث القائمة
          IconButton(
            onPressed: _loadDueItems,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          tabs: const [
            Tab(text: 'الوثائق', icon: Icon(Icons.assignment)),
            Tab(text: 'الحسابات', icon: Icon(Icons.account_balance_wallet)),
          ],
        ),
      ),
      body: Column(
        children: [
          // أزرار الفلترة
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilterRow(
                  selectedFilter: _selectedFilter,
                  onFilterChanged: _changeFilter,
                ),
                const SizedBox(height: 8),
                // عرض عدد النتائج حسب التبويب النشط
                Text(
                  _tabController.index == 0
                      ? (_selectedFilter == -1
                            ? 'إجمالي الوثائق: ${_dueDocuments.length}'
                            : 'الوثائق (${_selectedFilter} يوم): ${_dueDocuments.length}')
                      : (_selectedFilter == -1
                            ? 'إجمالي الحسابات المديونة: ${_dueAccounts.length}'
                            : 'الحسابات المديونة (${_selectedFilter} يوم): ${_dueAccounts.length}'),
                  style: TextStyle(fontSize: 14, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          // محتوى التبويبات
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // قائمة الوثائق
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _dueDocuments.isEmpty
                    ? EmptyState(
                        message: _selectedFilter == -1
                            ? 'لا توجد وثائق قاربت على الانتهاء'
                            : 'لا توجد وثائق تنتهي خلال هذه الفترة',
                        icon: Icons.check_circle,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _dueDocuments.length,
                        itemBuilder: (context, index) {
                          final document = _dueDocuments[index];
                          return _DocumentExpiryCard(document: document);
                        },
                      ),

                // قائمة الحسابات
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _dueAccounts.isEmpty
                    ? EmptyState(
                        message: _selectedFilter == -1
                            ? 'لا توجد حسابات مديونة\nجميع الحسابات مسددة بالكامل'
                            : 'لا توجد حسابات مديونة تستحق خلال هذه الفترة\nقم بتغيير الفلتر لعرض المزيد',
                        icon: Icons.check_circle,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _dueAccounts.length,
                        itemBuilder: (context, index) {
                          final account = _dueAccounts[index];
                          return CompactAccountCard(
                            account: account,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AccountFormPage(accountToEdit: account),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة عرض وثيقة قاربت على الانتهاء
class _DocumentExpiryCard extends StatelessWidget {
  final Map<String, dynamic> document;

  const _DocumentExpiryCard({required this.document});

  // تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final category = document['category'] ?? 'document';
    final isWorkerDoc = category == 'worker';
    final icon =
        document['icon'] ?? (isWorkerDoc ? Icons.person : Icons.assignment);
    final daysLeft = document['daysLeft'] as int;
    final expiryDate = document['expiry'] as DateTime;

    return StatusCard(
      title: document['name'],
      subtitle: isWorkerDoc
          ? 'رقم الإقامة: ${document['number']} • ينتهي: ${_formatDate(expiryDate)}'
          : '${document['docType']}: ${document['number']} • ينتهي: ${_formatDate(expiryDate)}',
      value: 'تابع لـ: ${document['company']}',
      daysLeft: daysLeft,
      icon: icon,
      onTap: () {
        // فتح صفحة المؤسسة عند الضغط على الوثيقة
        _openCompanyDetails(context);
      },
    );
  }

  // فتح صفحة تفاصيل المؤسسة
  void _openCompanyDetails(BuildContext context) {
    final companyKey = document['companyKey'];
    if (companyKey != null) {
      // البحث عن المؤسسة بالمفتاح
      final companies = DatabaseService.getAllCompanies();
      final companyIndex = companies.indexWhere((c) => c.key == companyKey);

      if (companyIndex != -1) {
        final company = companies[companyIndex];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CompanyDetailsPage(company: company, index: companyIndex),
          ),
        );
      }
    }
  }
}
