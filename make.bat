@echo off
if "%1" == "" goto default
set userinput=%1
goto start
:default
 set userinput=%~dp0MoeHero
:start

cd %~dp0tools
"bin\w2l-worker.exe" "make.lua" "debug" "%userinput%"
pause
