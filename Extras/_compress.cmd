@echo off && title Compressing swconquest release... ^| Wait a bit && cd ..
set fname=swconquest-0904_t.7z
set /p fname=7z filename [or enter for %fname%]:

Extras\_7z a -m0=lzma2 -mx9 -xr!_*.txt %fname% @extras\_compress.list

echo Compressed! Showing in explorer...
explorer /select,%fname%
pause