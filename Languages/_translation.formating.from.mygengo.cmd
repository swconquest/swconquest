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
	set newfilename=!oldfilename:~3!

	echo !oldfilename! ^=^> !newfilename!
    echo.&echo.
	
    ren !oldfilename! !newfilename!
    )
popd

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