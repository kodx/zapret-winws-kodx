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
@REM 65001 = UTF-8

SetLocal EnableDelayedExpansion

set "PROG_NAME=Zapret-Winws-kodx"
set "SRVNAME=zapret-winws-kodx"
set "WINWS_BIN=%~dp0winws\winws.exe"
set "PAYLOAD_PATH=%~dp0..\payloads"
set "LIST_PATH=%~dp0..\lists"
set "CONFIG_PATH=%~dp0..\config"

set "BLACK_LIST_URL=https://p.thenewone.lol/domains-export.txt"

@REM convert relative to absolute path
for %%I in ("PAYLOAD_PATH" "LIST_PATH" "CONFIG_PATH") do (
    call :SetPathVar %%I
)

set "PARAMS_FILE=%CONFIG_PATH%\params.txt"
set "VARIANTS_FILE=%CONFIG_PATH%\variants.csv"
set "PAYLOADS_FILE=%CONFIG_PATH%\payloads.txt"
set "LISTS_FILE=%CONFIG_PATH%\lists.txt"
set "CUSTOM_SETTINGS_FILE=%CONFIG_PATH%\custom.txt"

@REM load payload vars from file
call :ReadVarsFromFile %PAYLOADS_FILE%
@REM set address list from lists file
call :SetAddrlist %LISTS_FILE%
@REM set row count from variants file
call :SetRowCount %VARIANTS_FILE%

goto :main

:UpdateRussiaBlacklist
    bitsadmin /transfer blacklist %BLACK_LIST_URL% "%BLACK_LIST%"
    call :SetAddrlist %LISTS_FILE%
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

@REM Set address arguments from lists file
:SetAddrlist
    set "_IN_FILE=%1"

    for /f "tokens=1,2 delims==" %%a in (%_IN_FILE%) do (
        call :SetAddrlistVar "%%a" "%%b"
    )
exit /b 0

:SetAddrlistVar
    set "_in_name=%~1"
    set "_in_path=%~2"
    set "_file_type="
    set "_result="
    if not defined _in_path (
        goto :SetAddrlistVarExit
    )

    @REM if ends with "_LIST"
    if "%_in_name:~-5%" == "_LIST" (
        set "_file_type=--hostlist"
    )

    @REM if ends with "_IPSET"
    if "%_in_name:~-6%" == "_IPSET" (
        set "_file_type=--ipset"
    )

    @REM if starts with "AUTO_"
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
    set "_result=%_file_type%="%_in_path%""

    :SetAddrlistVarExit
    set %_in_name%=%_result%
exit /b 0

@REM Parse row %1
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

@REM Read value from ARG_LIST array at given number %1
:GetArgListVal
    set "_result=!ARG_LIST[%~1]!"
exit /b 0

@REM %1 - param number
:GetPVar
    set "_result=!p[%1]!"
exit /b 0

:ReadVarsFromFile
    set "_IN_FILE=%~1"
    for /f "delims=" %%L in (%_IN_FILE%) do (
        call set %%L
    )
exit /b 0

:ReadCustomSettings
    set "_IN_FILE=%1"
    for /f "tokens=1,2 delims=|" %%a in (%_IN_FILE%) do (
        call set %%a=%%b
    )
exit /b 0

@REM Read argument names from config
:ReadArgumentNames
    set "_IN_ARG_VARIANTS_FILE=%~1"
    set /p _HEADER=<"%_IN_ARG_VARIANTS_FILE%"
    set ARG_COUNT=0
    for %%I in (%_HEADER:,= %) do (
        set /a ARG_COUNT+=1
        set "ARG_LIST[!ARG_COUNT!]=%%I"
    )
exit /b 0

:SetRowCount
    set "_IN_ROW_VARIANTS_FILE=%~1"
    set ROW_COUNT=0
    for /f "delims=" %%L in (%_IN_ROW_VARIANTS_FILE%) do (
        set /a ROW_COUNT+=1
    )
    rem substract header from ROW_COUNT
    set /a ROW_COUNT-=1
exit /b 0

@REM Read variants from file %1, file is csv with header at first line
@REM Read parameters from file %2
@REM Read custom settings from %3
@REM %4 is selected variant, if 0 then read from custom settings file
@REM In result there will be vars like YT_HTTPS_ARG with param set
:SetArgs
    set "_IN_VARIANTS_FILE=%1"
    set "_IN_PARAMS_FILE=%2"
    set "_IN_SETTINGS_FILE=%3"
    set "_IN_CHOICE_NUM=%~4"

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

    @REM Read one selected row from variants file
    for /f "skip=%_IN_CHOICE_NUM% usebackq delims=" %%R in ("%_IN_VARIANTS_FILE%") do (
        set "_ARG_ROW=%%R"
        goto :SetArgsRowFindEnd
    )
    :SetArgsRowFindEnd

    call :ParseRow "%_ARG_ROW%"

    :SetArgsStr
    set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50099 ^
--filter-tcp=80 %YT_LIST% %YT_HTTP% --new ^
--filter-tcp=443 %YT_LIST% %YT_HTTPS% --new ^
--filter-udp=443 %YT_LIST% %YT_UDP% --new ^
--filter-tcp=80 %DIS_LIST% %DIS_HTTP% --new ^
--filter-tcp=443 %DIS_LIST% %DIS_HTTPS% --new ^
--filter-udp=443 %DIS_LIST% %DIS_UDP% --new ^
--filter-udp=50000-50099 %DIS_PORT%

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

:ServiceStart
    echo Запускаем \ Starting %1 ...
    sc start %1
exit /b 0

:ServiceStop
    echo Останавливаем \ Stopping %1 ...
    net stop %1
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
            call :SetArgs %VARIANTS_FILE% %PARAMS_FILE% %CUSTOM_SETTINGS_FILE% !_V_CHOICE!
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
