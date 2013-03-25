@echo off
cd ..
:start
Extras\fxc64 /D /nologo /Tfx_2_0 /Fomb.fx mb_src.fx


echo Shader processing has ended.
echo Press any key to recompile. . .
echo ___________________________________
pause>nul
goto :start