:: zapret-winws-kodx, zapret config creation script
:: Copyright (C) 2024  Yegor Bayev <kodx.org>

:: This program is free software: you can redistribute it and/or modify
:: it under the terms of the GNU Affero General Public License as published
:: by the Free Software Foundation, either version 3 of the License, or
:: (at your option) any later version.

:: This program is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
:: GNU Affero General Public License for more details.

:: You should have received a copy of the GNU Affero General Public License
:: along with this program.  If not, see <https://www.gnu.org/licenses/>.

:: SPDX-License-Identifier: AGPL-3.0-or-later

@echo off
chcp 65001 >nul
:: 65001 = UTF-8

:: checking administrator access
net session >nul 2>&1

:: if don't have the rights, run it with vbs script
if '%errorlevel%' NEQ '0' (
    cscript //NoLogo "%~dp0bin\elevate.vbs" "%~f0" %*
    exit /B
)

SetLocal EnableDelayedExpansion

set "PROG_NAME="Zapret-Winws-kodx"

:: service
set "SVC_NAME=zapret-winws-kodx"
set "SVC_DISP_NAME=zapret DPI bypass : %SVC_NAME%"
set "SVC_DESC=zapret DPI bypass software"

:: paths
set "WINWS_BIN=%~dp0bin\winws\winws.exe"
set "PAYLOAD_PATH=%~dp0payloads"
set "LIST_PATH=%~dp0lists"
set "CONFIG_PATH=%~dp0config"

set "BLACK_LIST_URL=https://p.thenewone.lol/domains-export.txt"

:: convert relative to absolute path
for %%I in ("PAYLOAD_PATH" "LIST_PATH" "CONFIG_PATH") do (
    call :SetPathVar %%I
)

:: config files
set "CONFIG_FILE=%~dp0zapret-winws-kodx-config.txt"
set "PARAMS_FILE=%CONFIG_PATH%\params.txt"
set "VARIANTS_FILE=%CONFIG_PATH%\variants.csv"
set "PAYLOADS_FILE=%CONFIG_PATH%\payloads.txt"
set "LISTS_FILE=%CONFIG_PATH%\lists.txt"
set "CUSTOM_SETTINGS_FILE=%CONFIG_PATH%\custom.txt"

:: load payload vars from file
call :ReadVarsFromFile "%PAYLOADS_FILE%"
:: set address list from lists file
call :SetAddrlist "%LISTS_FILE%"
:: set row count from variants file
call :SetRowCount "%VARIANTS_FILE%"

goto :main

:UpdateRussiaBlacklist
    bitsadmin /transfer blacklist %BLACK_LIST_URL% "%BLACK_LIST%"
    call :SetAddrlist %LISTS_FILE%
exit /b 0

:GetFullPath
    set _result="%~f1"
exit /b 0

:SetPathVar
    set _IN_PARAM="%~1"
    set _IN_PATH="!%~1!"
    call :GetFullPath %_IN_PATH%
    set %_IN_PARAM%="%_result%"
    set "_result="
exit /b 0

:: Set address arguments from lists file
:SetAddrlist
    set _IN_FILE="%~1"
    for /f "usebackq delims=" %%L in (`type !_IN_FILE!`) do (
        set "line=%%L"
        if defined line (
            for /f "tokens=1,* delims==" %%A in ("!line!") do (
                call :SetAddrlistVar %%A %%B
            )
        )
    )

exit /b 0

:SetAddrlistVar
    set "_in_name=%~1"
    set _in_path="%~2"
    set "_file_type="
    set "_result="

    if not defined _in_path (
        goto :SetAddrlistVarExit
    )

    :: if ends with "_LIST"
    if "%_in_name:~-5%" == "_LIST" (
        set "_file_type=--hostlist"
    )

    :: if ends with "_IPSET"
    if "%_in_name:~-6%" == "_IPSET" (
        set "_file_type=--ipset"
    )

    :: if starts with "AUTO_"
    if "%_in_name:~0,5%" == "AUTO_" (
        set "_file_type=--hostlist-auto"
    )

    if "%_in_name%" == "EXCLUDE_LIST" (
        set "_file_type=--hostlist-exclude"
    )

    if not defined _file_type (
        goto :SetAddrlistVarExit
    )

    if not %_in_name% == AUTO_LIST (
        if not exist %_in_path% (
            goto :SetAddrlistVarExit
        )
    )
    set "_result=%_file_type%=%_in_path%"
    set %_in_name%=%_result%
    :SetAddrlistVarExit
