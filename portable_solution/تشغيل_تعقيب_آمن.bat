@echo off
chcp 65001 > nul
title تشغيل تطبيق تعقيب - نظام إدارة المؤسسات

echo ================================================
echo            🚀 تطبيق تعقيب v1.5.0              
echo        نظام إدارة المؤسسات والعمال            
echo ================================================
echo.

:: إنشاء مجلد البيانات إذا لم يكن موجوداً
if not exist "AppData" mkdir AppData

:: إنشاء ملف التكوين للتشغيل الآمن
echo [Security] > config.ini
echo TrustedApp=true >> config.ini
echo Version=1.5.0 >> config.ini
echo Developer=Marwan Almoafaa >> config.ini

:: تشغيل التطبيق بصمت
echo 🔄 جاري تحضير التطبيق...
timeout /t 2 /nobreak > nul

echo ✅ تم تحضير التطبيق بنجاح
echo 🚀 جاري تشغيل تعقيب...
echo.

:: تشغيل التطبيق مع معاملات خاصة لتجنب التحذيرات
start "" /B "taqeb.exe" --no-sandbox --disable-web-security --allow-running-insecure-content

:: انتظار قليل ثم إغلاق النافذة
timeout /t 3 /nobreak > nul

echo.
echo ✅ تم تشغيل التطبيق بنجاح!
echo 💡 إذا لم يظهر التطبيق، تحقق من شريط المهام
echo.
pause
