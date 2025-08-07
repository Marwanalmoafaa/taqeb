@echo off
echo ========================================
echo       تطبيق تقب - نظام إدارة المؤسسات
echo            الإصدار 1.1.0+2
echo ========================================
echo.
echo جاري تشغيل التطبيق...
echo.

REM التحقق من وجود الملفات المطلوبة
if not exist "taqeb.exe" (
    echo ❌ خطأ: ملف taqeb.exe غير موجود!
    echo تأكد من وجود جميع ملفات التطبيق في نفس المجلد.
    pause
    exit /b 1
)

if not exist "flutter_windows.dll" (
    echo ❌ خطأ: ملف flutter_windows.dll غير موجود!
    echo تأكد من وجود جميع ملفات التطبيق في نفس المجلد.
    pause
    exit /b 1
)

if not exist "data" (
    echo ❌ خطأ: مجلد data غير موجود!
    echo تأكد من وجود جميع ملفات التطبيق في نفس المجلد.
    pause
    exit /b 1
)

echo ✅ جميع الملفات موجودة، جاري التشغيل...
echo.

REM تشغيل التطبيق
start "" "taqeb.exe"

echo ✅ تم تشغيل التطبيق بنجاح!
echo يمكنك الآن إغلاق هذه النافذة.
echo.
pause