exit /b 0

:: Parse row %1
:ParseRow
    set "_IN_ROW_STR=%~1"
    set _COLUMN_INDEX=0
    for %%I in (%_IN_ROW_STR:,= %) do (
        set /a "_COLUMN_INDEX+=1"
        call :GetArgListVal !_COLUMN_INDEX!
        set "_COL_NAME=!_result!"
        set "PARAM_NUM=%%I"
        call :GetPVar !PARAM_NUM!
        set "!_COL_NAME!=!_result!"
    )
exit /b 0

:: Read value from ARG_LIST array at given number %1
:GetArgListVal
    set "_result=!ARG_LIST[%~1]!"
exit /b 0

:: %1 - param number
:GetPVar
    set "_result=!p[%1]!"
exit /b 0

:ReadVarsFromFile
    set _IN_FILE="%~1"
    for /f "usebackq delims=" %%L in (`type !_IN_FILE!`) do (
        set "line=%%L"
        if defined line (
            call set %%L
        )
    )
exit /b 0

:ReadCustomSettings
    set "_IN_FILE=%1"
    for /f "tokens=1,2 delims=|" %%a in (`type !_IN_FILE!`) do (
        call set %%a=%%b
    )
exit /b 0

:: Read argument names from config
:ReadArgumentNames
    set _IN_FILE="%~1"
    set /p _HEADER=<%_IN_FILE%
    set ARG_COUNT=0
    for %%I in (%_HEADER:,= %) do (
        set /a ARG_COUNT+=1
        set "ARG_LIST[!ARG_COUNT!]=%%I"
    )
exit /b 0

:SetRowCount
    set _IN_FILE="%~1"
    set ROW_COUNT=0
    for /f "usebackq delims=" %%L in (`type !_IN_FILE!`) do (
        set /a ROW_COUNT+=1
    )
    :: substract header from ROW_COUNT
    set /a ROW_COUNT-=1
exit /b 0


:: Read variants from file %1, file is csv with header at first line
:: Read parameters from file %2
:: Read custom settings from %3
:: %4 is selected variant, if 0 then read from custom settings file
:: In result there will be vars like YT_HTTPS_ARG with param set
:SetArgs
    set _IN_VARIANTS_FILE="%~1"
    set _IN_PARAMS_FILE="%~2"
    set _IN_SETTINGS_FILE="%~3"
    set "_IN_CHOICE_NUM=%~4"
    set "ARGS="

    call :ReadArgumentNames %_IN_VARIANTS_FILE%

    if %_IN_CHOICE_NUM% equ 0 (
        if exist %_IN_SETTINGS_FILE% (
            call :ReadCustomSettings %_IN_SETTINGS_FILE%
        ) else (
            echo."||| ОШИБКА / ERROR |||"
            echo.Не найден файл пользовательских настроек %CUSTOM_SETTINGS_FILE%.
            echo.
            echo.Custom settings file %CUSTOM_SETTINGS_FILE% doesn't exists.
            goto SetArgsExit
        )
        goto :SetArgsStr
    )

    call :SetRowCount %_IN_VARIANTS_FILE%
    call :ReadVarsFromFile %_IN_PARAMS_FILE%

    :: Read one selected row from variants file
    for /f "skip=%_IN_CHOICE_NUM% usebackq delims=" %%R in (`type !_IN_VARIANTS_FILE!`) do (
        set "_ARG_ROW=%%R"
        goto :SetArgsRowFindEnd
    )
    :SetArgsRowFindEnd

    call :ParseRow "%_ARG_ROW%"

    :SetArgsStr
    set ARGS=--wf-tcp=80,443 --wf-udp=443,596-599,1400,50000-50099 ^
