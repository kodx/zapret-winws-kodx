@echo off
chcp 65001 >nul
:: 65001 - UTF-8 

set NAME=Zapret-Winws

title %NAME% - Управление службой/Service control

rem cd /d "%~dp0"

set SRVNAME=winws1
set BIN=%~dp0winws\
set FAKE_PATH=%~dp0..\files
set LIST_PATH=%~dp0..\lists
set TLS_GOOGLE="%FAKE_PATH%\tls_clienthello_www_google_com.bin"
set QUIC_GOOGLE="%FAKE_PATH%\quic_initial_www_google_com.bin"
set TLS_IANA="%FAKE_PATH%\tls_clienthello_iana_org.bin"
set YT_LIST="%LIST_PATH%\list-youtube.txt"
IF EXIST "%YT_LIST%" (
    set YT_LIST=--hostlist=%YT_LIST%
) ELSE (
    set YT_LIST=
)
set C_LIST="%LIST_PATH%\list-custom.txt"
IF EXIST "%C_LIST%" (
    set C_LIST=--hostlist=%C_LIST%
) ELSE (
    set C_LIST=
)
set DIS_LIST="%LIST_PATH%\list-discord.txt"
IF EXIST "%DIS_LIST%" (
    set DIS_LIST=--hostlist=%DIS_LIST%
) ELSE (
    set DIS_LIST=
)
set COMBO_LIST=%DIS_LIST% %C_LIST%
set ALL_LIST=%YT_LIST% %COMBO_LIST%
set DIS_IPSET="%LIST_PATH%\ipset-discord.txt"
IF EXIST "%DIS_IPSET%" (
    set DIS_IPSET=--ipset=%DIS_IPSET%
) ELSE (
    set DIS_IPSET=
)
set DIS_PORTSET=50000-50099

:start
echo.
echo -------------
echo %NAME% - Управление службой  │ Service control
echo -------------
echo Выберите действие                  │ Select an action
echo ========================================================
echo 1. Установка/Обновление настроек   │ Setup/Config update
echo 2. Запуск                          │ Start
echo 3. Перезапуск                      │ Restart
echo 4. Остановка                       │ Stop
echo 5. Удаление                        │ Delete
echo 6. Выход                           │ Exit
echo.
set op=
choice /c 123456 /n /m "Ваш выбор: │ Choose number: "
set op=%errorlevel%

if %op%==1 goto install
if %op%==2 call :srvstart %SRVNAME%
if %op%==3 call :srvrestart %SRVNAME%
if %op%==4 call :srvstop %SRVNAME%
if %op%==5 call :srvdel %SRVNAME%
if %op%==6 goto end

:install
echo.
echo -------------
echo %NAME% - Установка/Обновление настроек │ Setup-Config update
echo -------------
echo Выберите вариант настроек от 1 до 15 или 0 для возвращения назад в меню
echo после ввода нажмите Enter, по умолчанию выбор 0
echo.
echo Select a setting option from 1 to 15 or 0 to return back to the menu
echo press Enter after entering, default is 0
echo =============
set op=
set /p op=Ваш выбор: │ Choose number: 
if '%op%'=='' set op=0
set res=
if %op% gtr 15 set res=1
if %op% lss 0 set res=1
if defined res (
    echo Введённое число "%op%" выходит за диапазон от 0 до 15.
    echo.
    echo The entered number "%op%" is outside the range of 0 to 15.
    goto install
)

if %op%==0 goto start

echo Выбран вариант "%op%" │ You option "%op%"
goto %op%
:run
set SVCBIN="\"%BIN%winws.exe\" %ARGS%"
call :srvinst %SRVNAME%

:srvinst
echo Stopping %1 ...
net stop %1
echo Deleting %1 ...
sc delete %1
echo Creating service %1 with cmd %SVCBIN%
sc create %1 binPath= %SVCBIN% DisplayName= "zapret DPI bypass : %1" start= auto
sc description %1 "zapret DPI bypass software"
echo Starting %1 ...
sc start %1
goto start

:srvstart
echo Starting %1 ...
sc start %1
goto start

:srvrestart
echo Stopping %1 ...
net stop %1
echo Starting %1 ...
sc start %1
goto start

:srvstop
echo Stopping %1 ...
net stop %1
goto start

:srvdel
echo Stopping %1 ...
net stop %1
echo Deleting %1 ...
sc delete %1
echo Stopping WinDivert ...
net stop "WinDivert"
echo Deleting WinDivert ...
sc delete "WinDivert"
echo Stopping WinDivert14 ...
net stop "WinDivert14"
echo Deleting WinDivert14 ...
sc delete "WinDivert14"
goto start

:end
exit

:1
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %YT_LIST% --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=%TLS_GOOGLE% --new ^
--filter-tcp=443 %COMBO_LIST% --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --new ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDAFAAAAC --new ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-any-protocol --dpi-desync-cutoff=n4
goto run

