rem  #############################################################################
rem  # SCRIPT TO UPDATE STAR WARS CONQUEST
rem  #############################################################################
rem                      W W W . S W C O N Q U E S T . C O . C C 

rem  Coded By Swyter | © 2010 All rights reserved
rem ______________________________________________________________________________

goto start
exit

:UPDATE
cls

echo. 
echo. 
echo   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo   ~           SCRIPT TO UPDATE STAR WARS CONQUEST                   ~
echo   ~           coded by Swyter                                       ~
echo   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo. 
echo. 
echo. 
echo   Press Enter to update your SWC version, it only download the
echo   new and updated files, so the download will be faster...
echo.  You can exit anytime pressing Ctrl+C..
echo. 
echo. 
echo.   [+] Progress: Updating... Please wait... [Started at %time%]
echo. 
echo.  -Launching SVN Client
.\svn_client\svn.exe checkout --force http://svn6.assembla.com/svn/swconquest/ .\ 
echo. 
echo. 
echo.   [?] The update has ended at %time%... Press a key to exit...
pause > nul
echo. 
echo Good Bye! Enjoy the Game and greetings from Swyter :D

rem #That's for waiting a second to show the message ;D
rem #It only autopings your own computer 1sec before exit, call it a timer...
ping -n 2 127.0.0.1 > nul
exit


:start
echo off
cls
color 0E
title Update Star Wars Conquest Script - Coded by Swyter

echo. 
echo. 
echo   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo   ~           SCRIPT TO UPDATE STAR WARS CONQUEST                   ~
echo   ~           coded by Swyter                                       ~
echo   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo. 
echo. 
echo. 
echo   Press Enter to update your SWC version, it only download the
echo   new and updated files, so the download will be faster...
echo.  You can exit anytime pressing Ctrl+C..
echo. 
echo. 
echo.   [-] Progress: Waiting for Enter key...
pause > nul
echo. 
echo. 

IF EXIST .\svn_client\svn.exe (
goto UPDATE
)
echo.   [!] Error: You have not copied the "svn_client" folder...
echo.              Press a key to exit...
pause > nul
exit



