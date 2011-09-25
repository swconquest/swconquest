@echo off
setlocal enabledelayedexpansion
cls

:main
rem --------------{begin}
title formating, pls wait...

call :doit DE
call :doit ES
call :doit FR
call :doit PL

rem --------------{end}
goto exit


:doit
rem --------------{begin}
cd %1
echo Processing [%1]...

for /f "tokens=1-3* delims=-()" %%1 in ('dir /b *.ini') do (
    set oldfilename=%%1
    rem set out=%%2.csv&set out=!out:~0,8!
    rem set newfilename=%%2(!out!^)%%4
	rem set newfilename=!oldfilename!:[%1]=
	rem set newfilename=!oldfilename:%1.=! this one gives an error with the spanish files removes two "es."
	set newfilename=!oldfilename:~3!
    echo Oldfilename=!oldfilename!
    echo Newfilename=!newfilename!
    pause>nul
    echo.&echo.
    ren !oldfilename! !newfilename!
    )
popd

ren *.ini *.csv
ren items.csv item_kinds.csv

cd ..
rem --------------{end}
goto :eof


:exit
rem --------------{begin}
echo. && echo _________________ && echo finished! && pause>nul
exit
rem --------------{end}