import 'package:flutter/material.dart';
import 'package:taqeb/models/company.dart';
import 'package:taqeb/services/database_service.dart';
import 'package:taqeb/utils/constants.dart';
import 'package:taqeb/widgets/common_widgets.dart';

/// شاشة عرض المؤسسات المؤرشفة
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<Company> _archivedCompanies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchivedCompanies();
  }

  // تحميل المؤسسات المؤرشفة
  void _loadArchivedCompanies() {
    setState(() {
      _isLoading = true;
    });

    // استخدام خدمة قاعدة البيانات للحصول على المؤسسات المؤرشفة
    _archivedCompanies = DatabaseService.getAllCompanies(
      includeArchived: true,
    ).where((company) => company.isArchived).toList();

    setState(() {
      _isLoading = false;
    });
  }

  // استعادة مؤسسة من الأرشيف
  void _restoreCompany(Company company) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: 'استعادة المؤسسة',
      content: 'هل أنت متأكد من استعادة مؤسسة "${company.name}" من الأرشيف؟',
      confirmText: 'استعادة',
    );

    if (confirm == true) {
      company.isArchived = false;
      await DatabaseService.updateCompany(company);
      _loadArchivedCompanies();

      if (mounted) {
        showSnackMessage(context, 'تم استعادة المؤسسة بنجاح');
      }
    }
  }

  // حذف مؤسسة نهائياً
  void _deleteCompany(Company company) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: 'حذف نهائي',
      content:
          'هل أنت متأكد من حذف مؤسسة "${company.name}" بشكل نهائي؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmText: 'حذف نهائي',
      isDanger: true,
    );

    if (confirm == true) {
      await DatabaseService.deleteCompany(company);
      _loadArchivedCompanies();

      if (mounted) {
        showSnackMessage(context, 'تم حذف المؤسسة نهائياً');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PageTitle('الأرشيف', icon: Icons.archive),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // زر تحديث القائمة
          IconButton(
            onPressed: _loadArchivedCompanies,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _archivedCompanies.isEmpty
          ? const EmptyState(
              message: 'لا توجد مؤسسات في الأرشيف',
              icon: Icons.archive_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _archivedCompanies.length,
              itemBuilder: (context, index) {
                final company = _archivedCompanies[index];
                return _ArchivedCompanyCard(
                  company: company,
                  onRestore: () => _restoreCompany(company),
                  onDelete: () => _deleteCompany(company),
                );
              },
            ),
    );
  }
}

/// بطاقة عرض المؤسسة المؤرشفة
class _ArchivedCompanyCard extends StatelessWidget {
  final Company company;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _ArchivedCompanyCard({
    required this.company,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final firstLetter = company.name.isNotEmpty ? company.name[0] : '?';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رمز المؤسسة
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey,
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // معلومات المؤسسة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // اسم المؤسسة
                          Expanded(
                            child: Text(
                              company.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          // شارة الأرشيف
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'مؤرشف',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // المالك
                      Text(
                        'المالك: ${company.ownerId}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // رقم الجوال
                      Text(
                        'الجوال: ${company.ownerPhone}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // أزرار الإجراءات
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // زر الاستعادة
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore),
                    label: const Text('استعادة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // زر الحذف النهائي
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('حذف نهائي'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
