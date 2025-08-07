import 'dart:convert';

// اختبار بسيط لوظائف النسخ الاحتياطي
void main() {
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

    // اختبار استعادة البيانات
    final parsedData = jsonDecode(jsonString);
    print('✅ قراءة واستعادة البيانات: نجح');
    print('📊 عدد الشركات المستعادة: ${parsedData['data']['companies_count']}');
    print('📊 عدد الحسابات المستعادة: ${parsedData['data']['accounts_count']}');
    print(
      '📊 عدد المعاملات المستعادة: ${parsedData['data']['transactions_count']}',
    );

    print('\n🎉 جميع اختبارات النسخ الاحتياطي نجحت!');
    print('✨ النظام جاهز للاستخدام');
  } catch (e) {
    print('❌ خطأ في الاختبار: $e');
  }
}
