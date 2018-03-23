@echo off
if "%1" == "" goto default
set userinput=%1
goto start
:default
 set userinput=%~dp0\
:start

del "%~dp0\MoeHero\lua\currentpath.lua"
echo return [[%~dp0MoeHero\script\]] >> "%~dp0MoeHero\lua\currentpath.lua"
cd %~dp0tools
"bin\w2l-worker.exe" "make.lua" "debug" "%userinput%"
del "%~dp0MoeHero\lua\currentpath.lua"
pause
