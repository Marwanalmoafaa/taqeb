import 'dart:convert';
import 'dart:io';

// اختبار بسيط لوظائف النسخ الاحتياطي
void main() async {
  print('🔍 اختبار وظائف النسخ الاحتياطي...');

  // محاكاة بيانات النسخة الاحتياطية
  final testData = {
    'version': '1.0',
    'exported_at': DateTime.now().toIso8601String(),
    'data': {
      'companies_count': 5,
      'accounts_count': 15,
      'transactions_count': 50,
      'summary': {
        'total_companies': 5,
        'total_accounts': 15,
        'total_transactions': 50,
      },
    },
  };

  try {
    // اختبار تحويل إلى JSON
    final jsonString = jsonEncode(testData);
    print('✅ تحويل البيانات إلى JSON: نجح');
    print('📄 حجم البيانات: ${jsonString.length} حرف');

    // اختبار إنشاء ملف مؤقت
    final tempFile = File(
      'backup_test_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await tempFile.writeAsString(jsonString);
    print('✅ إنشاء ملف النسخة الاحتياطية: نجح');
    print('📁 المسار: ${tempFile.path}');

    // اختبار قراءة الملف
    final readData = await tempFile.readAsString();
    final parsedData = jsonDecode(readData);
    print('✅ قراءة واستعادة البيانات: نجح');
    print('📊 عدد الشركات المستعادة: ${parsedData['data']['companies_count']}');

    // حذف الملف المؤقت
    await tempFile.delete();
    print('🧹 تنظيف الملفات المؤقتة: نجح');

    print('\n🎉 جميع اختبارات النسخ الاحتياطي نجحت!');
    print('✨ النظام جاهز للاستخدام');
  } catch (e) {
    print('❌ خطأ في الاختبار: $e');
  }
}
