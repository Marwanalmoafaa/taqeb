import 'package:flutter/material.dart';
import 'package:taqeb/models/company.dart';
import 'package:taqeb/services/database_service.dart';
import 'package:taqeb/utils/constants.dart';
import 'package:taqeb/widgets/common_widgets.dart';
import 'package:taqeb/screens/company_details.dart';

// تعريف أنواع نتائج البحث
enum SearchResultType { company, worker }

// فئة نتيجة البحث
class SearchResult {
  final SearchResultType type;
  final String title;
  final String subtitle;
  final Company company;
  final Map<String, dynamic>? workerData;

  SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.company,
    this.workerData,
  });
}

/// شاشة عرض المؤسسات
class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  List<Company> _companies = [];
  List<Company> _filteredCompanies = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearchDropdown = false;
  List<SearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // تحميل قائمة المؤسسات
  void _loadCompanies() {
    setState(() {
      _isLoading = true;
    });

    // استخدام خدمة قاعدة البيانات للحصول على المؤسسات
    _companies = DatabaseService.getAllCompanies();
    _filteredCompanies = _companies;

    setState(() {
      _isLoading = false;
    });
  }

  // البحث الفوري
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredCompanies = _companies;
        _showSearchDropdown = false;
        _searchResults = [];
      });
      return;
    }

    List<SearchResult> results = [];

    // البحث في المؤسسات
    for (var company in _companies) {
      if (company.name.toLowerCase().contains(query)) {
        results.add(
          SearchResult(
            type: SearchResultType.company,
            title: company.name,
            subtitle: 'مؤسسة',
            company: company,
          ),
        );
      }

      // البحث في العمال
      for (var worker in company.workers) {
        final workerName = worker['name']?.toString() ?? '';
        if (workerName.toLowerCase().contains(query)) {
          results.add(
            SearchResult(
              type: SearchResultType.worker,
              title: workerName,
              subtitle: 'عامل في ${company.name}',
              company: company,
              workerData: worker,
            ),
          );
        }
      }
    }

    setState(() {
      _searchResults = results.take(10).toList(); // أول 10 نتائج
      _showSearchDropdown = results.isNotEmpty;
      _filteredCompanies = _companies
          .where(
            (company) =>
                company.name.toLowerCase().contains(query) ||
                company.workers.any(
                  (worker) => (worker['name']?.toString() ?? '')
                      .toLowerCase()
                      .contains(query),
                ),
          )
          .toList();
    });
  }

  void _onSearchResultTapped(SearchResult result) {
    _searchController.clear();
    setState(() {
      _showSearchDropdown = false;
    });
    _searchFocusNode.unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailsPage(
          company: result.company,
          index: _companies.indexOf(result.company),
        ),
      ),
    ).then((_) => _loadCompanies());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PageTitle('المؤسسات', icon: Icons.business),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _loadCompanies,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Container(
            padding: const EdgeInsets.all(AppPadding.medium),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'البحث عن مؤسسة أو عامل...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                // قائمة نتائج البحث المنسدلة
                if (_showSearchDropdown) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                result.type == SearchResultType.company
                                ? AppColors.primary
                                : AppColors.accent,
                            child: Icon(
                              result.type == SearchResultType.company
                                  ? Icons.business
                                  : Icons.person,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            result.title,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            result.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                          onTap: () => _onSearchResultTapped(result),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          // محتوى الصفحة
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCompanies.isEmpty
                ? const EmptyState(
                    message:
                        'لا توجد مؤسسات حالياً\nقم بإضافة مؤسسة جديدة من القائمة',
                    icon: Icons.business,
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.medium,
                    ),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _filteredCompanies.length,
                      itemBuilder: (context, index) {
                        final company = _filteredCompanies[index];
                        return _CompanyCard(
                          company: company,
                          index: index,
                          onRefresh: _loadCompanies,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewCompanyPage()),
          );
          _loadCompanies(); // إعادة تحميل قائمة المؤسسات بعد الإضافة
        },
        icon: const Icon(Icons.add_business),
        label: const Text('إضافة مؤسسة'),
      ),
    );
  }
}

/// بطاقة عرض المؤسسة
class _CompanyCard extends StatelessWidget {
  final Company company;
  final int index;
  final VoidCallback onRefresh;

  const _CompanyCard({
    required this.company,
    required this.index,
    required this.onRefresh,
  });

  // تحديد لون رمز الشركة بناءً على اسمها
  Color _avatarColor(String name) {
    final colors = const [
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
      Color(0xFF009688),
      Color(0xFF795548),
      Color(0xFF607D8B),
      Color(0xFF3F51B5),
      Color(0xFFCDDC39),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColor(company.name);
    final firstLetter = company.name.isNotEmpty ? company.name[0] : '?';

    // حساب الإحصائيات
    final workersCount = company.workers.length;
    final expiredDocs = company.workers.where((w) {
      final expiry = w['expiry'];
      if (expiry == null) return false;
      try {
        DateTime expiryDate;
        if (expiry is DateTime) {
          expiryDate = expiry;
        } else if (expiry is String) {
          expiryDate = DateTime.parse(expiry);
        } else {
          return false;
        }
        return expiryDate.isBefore(DateTime.now());
      } catch (e) {
        return false;
      }
    }).length;

    final expiringSoon = company.workers.where((w) {
      final expiry = w['expiry'];
      if (expiry == null) return false;
      try {
        DateTime expiryDate;
        if (expiry is DateTime) {
          expiryDate = expiry;
        } else if (expiry is String) {
          expiryDate = DateTime.parse(expiry);
        } else {
          return false;
        }
        final now = DateTime.now();
        final difference = expiryDate.difference(now).inDays;
        return difference > 0 && difference <= 30;
      } catch (e) {
        return false;
      }
    }).length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CompanyDetailsPage(company: company, index: index),
            ),
          ).then((_) => onRefresh());
        },
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رمز الشركة
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: avatarColor,
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اسم الشركة
                        Text(
                          company.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // اسم المالك
                        Text(
                          'المالك: ${company.ownerId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // زر الحذف
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context: context,
                        title: 'تأكيد الحذف',
                        content: 'هل أنت متأكد من حذف هذه المؤسسة؟',
                        confirmText: 'حذف',
                        isDanger: true,
                      );

                      if (confirmed == true) {
                        await DatabaseService.archiveCompany(company);
                        onRefresh();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // الإحصائيات السريعة
              Row(
                children: [
                  // عدد العمال
                  Expanded(
                    child: _StatChip(
                      icon: Icons.people,
                      label: 'العمال',
                      value: workersCount.toString(),
                      color: avatarColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // الوثائق المنتهية
                  if (expiredDocs > 0)
                    Expanded(
                      child: _StatChip(
                        icon: Icons.error_outline,
                        label: 'منتهية',
                        value: expiredDocs.toString(),
                        color: Colors.red,
                      ),
                    ),
                  // الوثائق قاربت على الانتهاء
                  if (expiringSoon > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(
                        icon: Icons.warning_outlined,
                        label: 'قريباً',
                        value: expiringSoon.toString(),
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// كلاس إحصائية صغيرة
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
