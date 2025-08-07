import 'package:flutter/material.dart';
import 'package:taqeb/models/transaction.dart';
import 'package:taqeb/models/company.dart';
import 'package:taqeb/services/database_service.dart';
import 'package:taqeb/screens/due_notifications_screen.dart';
import 'package:taqeb/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _search = '';
  List<TransactionModel> _transactions = [];
  List<Company> _companies = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _transactions = DatabaseService.getAllTransactions();
      _companies = DatabaseService.getAllCompanies();
    });
  }

  List<TransactionModel> get _filteredTransactions {
    if (_search.isEmpty) return _transactions;
    return _transactions.where((t) {
      // البحث في اسم المؤسسة أو اسم العامل داخل نص المعاملة
      final content = t.content;
      final companyMatch = _companies.any((c) => c.name.contains(_search));
      // البحث في أسماء العمال
      final workerMatch = _companies.any(
        (c) => c.workers.any(
          (w) => (w['name'] ?? '').toString().contains(_search),
        ),
      );
      return content.contains(_search) || companyMatch || workerMatch;
    }).toList();
  }

  void _editTransaction(TransactionModel tx) async {
    // منطق التعديل (يمكن فتح صفحة تعديل)
  }

  Widget _buildExpiringPreview() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_bottom, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'قاربت على الانتهاء',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DueNotificationsScreen(),
                    ),
                  );
                },
                child: const Text('عرض التفاصيل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: 4, // عرض 4 عناصر فقط كمعاينة
              itemBuilder: (context, index) {
                final items = [
                  {'title': 'رخصة الشركة أ', 'days': '7'},
                  {'title': 'إقامة العامل محمد', 'days': '14'},
                  {'title': 'السجل التجاري', 'days': '21'},
                  {'title': 'شهادة الجودة', 'days': '30'},
                ];
                final item = items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '${item['days']} يوم',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // قائمة المعاملات
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'بحث باسم المؤسسة أو العامل...',
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: 'بحث',
                      onPressed: () => setState(() {}),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'تحديث البيانات',
                      onPressed: _loadData,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? const Center(child: Text('لا توجد معاملات'))
                      : ListView.separated(
                          itemCount: _filteredTransactions.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) {
                            final tx = _filteredTransactions[i];
                            return Card(
                              child: ListTile(
                                title: const Text('المعاملة'),
                                subtitle: Text(tx.content),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editTransaction(tx),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        // عرض معاينة الوثائق قاربت على الانتهاء
        Expanded(
          flex: 1,
          child: Container(
            color: AppColors.lightGrey.withOpacity(0.2),
            child: _buildExpiringPreview(),
          ),
        ),
      ],
    );
  }
}
