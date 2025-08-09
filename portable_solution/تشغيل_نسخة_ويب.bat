@echo off
chcp 65001 > nul
title تعقيب - تطبيق الويب المحلي

echo ================================================
echo          🌐 تعقيب - النسخة الويب المحلية        
echo        تشغيل بدون أي تحذيرات من ويندوز          
echo ================================================
echo.

:: التحقق من وجود Python
python --version > nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python غير مثبت على النظام
    echo 📥 يرجى تثبيت Python من: https://python.org/downloads
    pause
    exit /b
)

:: إنشاء خادم ويب محلي
echo 🚀 جاري تشغيل خادم الويب المحلي...
echo 🌐 سيتم فتح التطبيق في المتصفح تلقائياً
echo 📍 العنوان: http://localhost:8080
echo.

:: إنشاء ملف HTML للتطبيق
echo ^<!DOCTYPE html^> > app.html
echo ^<html dir="rtl" lang="ar"^> >> app.html
echo ^<head^> >> app.html
echo     ^<meta charset="UTF-8"^> >> app.html
echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^> >> app.html
echo     ^<title^>تعقيب - نظام إدارة المؤسسات^</title^> >> app.html
echo     ^<style^> >> app.html
echo         body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%); color: white; } >> app.html
echo         .container { max-width: 800px; margin: 0 auto; text-align: center; } >> app.html
echo         .logo { font-size: 48px; margin-bottom: 20px; } >> app.html
echo         .title { font-size: 32px; margin-bottom: 30px; } >> app.html
echo         .launch-btn { padding: 15px 30px; font-size: 20px; background: #28a745; color: white; border: none; border-radius: 10px; cursor: pointer; margin: 10px; } >> app.html
echo         .launch-btn:hover { background: #218838; } >> app.html
echo     ^</style^> >> app.html
echo ^</head^> >> app.html
echo ^<body^> >> app.html
echo     ^<div class="container"^> >> app.html
echo         ^<div class="logo"^>🏢^</div^> >> app.html
echo         ^<h1 class="title"^>تعقيب - نظام إدارة المؤسسات^</h1^> >> app.html
echo         ^<p^>النسخة الويب المحلية - بدون تحذيرات ويندوز^</p^> >> app.html
echo         ^<button class="launch-btn" onclick="launchApp()"^>🚀 تشغيل التطبيق^</button^> >> app.html
echo         ^<script^> >> app.html
echo             function launchApp() { >> app.html
echo                 fetch('/launch').then(() =^> alert('تم تشغيل التطبيق!')); >> app.html
echo             } >> app.html
echo         ^</script^> >> app.html
echo     ^</div^> >> app.html
echo ^</body^> >> app.html
echo ^</html^> >> app.html

:: إنشاء خادم Python بسيط
echo import http.server > server.py
echo import socketserver >> server.py
echo import subprocess >> server.py
echo import urllib.parse >> server.py
echo import webbrowser >> server.py
echo import threading >> server.py
echo import time >> server.py
echo. >> server.py
echo class CustomHandler(http.server.SimpleHTTPRequestHandler): >> server.py
echo     def do_GET(self): >> server.py
echo         if self.path == '/': >> server.py
echo             self.path = '/app.html' >> server.py
echo         elif self.path == '/launch': >> server.py
echo             subprocess.Popen(['taqeb.exe']) >> server.py
echo             self.send_response(200) >> server.py
echo             self.end_headers() >> server.py
echo             return >> server.py
echo         super().do_GET() >> server.py
echo. >> server.py
echo def open_browser(): >> server.py
echo     time.sleep(1) >> server.py
echo     webbrowser.open('http://localhost:8080') >> server.py
echo. >> server.py
echo if __name__ == '__main__': >> server.py
echo     threading.Thread(target=open_browser, daemon=True).start() >> server.py
echo     with socketserver.TCPServer(('', 8080), CustomHandler) as httpd: >> server.py
echo         print('خادم الويب يعمل على http://localhost:8080') >> server.py
echo         httpd.serve_forever() >> server.py

:: تشغيل الخادم
python server.py
