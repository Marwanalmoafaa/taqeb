import 'package:flutter/material.dart';
import 'package:taqeb/models/account.dart';
import 'package:taqeb/services/database_service.dart';
import 'package:taqeb/utils/constants.dart';
import 'package:taqeb/widgets/common_widgets.dart';

/// نموذج إضافة/تعديل الحسابات
class AccountFormPage extends StatefulWidget {
  final AccountModel? accountToEdit;

  const AccountFormPage({super.key, this.accountToEdit});

  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _totalDueController = TextEditingController();
  final TextEditingController _totalPaidController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  List<Map<String, dynamic>> _items = [];
  List<Document> _documents = []; // قائمة الوثائق الإضافية
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.accountToEdit != null) {
      _nameController.text = widget.accountToEdit!.name;
      _totalDueController.text = widget.accountToEdit!.totalDue.toString();
      _totalPaidController.text = widget.accountToEdit!.totalPaid.toString();
      _dueDate = widget.accountToEdit!.dueDate;
      _items = List<Map<String, dynamic>>.from(widget.accountToEdit!.items);
      _documents = List<Document>.from(widget.accountToEdit!.documents);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalDueController.dispose();
    _totalPaidController.dispose();
    super.dispose();
  }

  // حفظ الحساب
  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final name = _nameController.text.trim();
      final totalDue = double.tryParse(_totalDueController.text) ?? 0;
      final totalPaid = double.tryParse(_totalPaidController.text) ?? 0;

      if (widget.accountToEdit == null) {
        // إضافة حساب جديد
        final newAccount = AccountModel(
          name: name,
          totalDue: totalDue,
          totalPaid: totalPaid,
          dueDate: _dueDate,
          items: _items,
          documents: _documents,
        );

        await DatabaseService.addAccount(newAccount);
        if (mounted) {
          showSnackMessage(context, 'تم إضافة الحساب بنجاح');
          Navigator.pop(context);
        }
      } else {
        // تحديث الحساب الموجود
        widget.accountToEdit!.name = name;
        widget.accountToEdit!.totalDue = totalDue;
        widget.accountToEdit!.totalPaid = totalPaid;
        widget.accountToEdit!.dueDate = _dueDate;
        widget.accountToEdit!.items = _items;
        widget.accountToEdit!.documents = _documents;

        await DatabaseService.updateAccount(widget.accountToEdit!);
        if (mounted) {
          showSnackMessage(context, 'تم تحديث الحساب بنجاح');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackMessage(context, 'حدث خطأ أثناء حفظ البيانات', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // إضافة عنصر جديد
  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => const _AddItemDialog(),
    ).then((newItem) {
      if (newItem != null) {
        setState(() {
          _items.add(newItem);
        });
      }
    });
  }

  // حذف عنصر
  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  // إضافة وثيقة جديدة
  void _addDocument() {
    showDialog(
      context: context,
      builder: (context) => _AddDocumentDialog(
        onAdd: (document) {
          setState(() {
            _documents.add(document);
          });
        },
      ),
    );
  }

  // حذف وثيقة
  void _deleteDocument(int index) {
    setState(() {
      _documents.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.accountToEdit != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: PageTitle(
            isEditing ? 'تعديل الحساب' : 'حساب جديد',
            icon: Icons.account_balance_wallet,
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بيانات الحساب الأساسية
                  SectionCard(
                    title: 'بيانات الحساب',
                    icon: Icons.description,
                    child: _accountDetailsForm(),
                  ),

                  const SizedBox(height: 24),

                  // عناصر الحساب
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.medium,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // عنوان القسم
                          Row(
                            children: [
                              const Icon(
                                Icons.list_alt,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'عناصر الحساب',
                                style: AppTextStyles.sectionTitle,
                              ),
                              const Spacer(),
                              ActionButton(
                                label: 'إضافة عنصر',
                                icon: Icons.add,
                                onPressed: _addItem,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // قائمة العناصر
                          if (_items.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'لم يتم إضافة أي عناصر بعد',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(
                                      item['description'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${item['amount']?.toString() ?? '0'} ريال',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteItem(index),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // قسم الوثائق الإضافية
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.medium,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // عنوان القسم
                          Row(
                            children: [
                              const Icon(
                                Icons.description,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'الوثائق الإضافية',
                                style: AppTextStyles.sectionTitle,
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: _addDocument,
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                                tooltip: 'إضافة وثيقة',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // قائمة الوثائق
                          if (_documents.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'لم يتم إضافة أي وثائق بعد',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _documents.length,
                              itemBuilder: (context, index) {
                                final document = _documents[index];
                                final isExpired = document.isExpired;
                                final isExpiringSoon = document.isExpiringSoon;

                                Color statusColor = Colors.green;
                                if (isExpired) {
                                  statusColor = Colors.red;
                                } else if (isExpiringSoon) {
                                  statusColor = Colors.orange;
                                }

                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.description,
                                      color: statusColor,
                                    ),
                                    title: Text(
                                      document.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('الرقم: ${document.number}'),
                                        Text(
                                          'تنتهي: ${document.expiryDate.day}/${document.expiryDate.month}/${document.expiryDate.year}',
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteDocument(index),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // أزرار الإجراءات
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          label: 'إلغاء',
                          icon: Icons.cancel,
                          onPressed: () => Navigator.pop(context),
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ActionButton(
                          label: isEditing ? 'تحديث الحساب' : 'حفظ الحساب',
                          icon: isEditing ? Icons.update : Icons.save,
                          onPressed: _saveAccount,
                          isLoading: _isSaving,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // نموذج بيانات الحساب الأساسية
  Widget _accountDetailsForm() {
    return Column(
      children: [
        // اسم الحساب
        CustomTextField(
          label: 'اسم الحساب',
          hint: 'أدخل اسم الحساب',
          controller: _nameController,
          prefixIcon: Icons.label,
          isRequired: true,
        ),

        // المبلغ المستحق
        CustomTextField(
          label: 'المبلغ المستحق',
          hint: 'أدخل المبلغ المستحق',
          controller: _totalDueController,
          prefixIcon: Icons.attach_money,
          isRequired: true,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال المبلغ المستحق';
            }
            if (double.tryParse(value) == null) {
              return 'يرجى إدخال قيمة صحيحة';
            }
            return null;
          },
        ),

        // المبلغ المسدد
        CustomTextField(
          label: 'المبلغ المسدد',
          hint: 'أدخل المبلغ المسدد',
          controller: _totalPaidController,
          prefixIcon: Icons.payments,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (double.tryParse(value) == null) {
                return 'يرجى إدخال قيمة صحيحة';
              }
            }
            return null;
          },
        ),

        // تاريخ الاستحقاق
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تاريخ الاستحقاق',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (selectedDate != null) {
                    setState(() {
                      _dueDate = selectedDate;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_dueDate.year}/${_dueDate.month}/${_dueDate.day}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// مربع حوار إضافة عنصر جديد
class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog();

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitItem() {
    if (_formKey.currentState!.validate()) {
      final newItem = {
        'description': _descriptionController.text.trim(),
        'amount': double.tryParse(_amountController.text) ?? 0,
      };
      Navigator.pop(context, newItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إضافة عنصر جديد'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // وصف العنصر
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'الوصف *',
                  hintText: 'أدخل وصف العنصر',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال وصف للعنصر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // قيمة العنصر
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ *',
                  hintText: 'أدخل قيمة العنصر',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال المبلغ';
                  }
                  if (double.tryParse(value) == null) {
                    return 'يرجى إدخال قيمة صحيحة';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(onPressed: _submitItem, child: const Text('إضافة')),
        ],
      ),
    );
  }
}

/// دايلوج إضافة وثيقة جديدة
class _AddDocumentDialog extends StatefulWidget {
  final Function(Document) onAdd;

  const _AddDocumentDialog({required this.onAdd});

  @override
  State<_AddDocumentDialog> createState() => _AddDocumentDialogState();
}

class _AddDocumentDialogState extends State<_AddDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  void _submitDocument() {
    if (_formKey.currentState!.validate()) {
      final newDocument = Document(
        name: _nameController.text.trim(),
        number: _numberController.text.trim(),
        expiryDate: _expiryDate,
      );
      widget.onAdd(newDocument);
      Navigator.pop(context);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.description, color: AppColors.primary),
            SizedBox(width: 8),
            Text('إضافة وثيقة جديدة'),
          ],
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // اسم الوثيقة
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الوثيقة *',
                  hintText: 'مثال: رخصة عمل، جواز سفر، عقد عمل',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم الوثيقة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // رقم الوثيقة
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'رقم الوثيقة *',
                  hintText: 'أدخل رقم الوثيقة',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال رقم الوثيقة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // تاريخ الانتهاء
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text('تاريخ الانتهاء: '),
                      Text(
                        '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _submitDocument,
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