--filter-tcp=80 %YT_LIST% %YT_HTTP% --new ^
--filter-tcp=443 %YT_LIST% %YT_HTTPS% --new ^
--filter-udp=443 %YT_LIST% %YT_UDP% --new ^
--filter-tcp=80 %DIS_LIST% %DIS_HTTP% --new ^
--filter-tcp=443 %DIS_LIST% %DIS_HTTPS% --new ^
--filter-udp=443 %DIS_LIST% %DIS_UDP% --new ^
--filter-udp=596-599,1400,50000-50099 %DIS_PORT%

    if defined CF_IPSET (
        set ARGS=%ARGS% --new ^
--filter-tcp=80 %CF_IPSET% %CF_HTTP% --new ^
--filter-tcp=443 %CF_IPSET% %CF_HTTPS% --new ^
--filter-udp=443 %CF_IPSET% %CF_UDP%
    )

    if defined CUSTOM_LIST (
        set ARGS=%ARGS% --new ^
--filter-tcp=80 %CUSTOM_LIST% %CUSTOM_HTTP% --new ^
--filter-tcp=443 %CUSTOM_LIST% %CUSTOM_HTTPS% --new ^
--filter-udp=443 %CUSTOM_LIST% %CUSTOM_UDP%
    )

    if defined CUSTOM_IPSET (
        set ARGS=%ARGS% --new ^
--filter-tcp=80 %CUSTOM_IPSET% %CUSTOM_HTTP% --new ^
--filter-tcp=443 %CUSTOM_IPSET% %CUSTOM_HTTPS% --new ^
--filter-udp=443 %CUSTOM_IPSET% %CUSTOM_UDP%
    )

    if defined GAME_LIST (
        set ARGS=%ARGS% --new ^
--filter-tcp=80 %GAME_LIST% %GAME_HTTP% --new ^
--filter-tcp=443 %GAME_LIST% %GAME_HTTPS% --new ^
--filter-udp=443 %GAME_LIST% %GAME_UDP%
    )

    if defined GAME_IPSET (
        set ARGS=%ARGS% --new ^
--filter-tcp=80 %GAME_IPSET% %GAME_HTTP% --new ^
--filter-tcp=443 %GAME_IPSET% %GAME_HTTPS% --new ^
--filter-udp=443 %GAME_IPSET% %GAME_UDP% --new ^
--filter-tcp=2099 %GAME_IPSET% %GAME_PORT%
    )

    if defined BLACK_LIST (
        set ARGS=%ARGS% --new ^
--filter-tcp=80 %BLACK_LIST% %BLACK_HTTP% --new ^
--filter-tcp=443 %BLACK_LIST% %BLACK_HTTPS%
    )

    set ARGS=%ARGS% --new ^
--filter-tcp=80 %AUTO_LIST% %EXCLUDE_LIST% %AUTO_HTTP% --new ^
--filter-tcp=443 %AUTO_LIST% %EXCLUDE_LIST% %AUTO_HTTPS% --new ^
--filter-udp=443 %AUTO_LIST% %EXCLUDE_LIST% %AUTO_UDP%

    :SetArgsExit
exit /b 0

:: Service control
::  %1 - service name
::  %2 - control command, can be one of (start, stop, restart, delete)
:ServiceControl
    set "_svc_name=%~1"
    set "_svc_control_cmd=%~2"

    sc query "%_svc_name%" >nul 2>&1
    if errorlevel 1 (
        echo Служба "%_svc_name%" не найдена \ Service "%_svc_name%" not found
        exit /b 0
    )

    if %_svc_control_cmd%==start (
        echo Запускаем \ Starting "%_svc_name%" ...
        sc start %_svc_name%
    )
    if %_svc_control_cmd%==stop (
        echo Останавливаем \ Stopping "%_svc_name%" ...
        net stop %_svc_name%
    )
    if %_svc_control_cmd%==restart (
        echo Останавливаем \ Stopping "%_svc_name%" ...
        net stop %_svc_name%
        echo Запускаем \ Starting "%_svc_name%" ...
        sc start %_svc_name%
    )
    if %_svc_control_cmd%==delete (
        echo Останавливаем \ Stopping "%_svc_name%" ...
        net stop %_svc_name%
        echo Удаляем \ Deleting "%_svc_name%" ...
        sc delete %_svc_name%
    )
exit /b 0

:ServiceCleanup
    for %%I in ("%SVC_NAME%" "WinDivert" "WinDivert14") do (
        call :ServiceControl %%I delete
    )
ivert14"
exit /b 0

:ServiceCleanupOthers
    for %%I in ("GoodbyeDPI" "winws1" "zapret" "WinDivert" "WinDivert14") do (
        call :ServiceControl %%I delete
    )
exit /b 0

:ServiceInstall
    if not defined ARGS (
        echo "Настройки не определены, остановка \ The settings are not defined, break"
        exit /b 0
    )
    call :SaveCurrentConfig
    call :ServiceControl %SVC_NAME% stop
    echo Создаём службу \ Creating service "%SVC_NAME%"
    call :ServiceCreate
    call :ServiceControl %SVC_NAME% start
exit /b 0

:SaveCurrentConfig
    echo # variant: %_V_CHOICE% > "%CONFIG_FILE%"
    echo %ARGS% >> "%CONFIG_FILE%"
exit /b 0

