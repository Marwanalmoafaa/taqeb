import 'package:hive_flutter/hive_flutter.dart';
import 'package:taqeb/models/company.dart';
import 'package:taqeb/models/transaction.dart';
import 'package:taqeb/models/account.dart';
import 'package:taqeb/models/user.dart';

/// خدمة قاعدة البيانات المركزية للتطبيق
/// تدير عمليات الاتصال بقاعدة البيانات Hive وعمليات CRUD
class DatabaseService {
  // صناديق Hive المستخدمة في التطبيق
  static late Box<Company> _companiesBox;
  static late Box<TransactionModel> _transactionsBox;
  static late Box<AccountModel> _accountsBox;

  // أسماء الصناديق
  static const String companiesBoxName = 'companies';
  static const String transactionsBoxName = 'transactions';
  static const String accountsBoxName = 'accounts';

  /// تهيئة قاعدة البيانات وفتح الصناديق
  static Future<void> initialize() async {
    await Hive.initFlutter();

    try {
      // تسجيل المحولات
      Hive.registerAdapter(CompanyAdapter());
      Hive.registerAdapter(TransactionAdapter());
      Hive.registerAdapter(AccountAdapter());
      Hive.registerAdapter(UserAdapter());

      // فتح الصناديق
      _companiesBox = await Hive.openBox<Company>(companiesBoxName);
      _transactionsBox = await Hive.openBox<TransactionModel>(
        transactionsBoxName,
      );
      _accountsBox = await Hive.openBox<AccountModel>(accountsBoxName);
    } catch (e) {
      // في حالة وجود خطأ في قراءة البيانات القديمة، احذف البيانات وابدأ من جديد
      await Hive.deleteFromDisk();
      await Hive.initFlutter();

      // إعادة تسجيل المحولات
      Hive.registerAdapter(CompanyAdapter());
      Hive.registerAdapter(TransactionAdapter());
      Hive.registerAdapter(AccountAdapter());

      // فتح الصناديق من جديد
      _companiesBox = await Hive.openBox<Company>(companiesBoxName);
      _transactionsBox = await Hive.openBox<TransactionModel>(
        transactionsBoxName,
      );
      _accountsBox = await Hive.openBox<AccountModel>(accountsBoxName);
    }
  }

  // =========== عمليات الشركات ===========

  /// الحصول على جميع الشركات (غير المؤرشفة افتراضياً)
  static List<Company> getAllCompanies({bool includeArchived = false}) {
    if (includeArchived) {
      return _companiesBox.values.toList();
    }
    return _companiesBox.values
        .where((company) => !company.isArchived)
        .toList();
  }

  /// الحصول على شركة بواسطة المفتاح
  static Company? getCompany(dynamic key) {
    return _companiesBox.get(key);
  }

  /// إضافة شركة جديدة
  static Future<void> addCompany(Company company) async {
    await _companiesBox.add(company);
  }

  /// تحديث شركة
  static Future<void> updateCompany(Company company) async {
    await company.save();
  }

  /// حذف شركة (تحديثها كمؤرشفة)
  static Future<void> archiveCompany(Company company) async {
    company.isArchived = true;
    await company.save();
  }

  /// حذف شركة نهائياً
  static Future<void> deleteCompany(Company company) async {
    await company.delete();
  }

  // =========== عمليات المعاملات ===========

  /// الحصول على جميع المعاملات
  static List<TransactionModel> getAllTransactions() {
    return _transactionsBox.values.toList();
  }

