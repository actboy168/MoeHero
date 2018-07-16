@echo off
chcp 65001
"%~dp0..\w3x2lni\bin\w3x2lni-lua.exe" "%~dp0rsa.lua" %1
pause
