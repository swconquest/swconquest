rem  #############################################################################
rem  # SCRIPT TO CHANGE THE FONT OF THE GAME ENGINE TO THE STAR WARS CONQUEST ONE
rem  #############################################################################
rem                      W W W . S W C O N Q U E S T . C O . C C 

rem  Coded By Swyter | © 2010 All rights reserved
rem ______________________________________________________________________________

goto start
exit

:MB2SWC
cls

@ren ..\..\Textures\Font.dds Font_original_mb_[modified_by_swc_script].dds > nul
@copy /Y .\Textures\Font_SWC.dds ..\..\Textures\Font.dds > nul

@ren ..\..\Data\Font_data.xml Font_data_original_mb_[modified_by_swc_script].xml > nul
@copy /Y ".\Module Data\Font_data.xml" "..\..\Data\Font_data.xml" > nul

echo. 
echo. 
echo   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo   ~           SCRIPT TO CHANGE THE STAR WARS CONQUEST FONT          ~
echo   ~           coded by Swyter                                       ~
echo   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo. 
echo. 
echo. 
echo   Press Enter to replace the MountandBlade default font to the SWC one
echo   If the font is already changed, the script will restore it.
echo.  You can exit anytime pressing Ctrl+C..
echo. 
echo. 
echo.   [X] Progress: Done, Now you have the SWC font...
echo.   [!] Press Enter again to close the SWC script window
pause > nul
rem #That's for waiting a second to show the message ;D
echo. 
echo Good Bye! Enjoy the Game and greetings from Swyter :D
ping -n 2 127.0.0.1 > nul
exit



:SWC2MB

cls

@del /F /Q ..\..\Textures\Font.dds > nul
@ren ..\..\Textures\Font_original_mb_[modified_by_swc_script].dds Font.dds > nul

@del /F /Q ..\..\Data\Font_data.xml > nul
@ren ..\..\Data\Font_data_original_mb_[modified_by_swc_script].xml Font_data.xml > nul

echo. 
echo. 
echo   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo   ~           SCRIPT TO CHANGE THE STAR WARS CONQUEST FONT          ~
echo   ~           coded by Swyter                                       ~
echo   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo. 
echo. 
echo. 
echo   Press Enter to replace the MountandBlade default font to the SWC one
echo   If the font is already changed, the script will restore it.
echo.  You can exit anytime pressing Ctrl+C..
echo. 
echo. 
echo.   [X] Progress: Done, Now you have the MB default font again...
echo. 
echo.   [!] Press Enter to close the SWC script window
pause > nul
rem # That's for wait a second to show the message ;D
echo. 
echo Good Bye! Enjoy the Game and greetings from Swyter :D
ping -n 2 127.0.0.1 > nul
exit



:start
echo off
cls
color 0E
title Star Wars Conquest Font Script - Coded by Swyter

echo. 
echo. 
echo   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo   ~           SCRIPT TO CHANGE THE STAR WARS CONQUEST FONT          ~
echo   ~           coded by Swyter                                       ~
echo   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo. 
echo. 
echo. 
echo   Press Enter to replace the MountandBlade default font to the SWC one
echo   If the font is already changed, the script will restore it.
echo.  You can exit anytime pressing Ctrl+C..
echo. 
echo. 
echo.   [ ] Progress: Waiting for Enter key
pause > nul
echo. 
echo. 
if exist ..\..\Textures\Font_original_mb_[modified_by_swc_script].dds (

goto SWC2MB

) else (

goto MB2SWC

)

