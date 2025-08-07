import 'package:flutter/material.dart';
import 'package:taqeb/models/account.dart';
import 'package:taqeb/services/database_service.dart';
import 'package:taqeb/utils/constants.dart';
import 'package:taqeb/widgets/common_widgets.dart';

/// شاشة عرض وإدارة الحسابات
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<AccountModel> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  // تحميل الحسابات
  void _loadAccounts() {
    setState(() {
      _isLoading = true;
    });

    // استخدام خدمة قاعدة البيانات للحصول على الحسابات
    _accounts =
        DatabaseService.getAllAccounts(); // تحويل الحسابات القديمة التي لا تحتوي على items
    bool hasOldAccounts = false;
    for (final account in _accounts) {
      if (account.items.isEmpty) {
        hasOldAccounts = true;
        // إنشاء items افتراضي للحسابات القديمة
        account.items = [
          {
            'taskType': '', // نوع المهمة فارغ للحسابات القديمة
            'requiredAmount': account.totalDue,
            'receivedAmount': account.totalPaid,
            'dueDate': account.dueDate,
          },
        ];

        // إذا لم يكن للحساب تاريخ آخر تعديل، نضع التاريخ الحالي
        try {
          // التحقق من وجود خاصية lastModified
          account.lastModified;
        } catch (e) {
          account.lastModified = DateTime.now();
        }
      }
    }

    // حفظ التحويلات إذا وجدت حسابات قديمة
    if (hasOldAccounts) {
      for (final account in _accounts) {
        if (account.items.length == 1 &&
            account.items.first['taskType'] == '') {
          // تحديث تاريخ آخر تعديل عند تحويل الحسابات القديمة
          account.lastModified = DateTime.now();
          DatabaseService.updateAccount(account);
        }
      }
    }

    // ترتيب الحسابات حسب الأحدث (آخر تعديل أولاً)
    _accounts.sort((a, b) => b.lastModified.compareTo(a.lastModified));

    setState(() {
      _isLoading = false;
    });
  }

  // إضافة حساب جديد
  void _addNewAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AccountFormPage()),
    ).then((_) => _loadAccounts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PageTitle('الحسابات', icon: Icons.account_balance_wallet),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // زر تحديث القائمة
          IconButton(
            onPressed: _loadAccounts,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 16),
        ],
      ),
      // زر إضافة حساب جديد
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewAccount,
        icon: const Icon(Icons.add),
        label: const Text('حساب جديد'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
          ? const EmptyState(
              message: 'لا توجد حسابات حالياً\nقم بإضافة حساب جديد',
              icon: Icons.account_balance_wallet_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                return _AccountCard(
                  account: account,
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AccountFormPage(accountToEdit: account),
                      ),
                    ).then((_) => _loadAccounts());
                  },
                  onDelete: () async {
                    final confirmed = await showConfirmDialog(
                      context: context,
                      title: 'تأكيد الحذف',
                      content: 'هل أنت متأكد من حذف هذا الحساب؟',
                      confirmText: 'حذف',
                      isDanger: true,
                    );

                    if (confirmed == true) {
                      await DatabaseService.deleteAccount(account);
                      _loadAccounts();
                    }
                  },
                );
              },
            ),
    );
  }
}

