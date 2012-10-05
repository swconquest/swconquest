:: SCRIPT TO CHANGE THE FONT OF THE GAME ENGINE TO THE STAR WARS CONQUEST ONE
:: coded by swyter | licensed under MIT like terms <http://opensource.org/licenses/mit-license.php>
goto start

:MB2SWC
  @ren ..\..\Textures\Font.dds Font_original_mb_[modified_by_swc_script].dds > nul
  @copy /Y .\Font\Font_SWC.dds ..\..\Textures\Font.dds > nul

  @ren ..\..\Data\Font_data.xml Font_data_original_mb_[modified_by_swc_script].xml > nul
  @copy /Y .\Font\Font_data.xml ..\..\Data\Font_data.xml > nul
  goto :eof

:SWC2MB
  @del /F /Q ..\..\Textures\Font.dds > nul
  @ren ..\..\Textures\Font_original_mb_[modified_by_swc_script].dds Font.dds > nul

  @del /F /Q ..\..\Data\Font_data.xml > nul
  @ren ..\..\Data\Font_data_original_mb_[modified_by_swc_script].xml Font_data.xml > nul
  goto :eof


:start
  @echo off && cls && color 0E
  title Star Wars Conquest Font Script - Coded by Swyter


  if not exist ..\..\Textures\Font_original_mb_[modified_by_swc_script].dds (
      call :MB2SWC
      echo ^| Now you're using our own Star Wars Conquest font.
      echo ^| Run this script again to bring the original back.
  ) else (
      call :SWC2MB
      echo ^| Now you're using the original Mount^&Blade font again.
      echo ^| Run this script once more if you want to use our own.
  )
  pause
  exit