  /// إضافة معاملة جديدة
  static Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionsBox.add(transaction);
  }

  /// تحديث معاملة
  static Future<void> updateTransaction(TransactionModel transaction) async {
    await transaction.save();
  }

  /// حذف معاملة
  static Future<void> deleteTransaction(TransactionModel transaction) async {
    await transaction.delete();
  }

  // =========== عمليات الحسابات ===========

  /// الحصول على جميع الحسابات
  static List<AccountModel> getAllAccounts() {
    return _accountsBox.values.toList();
  }

  /// الحصول على الحسابات المستحقة قريبا
  static List<AccountModel> getDueAccounts({int daysThreshold = 7}) {
    final now = DateTime.now();
    return _accountsBox.values
        .where(
          (account) =>
              account.remaining > 0 &&
              account.dueDate.difference(now).inDays <= daysThreshold,
        )
        .toList();
  }

  /// إضافة حساب جديد
  static Future<void> addAccount(AccountModel account) async {
    await _accountsBox.add(account);
  }

  /// تحديث حساب
  static Future<void> updateAccount(AccountModel account) async {
    await account.save();
  }

  /// حذف حساب
  static Future<void> deleteAccount(AccountModel account) async {
    await account.delete();
  }

  /// استيراد البيانات من JSON
  static Future<void> importFromJson(Map<String, dynamic> data) async {
    // استيراد الشركات
    if (data.containsKey('companies')) {
      final companies = (data['companies'] as List)
          .map((e) => Company.fromMap(e as Map<String, dynamic>))
          .toList();

      await _companiesBox.clear();
      for (var company in companies) {
        await _companiesBox.add(company);
      }
    }

    // استيراد المعاملات
    if (data.containsKey('transactions')) {
      final transactions = (data['transactions'] as List)
          .map((e) => TransactionModel.fromMap(e as Map<String, dynamic>))
          .toList();

      await _transactionsBox.clear();
      for (var transaction in transactions) {
        await _transactionsBox.add(transaction);
      }
    }

    // استيراد الحسابات
    if (data.containsKey('accounts')) {
      final accounts = (data['accounts'] as List)
          .map((e) => AccountModel.fromMap(e as Map<String, dynamic>))
          .toList();

      await _accountsBox.clear();
      for (var account in accounts) {
        await _accountsBox.add(account);
      }
    }
  }

  /// تصدير البيانات إلى JSON
  static Map<String, dynamic> exportToJson() {
    return {
      'companies': _companiesBox.values
          .map((company) => company.toMap())
          .toList(),
      'transactions': _transactionsBox.values
          .map((transaction) => transaction.toMap())
          .toList(),
      'accounts': _accountsBox.values
          .map((account) => account.toMap())
          .toList(),
    };
  }

  /// إضافة بيانات تجريبية للاختبار
  static Future<void> addSampleExpiringData() async {
    final now = DateTime.now();

    // شركة مع سجل تجاري قارب على الانتهاء
    final company1 = Company(
      name: 'شركة المدينة للتجارة',
      ownerId: '1234567890',
      ownerPhone: '0501234567',
      ownerExtra: [],
      companyData: [
        {
          'label': 'السجل التجاري',
          'value': now.add(const Duration(days: 5)).toIso8601String(),
        },
        {
          'label': 'الرخصة التجارية',
          'value': now.add(const Duration(days: 20)).toIso8601String(),
        },
      ],
      workers: [
        {
          'name': 'أحمد محمد',
          'residencyExpiry': now.add(const Duration(days: 3)).toIso8601String(),
          'passportExpiry': now.add(const Duration(days: 45)).toIso8601String(),
        },
        {
          'name': 'محمد علي',
          'residencyExpiry': now
              .add(const Duration(days: 12))
              .toIso8601String(),
        },
      ],
    );

    // شركة مع وثائق قاربت على الانتهاء
    final company2 = Company(
      name: 'مؤسسة الخليج للمقاولات',
      ownerId: '9876543210',
      ownerPhone: '0509876543',
      ownerExtra: [],
      companyData: [
        {
          'label': 'شهادة السلامة',
          'value': now.add(const Duration(days: 8)).toIso8601String(),
        },
        {
          'label': 'تصريح البناء',
          'value': now.add(const Duration(days: 60)).toIso8601String(),
        },
      ],
      workers: [
        {
          'name': 'خالد أحمد',
          'residencyExpiry': now
              .add(const Duration(days: 25))
              .toIso8601String(),
          'licenseExpiry': now.add(const Duration(days: 15)).toIso8601String(),
        },
      ],
    );

    await addCompany(company1);
    await addCompany(company2);
  }

  /// حذف جميع البيانات (للاختبار فقط)
  static Future<void> clearAllData() async {
    await _companiesBox.clear();
    await _transactionsBox.clear();
    await _accountsBox.clear();
  }
}
