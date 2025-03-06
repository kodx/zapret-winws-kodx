@echo off
chcp 65001 >nul
:: 65001 - UTF-8

SetLocal EnableDelayedExpansion

set "PROG_NAME=Zapret-Winws-kodx"
set "SRVNAME=zapret-winws-kodx"
set "WINWS_BIN=%~dp0winws\winws.exe"
set "FAKE_PATH=%~dp0..\files"
set "LIST_PATH=%~dp0..\lists"
set "CONFIG_PATH=%~dp0..\config"

for %%I in ("FAKE_PATH" "LIST_PATH" "CONFIG_PATH") do (
    call :SetPathVar %%I
)

set "TLS_GOOGLE="%FAKE_PATH%\tls_clienthello_www_google_com.bin""
set "QUIC_GOOGLE="%FAKE_PATH%\quic_initial_www_google_com.bin""
set "QUIC_VK="%FAKE_PATH%\quic_initial_vk_com.bin""
set "QUIC_SHORT="%FAKE_PATH%\quic_short.bin""
set "TLS_IANA="%FAKE_PATH%\tls_clienthello_iana_org.bin""

set "YT_TCP_LIST=%LIST_PATH%\list-youtube-ui.txt"
set "YT_UDP_LIST=%LIST_PATH%\list-youtube-quic.txt"
set "YT_IP_IPSET=%LIST_PATH%\ipset-youtube-rtmps.txt"

set "CUSTOM_LIST=%LIST_PATH%\list-custom.txt"

set "DIS_TCP_LIST=%LIST_PATH%\list-discord.txt"
set "DIS_UDP_LIST=%LIST_PATH%\list-discord.txt"
set "DIS_IP_IPSET=%LIST_PATH%\ipset-discord.txt"
set "DIS_PORTSET=50000-50099"

set "BLACK_LIST_URL=https://p.thenewone.lol/domains-export.txt"
set "BLACK_LIST=%LIST_PATH%\list-blacklist.txt"

set "AUTO_LIST=%LIST_PATH%\list-auto.txt"

set "PARAMS_FILE=%CONFIG_PATH%\params.txt"
set "VARIANTS_FILE=%CONFIG_PATH%\variants.txt"
set "CONFIG_FILE=%CONFIG_PATH%\config.txt"
set "CUSTOM_SETTINGS_FILE=%CONFIG_PATH%\custom.txt"

set ADDR_LIST="YT_TCP_LIST" "YT_UDP_LIST" "YT_IP_IPSET" "CUSTOM_LIST" "DIS_TCP_LIST" "DIS_UDP_LIST" "DIS_IP_IPSET" "AUTO_LIST" "BLACK_LIST"
set ARG_VAR_LIST="HTTP" "CUSTOM" "YT_TCP" "YT_UDP" "YT_IP" "DIS_TCP" "DIS_UDP" "DIS_IP" "AUTO" "BLACK_HTTP" "BLACK_HTTPS"

set _ARG_VAR_LEN=0
for %%I in (%ARG_VAR_LIST%) do (
    set /a _ARG_VAR_LEN+=1
)

rem set addr vars from list
for %%i in (%ADDR_LIST%) do (
   call :SetAddrlistVar %%i
)

set "HTTP_LIST=%YT_TCP_LIST% %DIS_TCP_LIST% %CUSTOM_LIST%"

rem read parameters from file
set _P_LEN=0
for /f "delims=" %%L in (%PARAMS_FILE%) do (
    call set %%L
    set /a _P_LEN+=1
)

rem read variants from file
set _V_LEN=0
for /f "delims=" %%L in (%VARIANTS_FILE%) do (
    set %%L
    set /a _V_LEN+=1
)

rem variants array length
set /a _V_LEN=(_V_LEN/_ARG_VAR_LEN)

goto :main

:UpdateRussiaBlacklist
    bitsadmin /transfer blacklist %BLACK_LIST_URL% "%BLACK_LIST%"
exit /b 0

rem %1 - param number
:GetPVar
    set "_result=!p[%1]!"
exit /b 0

