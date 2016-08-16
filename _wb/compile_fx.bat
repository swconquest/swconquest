:start
@echo off
fxc /D PS_2_X=ps_2_b /T fx_2_0 /Fo mb.fx mb_src.fx


echo Script processing has ended.
echo Press any key to exit. . .
pause>nul
goto :start