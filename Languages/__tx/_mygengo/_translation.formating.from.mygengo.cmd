@echo off
setlocal enabledelayedexpansion
cls

:main
rem --------------{begin}
title formating, pls wait...

call :doit DE
call :doit EN
call :doit ES
call :doit FR
call :doit IT
call :doit PL
call :doit SV

rem --------------{end}
goto exit


:doit
rem --------------{begin}
cd %1
echo Processing [%1]...

ren *.ini *.csv
echo Everything converted from *.ini ^=^> *.csv

cd ..
rem --------------{end}
goto :eof


:exit
rem --------------{begin}
echo. && echo _________________ && echo finished! && pause>nul
exit
rem --------------{end}