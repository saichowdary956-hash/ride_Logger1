@echo off
cd C:\Users\gotti\Documents\datalogger\build\web
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --disable-web-resources-deprecation-warnings --disable-blink-features=AutomationControlled --no-first-run --no-default-browser-check --disable-translate --disable-popup-blocking "file:///%cd:\=/%/index.html"
pause
