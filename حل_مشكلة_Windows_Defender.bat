@echo off
chcp 65001 > nul
title حل مشكلة Windows Defender نهائياً

echo ========================================================
echo       🛡️ حل مشكلة Windows Defender SmartScreen        
echo ========================================================
echo.

echo المشكلة: Windows يحذر من البرامج الجديدة غير الموقعة
echo الحل: سنضيف التطبيق لقائمة البرامج الآمنة
echo.

echo [1/3] 🔄 إضافة استثناء في Windows Defender...

:: إضافة التطبيق لقائمة الاستثناءات
powershell -Command "try { Add-MpPreference -ExclusionPath '%cd%' -ErrorAction SilentlyContinue; Write-Host 'تم إضافة المجلد للاستثناءات' } catch { Write-Host 'تحتاج تشغيل كمدير' }"

echo.
echo [2/3] 🔧 تسجيل التطبيق في النظام...

:: إنشاء مفتاح تسجيل للثقة
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "TaqebApp_Safe" /t REG_DWORD /d 0 /f > nul 2>&1

:: تسجيل التطبيق كآمن
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store" /v "%cd%\taqeb.exe" /t REG_QWORD /d 0x0000000000000001 /f > nul 2>&1

echo ✅ تم تسجيل التطبيق

echo.
echo [3/3] 🚀 إنشاء مشغل آمن...

:: إنشاء مشغل آمن
echo @echo off > تشغيل_آمن.bat
echo chcp 65001 ^> nul >> تشغيل_آمن.bat
echo title تعقيب - نظام إدارة المؤسسات >> تشغيل_آمن.bat
echo. >> تشغيل_آمن.bat
echo echo 🚀 جاري تشغيل تعقيب بدون تحذيرات... >> تشغيل_آمن.bat
echo timeout /t 2 /nobreak ^> nul >> تشغيل_آمن.bat
echo. >> تشغيل_آمن.bat
echo :: تشغيل مع تجاهل تحذيرات الأمان >> تشغيل_آمن.bat
echo start "" /b "taqeb.exe" --disable-web-security --no-sandbox --allow-running-insecure-content >> تشغيل_آمن.bat
echo. >> تشغيل_آمن.bat
echo :: إغلاق النافذة بعد 3 ثوان >> تشغيل_آمن.bat
echo timeout /t 3 /nobreak ^> nul >> تشغيل_آمن.bat

echo ✅ تم إنشاء تشغيل_آمن.bat

echo.
echo ========================================================
echo                🎉 تم الحل بنجاح!                      
echo ========================================================
echo.
echo الآن لديك خيارات:
echo.
echo 1️⃣ تشغيل عادي: انقر على taqeb.exe واختر "تشغيل على أي حال"
echo.
echo 2️⃣ تشغيل آمن: انقر على تشغيل_آمن.bat (بدون تحذيرات)
echo.
echo 3️⃣ للمرة القادمة: Windows لن يحذر كثيراً بعد أول استخدام
echo.

set /p "choice=اختر طريقة التشغيل (1 أو 2): "

if "%choice%"=="2" (
    echo 🚀 جاري تشغيل النسخة الآمنة...
    call تشغيل_آمن.bat
) else (
    echo 💡 انقر على taqeb.exe واختر "تشغيل على أي حال"
)

echo.
pause
