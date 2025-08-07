import 'package:flutter/material.dart';
import 'package:taqeb/services/database_service.dart';
import 'package:taqeb/models/company.dart';
import 'package:taqeb/models/transaction.dart';
import 'package:taqeb/utils/constants.dart';
import 'package:taqeb/widgets/common_widgets.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Company> companies = [];
  List<TransactionModel> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      isLoading = true;
    });

    companies = DatabaseService.getAllCompanies();
    transactions = DatabaseService.getAllTransactions();

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PageTitle('الإحصائيات', icon: Icons.bar_chart),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // إحصائيات عامة
                  _buildGeneralStats(),
                  const SizedBox(height: 20),

                  // إحصائيات المؤسسات
                  _buildCompaniesStats(),
                  const SizedBox(height: 20),

                  // إحصائيات الوثائق
                  _buildDocumentsStats(),
                ],
              ),
            ),
    );
  }

  Widget _buildGeneralStats() {
    final totalCompanies = companies.length;
    final totalWorkers = companies.fold(
      0,
      (sum, company) => sum + company.workers.length,
    );
    final totalTransactions = transactions.length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الإحصائيات العامة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'المؤسسات',
                    value: totalCompanies.toString(),
                    icon: Icons.business,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'العمال',
                    value: totalWorkers.toString(),
                    icon: Icons.people,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'المعاملات',
                    value: totalTransactions.toString(),
                    icon: Icons.receipt,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompaniesStats() {
    final companiesWithWorkers = companies
        .where((c) => c.workers.isNotEmpty)
        .length;
    final companiesWithoutWorkers = companies.length - companiesWithWorkers;
    final avgWorkersPerCompany = companies.isEmpty
        ? 0.0
        : companies.fold(0, (sum, c) => sum + c.workers.length) /
              companies.length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات المؤسسات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'مؤسسات لديها عمال',
              companiesWithWorkers.toString(),
              Icons.business,
            ),
            _buildStatRow(
              'مؤسسات بدون عمال',
              companiesWithoutWorkers.toString(),
              Icons.business_outlined,
            ),
            _buildStatRow(
              'متوسط العمال لكل مؤسسة',
              avgWorkersPerCompany.toStringAsFixed(1),
              Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsStats() {
    int expiredDocs = 0;
    int expiringSoon = 0;
    int validDocs = 0;
    int totalAdditionalDocs = 0;

    for (var company in companies) {
      for (var worker in company.workers) {
        // فحص الإقامة الأساسية
        final expiry = worker['expiry'];
        if (expiry != null) {
          try {
            DateTime expiryDate;
            if (expiry is DateTime) {
              expiryDate = expiry;
            } else if (expiry is String) {
              expiryDate = DateTime.parse(expiry);
            } else {
              continue;
            }
            final now = DateTime.now();
            final difference = expiryDate.difference(now).inDays;

            if (difference < 0) {
              expiredDocs++;
            } else if (difference <= 30) {
              expiringSoon++;
            } else {
              validDocs++;
            }
          } catch (e) {
            // تجاهل التواريخ غير الصحيحة
          }
        }
      }
    }

    // فحص الوثائق الإضافية من حسابات العمال
    final accounts = DatabaseService.getAllAccounts();
    for (var account in accounts) {
      for (var document in account.documents) {
        totalAdditionalDocs++;
        if (document.isExpired) {
          expiredDocs++;
        } else if (document.isExpiringSoon) {
          expiringSoon++;
        } else {
          validDocs++;
        }
      }
    }

    // فحص الوثائق الإضافية للعمال في المؤسسات
    for (var company in companies) {
      for (var worker in company.workers) {
        if (worker['documents'] != null && worker['documents'] is List) {
          final workerDocs = worker['documents'] as List;
          for (var doc in workerDocs) {
            if (doc['expiryDate'] != null) {
              try {
                totalAdditionalDocs++;
                final expiryDate = DateTime.parse(doc['expiryDate']);
                final difference = expiryDate.difference(DateTime.now()).inDays;

                if (difference < 0) {
                  expiredDocs++;
                } else if (difference <= 30) {
                  expiringSoon++;
                } else {
                  validDocs++;
                }
              } catch (e) {
                // تجاهل التواريخ غير الصحيحة
              }
            }
          }
        }
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات الوثائق',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'إجمالي الوثائق الإضافية',
              totalAdditionalDocs.toString(),
              Icons.description,
              color: AppColors.primary,
            ),
            _buildStatRow(
              'وثائق منتهية الصلاحية',
              expiredDocs.toString(),
              Icons.error,
              color: Colors.red,
            ),
            _buildStatRow(
              'وثائق تنتهي قريباً (30 يوم)',
              expiringSoon.toString(),
              Icons.warning,
              color: Colors.orange,
            ),
            _buildStatRow(
              'وثائق سارية المفعول',
              validDocs.toString(),
              Icons.check_circle,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
