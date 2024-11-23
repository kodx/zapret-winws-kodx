@echo off
chcp 65001 >nul
:: 65001 - UTF-8 

set NAME=Zapret-Winws

title %NAME% - Управление службой

cd /d "%~dp0"

set SRVNAME=winws1
set BIN=%~dp0winws\
set FAKE_PATH=%~dp0..\files
set LIST_PATH=%~dp0..\lists
set TLS_GOOGLE=%FAKE_PATH%\tls_clienthello_www_google_com.bin
set QUIC_GOOGLE=%FAKE_PATH%\quic_initial_www_google_com.bin
set TLS_IANA=%FAKE_PATH%\tls_clienthello_iana_org.bin
set LIST=--hostlist=%LIST_PATH%\list-youtube.txt --hostlist=%LIST_PATH%\list-discord.txt --hostlist=%LIST_PATH%\list-custom.txt
set IPSET=%LIST_PATH%\ipset-discord.txt

:start
echo.
echo -------------
echo %NAME% - Управление службой
echo -------------
echo Выберите действие
echo =============
echo 1. Установка/Обновление
echo 2. Запуск
echo 3. Остановка
echo 4. Удаление
echo 5. Выход
echo.
set op=
choice /c 12345 /n /m "Введите число от 1 до 5: "
set op=%errorlevel%

if %op%==1 goto install
if %op%==2 call :srvstart %SRVNAME%
if %op%==3 call :srvstop %SRVNAME%
if %op%==4 call :srvdel %SRVNAME%
if %op%==5 goto end

:install
echo.
echo -------------
echo %NAME% - Установка/обновление
echo -------------
echo Выберите вариант настроек от 1 до 15 или 0 для возвращения назад в меню
echo после ввода нажмите Enter, по умолчанию выбор 0
echo =============
set op=
set /p op=Ваш выбор: 
if '%op%'=='' set op=0
set res=
if %op% gtr 15 set res=1
if %op% lss 0 set res=1
if defined res (
    echo Введённое число "%op%" выходит за диапазон от 0 до 15.
    goto install
)

if %op%==0 goto start

echo Выбран вариант "%op%"
goto %op%
:run
set SVCBIN="\"%BIN%winws.exe\" %ARGS%"
call :srvinst %SRVNAME%

:srvinst
net stop %1
sc delete %1
sc create %1 binPath= %SVCBIN% DisplayName= "zapret DPI bypass : %1" start= auto
sc description %1 "zapret DPI bypass software"
sc start %1
goto start

:srvstart
sc start %1
goto start

:srvstop
net stop %1
goto start

:srvdel
net stop %1
sc delete %1
goto start

:end
exit

:1
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=50000-50100 %IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %LIST% --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls=%TLS_GOOGLE%
goto run

:2
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=50000-50100 %IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %LIST% --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls=%TLS_GOOGLE%
goto run

:3
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=50000-50100 %IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %LIST% --dpi-desync=fake,fakedsplit --dpi-desync-autottl=5 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls=%TLS_GOOGLE%
goto run

:4
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=50000-50100 %IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %LIST% --dpi-desync=multisplit --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern=%TLS_GOOGLE%
goto run

:5
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=50000-50100 %IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %LIST% --dpi-desync=fakedsplit --dpi-desync-split-pos=1 --dpi-desync-autottl --dpi-desync-fooling=badseq --dpi-desync-repeats=8
goto run

:6
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=50000-50100 %IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=8 --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %LIST% --dpi-desync=fake,multisplit --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=%TLS_GOOGLE%
goto run

:7
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=50000-50100 %IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-l3=ipv4 --filter-tcp=443 --dpi-desync=syndata
goto run

:8
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=50000-50100 %IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %LIST% --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls=%TLS_GOOGLE%
goto run

:9
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=50000-50100 %IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %LIST% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=%TLS_GOOGLE%
goto run

:10
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=50000-50100 %IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %LIST% --dpi-desync=fake,multisplit --dpi-desync-ttl=1 --dpi-desync-autottl=5 --dpi-desync-repeats=6 --dpi-desync-fake-tls=%TLS_GOOGLE% ^
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
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=50000-50100 %IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %LIST% --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=%TLS_GOOGLE%
goto run

:12
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=50000-50100 %IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %LIST% --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=%TLS_GOOGLE%
goto run

:13
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=50000-50100 %IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %LIST% --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=%TLS_GOOGLE% ^
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
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=50000-50100 %IPSET% --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %LIST% --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls=%TLS_GOOGLE%
goto run

:15
set ARGS=--wf-tcp=80,443 --wf-udp=443,50000-50099 ^
--filter-udp=50000-50099 %IPSET% --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-any-protocol --dpi-desync-cutoff=n2 --new ^
--filter-udp=50000-50099 --new ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=%QUIC_GOOGLE% --new ^
--filter-udp=443 %LIST% --dpi-desync=fake --dpi-desync-repeats=11 --new ^
--filter-tcp=80 %LIST% --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 %LIST% --dpi-desync=fake,multisplit --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=%TLS_GOOGLE% --new ^
--dpi-desync=fake,multidisorder --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig
goto run