/// بطاقة عرض الحساب
class _AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.onEdit,
    required this.onDelete,
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

  // دالة مساعدة لبناء معلومات المبلغ مع التسمية
  Widget _buildLabeledAmount(String label, String amount, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          amount,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final duePercentage = account.totalDue > 0
        ? (account.totalPaid / account.totalDue * 100).clamp(0, 100)
        : 0.0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // السطر الأول: الأيقونة، الاسم، المعلومات المالية، زر الحذف
              Row(
                children: [
                  // أيقونة الحساب
                  Icon(
                    Icons.account_balance_wallet,
                    color: statusColor,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  // معلومات الحساب
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    ),
                  ),
                  // المعلومات المالية في الوسط
                  Row(
                    children: [
                      _buildLabeledAmount(
                        'الإجمالي',
                        '${account.totalDue.toStringAsFixed(0)}',
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      Container(height: 30, width: 1, color: Colors.grey[300]),
                      const SizedBox(width: 12),
                      _buildLabeledAmount(
                        'المسدد',
                        '${account.totalPaid.toStringAsFixed(0)}',
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Container(height: 30, width: 1, color: Colors.grey[300]),
                      const SizedBox(width: 12),
                      _buildLabeledAmount(
                        'المتبقي',
                        '${account.remaining.toStringAsFixed(0)}',
                        account.remaining > 0 ? Colors.red : Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // زر الحذف
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    iconSize: 22,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // شريط التقدم
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: duePercentage / 100,
                        backgroundColor: Colors.grey[200],
                        color: duePercentage >= 100
                            ? Colors.green
                            : Colors.blue,
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${duePercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: duePercentage >= 100 ? Colors.green : Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صفحة إضافة/تعديل حساب
class AccountFormPage extends StatefulWidget {
  final AccountModel? accountToEdit;

  const AccountFormPage({super.key, this.accountToEdit});

  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  // قوائم البحث
  List<String> _availableNames = [];
  List<String> _filteredNames = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableNames();
    _initializeFormData();
  }

  // تهيئة بيانات النموذج
  void _initializeFormData() {
    if (widget.accountToEdit != null) {
      // ملء الحقول مع البيانات الموجودة
      _nameController.text = widget.accountToEdit!.name;

      // تحويل الحسابات القديمة التي لا تحتوي على items
      if (widget.accountToEdit!.items.isEmpty) {
        // إنشاء عنصر افتراضي من البيانات الأساسية للحسابات القديمة
        _items = [
          {
            'taskType': '', // نوع المهمة فارغ للحسابات القديمة
            'requiredAmount': widget.accountToEdit!.totalDue,
            'receivedAmount': widget.accountToEdit!.totalPaid,
            'dueDate': widget.accountToEdit!.dueDate,
          },
        ];

        // حفظ التحويل في قاعدة البيانات
        widget.accountToEdit!.items = _items;
        DatabaseService.updateAccount(widget.accountToEdit!);
      } else {
        // نسخ البيانات من الحساب الموجود (الحسابات الجديدة)
        _items = widget.accountToEdit!.items
            .map(
              (item) => {
                'taskType': item['taskType']?.toString() ?? '',
                'requiredAmount': (item['requiredAmount'] is num)
                    ? (item['requiredAmount'] as num).toDouble()
                    : 0.0,
                'receivedAmount': (item['receivedAmount'] is num)
                    ? (item['receivedAmount'] as num).toDouble()
                    : 0.0,
                'dueDate': item['dueDate'] is DateTime
                    ? item['dueDate'] as DateTime
                    : (item['dueDate'] is String
                          ? DateTime.tryParse(item['dueDate']) ?? DateTime.now()
                          : DateTime.now()),
              },
            )
            .toList();
      }

      // تحديث الحالة لإعادة الرسم مع البيانات الجديدة
      setState(() {});
    } else {
      // حساب جديد - إضافة صف فارغ
      _addNewItem();
    }
  }

  // تحميل أسماء المؤسسات والعمال المتاحة
  void _loadAvailableNames() {
    final companies = DatabaseService.getAllCompanies();
    final names = <String>{};

    // إضافة أسماء المؤسسات
    for (final company in companies) {
      names.add(company.name);

      // إضافة أسماء العمال
      for (final worker in company.workers) {
        final workerName = worker['name']?.toString();
        if (workerName != null && workerName.isNotEmpty) {
          names.add(workerName);
        }
      }
    }

    setState(() {
      _availableNames = names.toList()..sort();
      _filteredNames = _availableNames;
    });
  }

  // تصفية أسماء البحث
  void _filterNames(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNames = _availableNames;
        _showSuggestions = false;
      } else {
        _filteredNames = _availableNames
            .where((name) => name.contains(query))
            .toList();
        _showSuggestions = true;
      }
    });
  }

  // إضافة عنصر جديد للجدول
  void _addNewItem() {
    setState(() {
      _items.add({
        'taskType': '',
        'requiredAmount': 0.0,
        'receivedAmount': 0.0,
        'dueDate': DateTime.now().add(const Duration(days: 30)),
      });
    });
  }

  // حذف عنصر من الجدول
  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  // حساب المجاميع
  double get _totalRequired =>
      _items.fold(0.0, (sum, item) => sum + (item['requiredAmount'] ?? 0.0));
  double get _totalReceived =>
      _items.fold(0.0, (sum, item) => sum + (item['receivedAmount'] ?? 0.0));
  double get _totalRemaining => _totalRequired - _totalReceived;

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // حفظ الحساب
  void _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      showSnackMessage(context, 'يجب إضافة عنصر واحد على الأقل', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();

      if (widget.accountToEdit == null) {
        // إضافة حساب جديد
        final newAccount = AccountModel(
          name: name,
          totalDue: _totalRequired,
          totalPaid: _totalReceived,
          dueDate: _items.isNotEmpty ? _items.first['dueDate'] : DateTime.now(),
          items: _items,
          lastModified: DateTime.now(), // تعيين تاريخ الإنشاء
        );

        await DatabaseService.addAccount(newAccount);
        if (mounted) {
          showSnackMessage(context, 'تم إضافة الحساب بنجاح');
          Navigator.pop(context);
        }
      } else {
        // تحديث الحساب الموجود
        widget.accountToEdit!.name = name;
        widget.accountToEdit!.totalDue = _totalRequired;
        widget.accountToEdit!.totalPaid = _totalReceived;
        widget.accountToEdit!.dueDate = _items.isNotEmpty
            ? _items.first['dueDate']
            : DateTime.now();
        widget.accountToEdit!.items = _items;
        widget.accountToEdit!.lastModified =
            DateTime.now(); // تحديث تاريخ آخر تعديل

        await DatabaseService.updateAccount(widget.accountToEdit!);
        if (mounted) {
          showSnackMessage(context, 'تم تحديث الحساب بنجاح');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackMessage(context, 'حدث خطأ: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.accountToEdit != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: PageTitle(
            isEditing ? 'تعديل حساب' : 'إضافة حساب جديد',
            icon: Icons.account_balance_wallet,
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // بحث اسم صاحب الحساب
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اسم صاحب الحساب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'ابحث عن اسم صاحب الحساب (مؤسسة أو عامل)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'هذا الحقل مطلوب';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _filterNames(value);
                    },
                  ),
                  // قائمة الاقتراحات
                  if (_showSuggestions && _filteredNames.isNotEmpty)
                    Container(
                      height: 150,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).cardColor,
                      ),
                      child: ListView.builder(
                        itemCount: _filteredNames.length,
                        itemBuilder: (context, index) {
                          final name = _filteredNames[index];
                          return ListTile(
                            title: Text(
                              name,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
                            onTap: () {
                              _nameController.text = name;
                              setState(() {
                                _showSuggestions = false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // جدول بيانات الحساب
              const Text(
                'بيانات الحساب',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 16),

              // رأس الجدول
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'نوع المهمة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'المبلغ المطلوب',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'المبلغ المستلم',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'المبلغ المتبقي',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'تاريخ الاستحقاق',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 48), // مساحة لزر الحذف
                  ],
                ),
              ),

              // صفوف الجدول
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final remaining =
                    (item['requiredAmount'] ?? 0.0) -
                    (item['receivedAmount'] ?? 0.0);

                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey[300]!),
                      right: BorderSide(color: Colors.grey[300]!),
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                    color: index % 2 == 0
                        ? Theme.of(context).cardColor
                        : Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      // نوع المهمة
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: item['taskType']?.toString() ?? '',
                          decoration: const InputDecoration(
                            hintText: 'نوع المهمة',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _items[index]['taskType'] = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // المبلغ المطلوب
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          initialValue:
                              item['requiredAmount'] != null &&
                                  item['requiredAmount'] != 0.0
                              ? item['requiredAmount'].toString()
                              : '',
                          decoration: const InputDecoration(
                            hintText: '0',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _items[index]['requiredAmount'] =
                                  double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // المبلغ المستلم
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          initialValue:
                              item['receivedAmount'] != null &&
                                  item['receivedAmount'] != 0.0
                              ? item['receivedAmount'].toString()
                              : '',
                          decoration: const InputDecoration(
                            hintText: '0',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _items[index]['receivedAmount'] =
                                  double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // المبلغ المتبقي (للقراءة فقط)
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]
                                : Colors.grey[100],
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            remaining.toStringAsFixed(0),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: remaining > 0
                                  ? Colors.red
                                  : remaining < 0
                                  ? Colors.orange
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // تاريخ الاستحقاق
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: item['dueDate'] ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 2),
                              ),
                              builder: (context, child) {
                                return Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: child!,
                                );
                              },
                            );

                            if (date != null) {
                              setState(() {
                                _items[index]['dueDate'] = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${item['dueDate']?.day ?? DateTime.now().day}/${item['dueDate']?.month ?? DateTime.now().month}/${item['dueDate']?.year ?? DateTime.now().year}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // زر الحذف
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: _items.length > 1
                            ? () => _removeItem(index)
                            : null,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // زر إضافة المزيد
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: _addNewItem,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة المزيد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // عرض المجاميع
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'إجمالي المطلوب',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_totalRequired.toStringAsFixed(0)} ريال',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[400],
                        ),
                        Column(
                          children: [
                            const Text(
                              'إجمالي المستلم',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_totalReceived.toStringAsFixed(0)} ريال',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[400],
                        ),
                        Column(
                          children: [
                            const Text(
                              'إجمالي المتبقي',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_totalRemaining.toStringAsFixed(0)} ريال',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _totalRemaining > 0
                                    ? Colors.red
                                    : _totalRemaining < 0
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // أزرار الإجراءات
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      label: isEditing ? 'حفظ التغييرات' : 'إضافة الحساب',
                      icon: isEditing ? Icons.save : Icons.add,
                      onPressed: _saveAccount,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