:GetFullPath
    set _result=%~f1
exit /b 0

:SetPathVar
    set "_IN_PARAM=%~1"
    set "_IN_PATH=!%~1!"
    call :GetFullPath %_IN_PATH%
    set %_IN_PARAM%=%_result%
    set "_result="
exit /b 0

:SetAddrlistVar
    set "_in_param=%~1"
    set "_path=!%~1!"
    set "_file_type="
    set "_result="

    if not defined _path (
        goto :SetAddrlistVarExit
    )

    if "%_in_param:~-5%" == "_LIST" (
        set "_file_type=--hostlist"
    )
    if "%_in_param:~-6%" == "_IPSET" (
        set "_file_type=--ipset"
    )
    if %_in_param% == AUTO_LIST (
        set "_file_type=--hostlist-auto"
    )

    if not defined _file_type (
        goto :SetAddrlistVarExit
    )

    if not %_in_param% == AUTO_LIST (
        if not exist %_path% (
            goto :SetAddrlistVarExit
        )
    ) 
    set "_result=%_file_type%="%_path%""

    :SetAddrlistVarExit
    set %_in_param%=%_result%
exit /b 0

:ReadCustomSettings
    for /f "delims=" %%L in (%CUSTOM_SETTINGS_FILE%) do (
        set %%L
    )
    for %%P in (%ARG_VAR_LIST%) do (
        call set v[0].%%~P=!C_%%~P!
    )
exit /b 0

rem %1 - variant number
:GetConfig
    set _V_NUM=%1

    if %_V_NUM% equ 0 (
        if exist %CUSTOM_SETTINGS_FILE% (
            call :ReadCustomSettings
        )
    )            

    for %%P in (%ARG_VAR_LIST%) do (
        if %_V_NUM% equ 0 (
            set _result=!v[%_V_NUM%].%%~P!
        ) else (
            set "PARAM_NUM=!v[%_V_NUM%].%%~P!"
            call :GetPVar !PARAM_NUM!
        )            
        set "%%~P_ARG=!_result!"
    )

    set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-tcp=80 %HTTP_LIST% %HTTP_ARG% --new ^
--filter-tcp=443 %CUSTOM_LIST% %CUSTOM_ARG% --new ^
--filter-tcp=443 %YT_TCP_LIST% %YT_TCP_ARG% --new ^
--filter-udp=443 %YT_UDP_LIST% %YT_UDP_ARG% --new ^
--filter-tcp=443 %YT_IP_IPSET% %YT_IP_ARG% --new ^
--filter-tcp=443 %DIS_TCP_LIST% %DIS_TCP_ARG% --new ^
--filter-udp=443 %DIS_UDP_LIST% %DIS_UDP_ARG% --new ^
--filter-udp=%DIS_PORTSET% %DIS_IP_IPSET% %DIS_IP_ARG% --new ^
--filter-tcp=443 %AUTO_LIST% %AUTO_ARG%

    if defined BLACK_LIST (
        set ARGS=%ARGS% --new ^
--filter-tcp=80 %BLACK_LIST% %BLACK_HTTP_ARG% --new ^
--filter-tcp=443 %BLACK_LIST% %BLACK_HTTPS_ARG%
    )
exit /b 0

:ServiceStart
    echo Запускаем \ Starting %1 ...
    sc start %1
exit /b 0

:ServiceStop
    echo Останавливаем \ Stopping %1 ...
    sc stop %1
exit /b 0

:ServiceRestart
    call :ServiceStop %1
    call :ServiceStart %1
exit /b 0

:ServiceDelete
    call :ServiceStop %1
    echo Удаляем \ Deleting %1 ...
    sc delete %1
exit /b 0

:ServiceCleanup
    call :ServiceDelete %1
    call :ServiceDelete "WinDivert"
    call :ServiceDelete "WinDivert14"
exit /b 0

:ServiceCleanupOthers
    call :ServiceDelete "GoodbyeDPI"
    call :ServiceDelete "winws1"
    call :ServiceDelete "zapret"
    call :ServiceDelete "WinDivert"
    call :ServiceDelete "WinDivert14"
