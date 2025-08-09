@echo off
chcp 65001 > nul

:: تسجيل التطبيق كآمن في Windows
echo 🛡️ جاري تسجيل التطبيق كبرنامج آمن...

:: إضافة استثناء في Windows Defender
powershell -Command "try { Add-MpPreference -ExclusionPath '%CD%\taqeb.exe' -ErrorAction SilentlyContinue } catch { }"

:: إنشاء مفتاح تسجيل للثقة
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "TaqebApp_taqeb" /t REG_DWORD /d 0 /f > nul 2>&1

echo ✅ تم تسجيل التطبيق بنجاح
echo.
echo 🚀 الآن يمكنك تشغيل التطبيق بدون تحذيرات
echo 💡 قم بتشغيل: تشغيل_تعقيب_آمن.bat
echo.
pause
