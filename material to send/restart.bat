@echo off
"C:\Program Files\Google\Chrome\nssm.exe" stop number_log
taskkill /IM "file logging number.exe" /F
timeout /t 5
"C:\Program Files\Google\Chrome\nssm.exe" start number_log