exit /b 0

:ServiceInstall
    set SVCBIN="\"%WINWS_BIN%\" %ARGS%"
    call :ServiceDelete %1
    echo Создаём службу \ Creating service %1 %SVCBIN%
    sc create %1 binPath= %SVCBIN% DisplayName= "zapret DPI bypass : %1" start= auto
    sc description %1 "zapret DPI bypass software"
    call :ServiceStart %1
exit /b 0

:RunExe
    set EXEC_STR="%WINWS_BIN%" %ARGS%
    echo Запускаем программу с параметрами \ Starting winws with cmd %EXEC_STR%
    start "zapret: http,https,quic" /min %EXEC_STR%
exit /b 0

:ChooseVariant
    echo.
    echo -----------------------------------------------------------------
    echo %NAME% - Установка/Обновление настроек │ Setup-Config update
    echo -----------------------------------------------------------------
    echo Выберите вариант настроек: 
    echo    от 1 до %_V_LEN% - один из предустановленных вариантов
    echo    0 - загрузить собственные настройки из файла 'custom.txt'
    echo    -1 - возвращение назад в меню
    echo после ввода нажмите Enter, по умолчанию выбор -1
    echo.
    echo Select a customization option: 
    echo    1 to %_V_LEN% - one of the preset options
    echo    0 - load your own customizations from the 'custom.txt' file
    echo    -1 - back to the main menu
    echo after entering press Enter, default selection is -1
    echo =================================================================
    :ChooseVariantStart
    set /p _V_CHOICE=Ваш выбор: │ Choose input: || set _V_CHOICE=-1

    if %_V_CHOICE% equ -1 (
        goto ChooseVariantEnd
    )

    if %_V_CHOICE% geq 0 (
        if %_V_CHOICE% leq %_V_LEN% (
            call :GetConfig !_V_CHOICE!
            goto ChooseVariantEnd
        )
        goto ChooseVariantErr
    )

    :ChooseVariantErr
    echo."||| ОШИБКА / ERROR |||"
    echo Введённое '%_V_CHOICE%' выходит за диапазон от 0 до %_V_LEN% или -1.
    echo.
    echo The entered '%_V_CHOICE%' is outside the range of 0 to %_V_LEN% or -1.

    goto ChooseVariantStart

    :ChooseVariantEnd
exit /b 0

:MainMenu
    echo.
    echo -------------
    echo %PROG_NAME%
    echo -------------
    echo Выберите действие                    │ Select an action
    echo ====================================================================
    echo 1. Установка/Обновление службы       │ Setup/Update service
    echo 2. Загрузка/Обновление списка сайтов │ Setup/Update russia blacklist
    echo 3. Пробный запуск в окне             │ Test run in separate window
    echo 4. Запуск службы                     │ Start service
    echo 5. Остановка службы                  │ Stop service
    echo 6. Перезапуск службы                 │ Restart service
    echo 7. Удаление службы                   │ Delete service
    echo 8. Очистка от похожих программ       │ Cleanup from similar programs
    echo 9. Выход                             │ Exit 
    echo.
    set op=
    choice /c 123456789 /n /m "Ваш выбор: │ Choose number: "
    set op=%errorlevel%

    if %op%==1 (
        call :ChooseVariant
        call :ServiceInstall %SRVNAME%
    )
    if %op%==2 (
        call :UpdateRussiaBlacklist
    )
    if %op%==3 (
        call :ChooseVariant
        call :RunExe
    )
    if %op%==4 (
        call :ServiceStart %SRVNAME%
    )
    if %op%==5 (
        call :ServiceStop %SRVNAME%
    )
    if %op%==6 (
        call :ServiceRestart %SRVNAME%
    )
    if %op%==7 (
        call :ServiceCleanup %SRVNAME%
    )
    if %op%==8 (
        call :ServiceCleanupOthers
    )
    if %op%==9 (
        goto end
    )
    goto :MainMenu
exit /b 0

:main

call :MainMenu

:end
EndLocal
exit
