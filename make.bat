@echo off
if "%1" == "" goto default
set userinput=%1
goto start
:default
 set userinput=%~dp0\
:start

del "%~dp0\map\lua\currentpath.lua"
echo return [[%~dp0script\]] >> "%~dp0\map\lua\currentpath.lua"
"%~dp0tools\w3x2lni\src\build\lua.exe" "%~dp0tools\make.lua" "debug" "%userinput%"
del "%~dp0\map\lua\currentpath.lua"
pause