:2
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %YT_LIST% --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls=%TLS_GOOGLE% --new ^
--filter-tcp=443 %COMBO_LIST% --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --new ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDAFAAAAC --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDAFAAAAC --new ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6
goto run

:3
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %YT_LIST% --dpi-desync=fake,fakedsplit --dpi-desync-autottl=5 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls=%TLS_GOOGLE% --new ^
--filter-tcp=443 %COMBO_LIST% --dpi-desync=fake,fakedsplit --dpi-desync-autottl=5 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --new ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --new ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6
goto run

:4
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %YT_LIST% --dpi-desync=multisplit --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern=%TLS_GOOGLE%  --new ^
--filter-tcp=443 %COMBO_LIST% --dpi-desync=multisplit --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --new ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6
goto run

:5
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %ALL_LIST% --dpi-desync=fakedsplit --dpi-desync-split-pos=1 --dpi-desync-autottl --dpi-desync-fooling=badseq --dpi-desync-repeats=8 --new ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --new ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6
goto run

:6
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %YT_LIST% --dpi-desync=fake,multisplit --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=%TLS_GOOGLE% --new ^
--filter-tcp=443 %COMBO_LIST% --dpi-desync=fake,multisplit --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --new ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --new ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=8
goto run

:7
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --new ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new ^
--filter-l3=ipv4 --filter-tcp=443 --dpi-desync=syndata
goto run

:8
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls=%TLS_GOOGLE% --new ^
--filter-tcp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --new ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --new ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6
goto run

:9
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=%TLS_GOOGLE% --new ^
--filter-tcp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --new ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-repeats=6 --new ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6
goto run

:10
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %YT_LIST% --dpi-desync=fake,multisplit --dpi-desync-ttl=1 --dpi-desync-autottl=5 --dpi-desync-repeats=6 --dpi-desync-fake-tls=%TLS_GOOGLE% ^
--filter-tcp=443 %COMBO_LIST% --dpi-desync=fake,multisplit --dpi-desync-ttl=1 --dpi-desync-autottl=5 --dpi-desync-repeats=6 ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDAFAAAAC --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDAFAAAAC --new ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata --dpi-desync-fake-syndata=%TLS_IANA% ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multisplit ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multisplit --dpi-desync-fake-syndata=%TLS_IANA% ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multidisorder ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multidisorder --dpi-desync-fake-syndata=%TLS_IANA% ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata --wssize 1:6 ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata --dpi-desync-fake-syndata=%TLS_IANA% --wssize 1:6 ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multisplit --wssize 1:6 ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multisplit --dpi-desync-fake-syndata=%TLS_IANA% --wssize 1:6 ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multidisorder --wssize 1:6 ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multidisorder --dpi-desync-fake-syndata=%TLS_IANA% --wssize 1:6
goto run

:11
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=%TLS_GOOGLE% --new ^
--filter-tcp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --new ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDAFAAAAC --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDAFAAAAC --new ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE%
goto run

:12
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %YT_LIST% --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=%TLS_GOOGLE% --new ^
--filter-tcp=443 %COMBO_LIST% --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=%TLS_GOOGLE% --new ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDAFAAAAC --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDAFAAAAC --new ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE%
goto run

:13
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDAFAAAAC --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDAFAAAAC --new ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %YT_LIST% --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=%TLS_GOOGLE% --new ^
--filter-tcp=443 %COMBO_LIST% --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata --dpi-desync-fake-syndata=%TLS_IANA% ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multisplit ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multisplit --dpi-desync-fake-syndata=%TLS_IANA% ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multidisorder ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multidisorder --dpi-desync-fake-syndata=%TLS_IANA% ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata --wssize 1:6 ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata --dpi-desync-fake-syndata=%TLS_IANA% --wssize 1:6 ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multisplit --wssize 1:6 ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multisplit --dpi-desync-fake-syndata=%TLS_IANA% --wssize 1:6 ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multidisorder --wssize 1:6 ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,multidisorder --dpi-desync-fake-syndata=%TLS_IANA% --wssize 1:6
goto run

:14
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls=%TLS_GOOGLE% --new ^
--filter-tcp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --new ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDAFAAAAC --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDAFAAAAC --new ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE%
goto run

:15
set ARGS=--wf-tcp=80,443 --wf-udp=443,%DIS_PORTSET% ^
--filter-udp=%DIS_PORTSET% %DIS_IPSET% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-any-protocol --dpi-desync-cutoff=n2 --new ^
--filter-udp=%DIS_PORTSET% --new ^
--filter-udp=443 %YT_LIST% --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %COMBO_LIST% --dpi-desync=fake --dpi-desync-repeats=11 --new ^
--filter-tcp=80 %ALL_LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %YT_LIST% --dpi-desync=fake,multisplit --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=%TLS_GOOGLE% --new ^
--filter-tcp=443 %COMBO_LIST% --dpi-desync=fake,multisplit --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --new ^
--dpi-desync=fake,multidisorder --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig
goto run