:ServiceCreate
    set "_svc_name=%SVC_NAME%"
    set "_svc_disp_name=%SVC_DISP_NAME%"
    set "_svc_desc=%SVC_DESC%"
    set _svc_bin_cmd="\"%WINWS_BIN%\" @\"%CONFIG_FILE%\""

    sc query "%_svc_name%" >nul 2>&1
    if errorlevel 1 (
        sc create "%_svc_name%" binPath= "C:\Windows\System32\svchost.exe" DisplayName= "%_svc_disp_name%" start= auto
        if errorlevel 1 (
            echo ОШИБКА: не удалось создать службу "%_svc_name%" \ ERROR: cannot create service "%_svc_name%"
            exit /b 1
        )
    ) else (
        echo Служба "%_svc_name%" уже существует — обновляем параметры \ Service "%_svc_name%" already created, update parameters
    )

    :: registry path
    set "_reg_path=HKLM\SYSTEM\CurrentControlSet\Services\%_svc_name%"

    reg add "%_reg_path%" /v ImagePath /t REG_EXPAND_SZ /d %_svc_bin_cmd% /f >nul 2>&1
    reg add "%_reg_path%" /v DisplayName /t REG_SZ /d %_svc_disp_name% /f >nul 2>&1
    reg add "%_reg_path%" /v Description /t REG_SZ /d "%_svc_desc%" /f >nul 2>&1

    echo Служба "%_svc_name%" успешно создана \ "%_svc_name%" service has been successfully created
    sc qc "%_svc_name%"
exit /b 0

:RunExe
    if not defined ARGS (
        echo "Настройки не определены, остановка \ The settings are not defined, break"
        exit /b 0
    )
    call :SaveCurrentConfig
    set EXEC_STR="%WINWS_BIN%" @"%CONFIG_FILE%"
    echo Запускаем программу с параметрами \ Starting winws with cmd %EXEC_STR%
    start "zapret: http,https,quic" /min %EXEC_STR%
exit /b 0

:ChooseVariant
    echo.
    echo -----------------------------------------------------------------
    echo %NAME% - Установка/Обновление настроек │ Setup-Config update
    echo -----------------------------------------------------------------
    echo Выберите вариант настроек:
    echo    от 1 до %ROW_COUNT% - один из предустановленных вариантов
    echo    0 - загрузить собственные настройки из файла 'custom.txt'
    echo    -1 - возвращение назад в меню
    echo после ввода нажмите Enter, по умолчанию выбор -1
    echo.
    echo Select a customization option:
    echo    1 to %ROW_COUNT% - one of the preset options
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
        if %_V_CHOICE% leq %ROW_COUNT% (
            call :SetArgs "%VARIANTS_FILE%" "%PARAMS_FILE%" "%CUSTOM_SETTINGS_FILE%" !_V_CHOICE!
            goto ChooseVariantEnd
        )
        goto ChooseVariantErr
    )

    :ChooseVariantErr
    echo."||| ОШИБКА / ERROR |||"
    echo Введённое '%_V_CHOICE%' выходит за диапазон от 0 до %ROW_COUNT% или -1.
    echo.
    echo The entered '%_V_CHOICE%' is outside the range of 0 to %ROW_COUNT% or -1.

    goto ChooseVariantStart

    :ChooseVariantEnd
exit /b 0

:MainMenu
    echo.
    echo -------------
    echo %PROG_NAME:"=%
    echo -------------
    echo Выберите действие                    │ Select an action
    echo ====================================================================
    echo 1. Установка/Обновление службы       │ Setup/Update service
    echo 2. Загрузка/Обновление списка сайтов │ Setup/Update russia blacklist
    echo 3. Пробный запуск в окне             │ Test run in separate window
    echo 4. Удаление службы                   │ Delete service
    echo 5. Очистка от похожих программ       │ Cleanup from similar programs
    echo 6. Выход                             │ Exit
    echo.
    set op=
    choice /c 123456 /n /m "Ваш выбор: │ Choose number: "
    set op=%errorlevel%

    if %op%==1 (
        call :ChooseVariant
        call :ServiceInstall
    )
    if %op%==2 (
        call :UpdateRussiaBlacklist
    )
    if %op%==3 (
        call :ChooseVariant
        call :RunExe
    )
    if %op%==4 (
        call :ServiceCleanup
    )
    if %op%==5 (
        call :ServiceCleanupOthers
    )
    if %op%==6 (
        goto end
    )
    goto :MainMenu
exit /b 0

:main

call :MainMenu

:end
EndLocal
exit
