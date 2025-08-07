import 'package:flutter/material.dart';
import 'package:taqeb/models/transaction.dart';
import 'package:taqeb/services/database_service.dart';
import 'package:taqeb/utils/constants.dart';
import 'package:taqeb/widgets/common_widgets.dart';

/// شاشة عرض وإدارة المعاملات
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // تحميل المعاملات
  void _loadTransactions() {
    setState(() {
      _isLoading = true;
    });

    // استخدام خدمة قاعدة البيانات للحصول على المعاملات
    _transactions = DatabaseService.getAllTransactions();

    // ترتيب المعاملات حسب الأحدث
    _transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _isLoading = false;
    });
  }

  // إضافة معاملة جديدة
  void _addTransaction() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final transaction = TransactionModel(content: content);
    await DatabaseService.addTransaction(transaction);

    _contentController.clear();
    _loadTransactions();

    if (mounted) {
      showSnackMessage(context, 'تم إضافة المعاملة بنجاح');
    }
  }

  // تبديل حالة الإكمال للمعاملة
  void _toggleDone(TransactionModel transaction) async {
    transaction.isDone = !transaction.isDone;
    await DatabaseService.updateTransaction(transaction);
    _loadTransactions();
  }

  // حذف معاملة
  void _deleteTransaction(TransactionModel transaction) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'تأكيد الحذف',
      content: 'هل أنت متأكد من حذف هذه المعاملة؟',
      confirmText: 'حذف',
      isDanger: true,
    );

    if (confirmed == true) {
      await DatabaseService.deleteTransaction(transaction);
      _loadTransactions();

      if (mounted) {
        showSnackMessage(context, 'تم حذف المعاملة بنجاح');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // تقسيم المعاملات إلى منجزة وغير منجزة
    final pendingTransactions = _transactions.where((t) => !t.isDone).toList();
    final completedTransactions = _transactions.where((t) => t.isDone).toList();

    return Scaffold(
      appBar: AppBar(
        title: const PageTitle('المعاملات', icon: Icons.receipt_long),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // زر تحديث القائمة
          IconButton(
            onPressed: _loadTransactions,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // حقل إضافة معاملة جديدة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[50],
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: 'معاملة جديدة',
                      hintText: 'أدخل تفاصيل المعاملة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.medium,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (_) => _addTransaction(),
                  ),
                ),
                const SizedBox(width: 12),
                ActionButton(
                  label: 'إضافة',
                  icon: Icons.add,
                  onPressed: _addTransaction,
                ),
              ],
            ),
          ),

          // المحتوى الرئيسي
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                ? const EmptyState(
                    message: 'لا توجد معاملات حالياً\nقم بإضافة معاملة جديدة',
                    icon: Icons.receipt_long,
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // قسم المعاملات الجديدة (غير منجزة)
                        if (pendingTransactions.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.pending_actions,
                                  color: Colors.orange[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'المعاملات (${pendingTransactions.length})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...pendingTransactions.map(
                            (transaction) => _TransactionItem(
                              transaction: transaction,
                              onToggleDone: () => _toggleDone(transaction),
                              onDelete: () => _deleteTransaction(transaction),
                              onUpdate: (updatedTransaction) =>
                                  _loadTransactions(),
                            ),
                          ),
                        ],

                        // قسم المعاملات المنجزة
                        if (completedTransactions.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'المعاملات المنجزة (${completedTransactions.length})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...completedTransactions.map(
                            (transaction) => _TransactionItem(
                              transaction: transaction,
                              onToggleDone: () => _toggleDone(transaction),
                              onDelete: () => _deleteTransaction(transaction),
                              onUpdate: (updatedTransaction) =>
                                  _loadTransactions(),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20), // مساحة في النهاية
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// عنصر المعاملة في القائمة
class _TransactionItem extends StatefulWidget {
  final TransactionModel transaction;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;
  final Function(TransactionModel) onUpdate;

  const _TransactionItem({
    required this.transaction,
    required this.onToggleDone,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<_TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<_TransactionItem> {
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.transaction.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _saveEdit() async {
    final newContent = _editController.text.trim();
    if (newContent.isNotEmpty && newContent != widget.transaction.content) {
      widget.transaction.content = newContent;
      await DatabaseService.updateTransaction(widget.transaction);
      widget.onUpdate(widget.transaction);
    }
    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEdit() {
    _editController.text = widget.transaction.content;
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(
          color: widget.transaction.isDone
              ? Colors.green.withOpacity(0.3)
              : Theme.of(context).dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: GestureDetector(
          onTap: widget.onToggleDone,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.transaction.isDone
                  ? Colors.green
                  : Colors.transparent,
              border: Border.all(
                color: widget.transaction.isDone
                    ? Colors.green
                    : Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]!
                    : Colors.grey[600]!,
                width: 2,
              ),
            ),
            child: widget.transaction.isDone
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        ),
        title: _isEditing
            ? TextField(
                controller: _editController,
                autofocus: true,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                ),
                onSubmitted: (_) => _saveEdit(),
              )
            : GestureDetector(
                onDoubleTap: _startEditing,
                child: Text(
                  widget.transaction.content,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: widget.transaction.isDone
                        ? TextDecoration.lineThrough
                        : null,
                    color: widget.transaction.isDone
                        ? Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600]
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
        trailing: _isEditing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green[600], size: 20),
                    onPressed: _saveEdit,
                    tooltip: 'حفظ',
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red[600], size: 20),
                    onPressed: _cancelEdit,
                    tooltip: 'إلغاء',
                  ),
                ],
              )
            : IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.red[300]
                      : Colors.red[600],
                ),
                onPressed: widget.onDelete,
                tooltip: 'حذف المعاملة',
              ),
      ),
    );
  }
}
