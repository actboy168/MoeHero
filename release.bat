@echo off
del "%~dp0\map\lua\currentpath.lua"
"%~dp0w3x2txt\build\lua.exe" "%~dp0src\make.lua" "%~dp0\" "release" %1
del "%~dp0\map\lua\currentpath.lua"
pause
