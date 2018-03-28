@echo off
if "%1" == "" goto default
set userinput=%1
goto start
:default
 set userinput=%~dp0MoeHero
:start

cd %~dp0tools
"w3x2lni\bin\w2l-worker.exe" "make.lua" "debug" "%userinput%" %~dp0
pause
