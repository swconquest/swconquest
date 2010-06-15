echo off
color 1f
echo. 
title Esto es para dejar limpia la Release antes de empaquetarla en ZIP, muy necesario...
echo Esto es para dejar limpia la Release antes de empaquetarla en ZIP, muy necesario...
echo.
echo. Apachurra enter si quieres...
pause > nul
echo Allá vamos revan
for /f "tokens=* delims=" %%i in ('dir /s /b /a:d *svn') do (
  rd /s /q "%%i"
)

echo Hecho
pause > nul
exit