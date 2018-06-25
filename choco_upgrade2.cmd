@echo off

:Detect_OS_Version
IF "%OS%"=="Windows_NT" GOTO OS_Is_WindowsNT
GOTO OS_Is_WindowsDOS9x

:OS_Is_WindowsDOS9x
REM [ Windows DOS ]
REM 1.01 - Windows 1.01
REM 1.02 - Windows 1.02
REM 1.03 - Windows 1.03
REM 1.04 - Windows 1.04
REM 2.03 - Windows 2.03
REM 2.10 - Windows 2.10
REM 2.11 - Windows 2.11
REM 3.00 - Windows 3.0
REM 3.10 - Windows 3.1
REM 3.11 - Windows for Workgroup 3.11
REM 3.20 - Windows 3.2
REM [ Windows 9x ]
REM 4.00 - Windows 95
REM 4.10 - Windows 98
REM 4.90 - Windows ME
color 4f && echo NO SUPPORT Windows DOS/9x && pause && exit

:OS_Is_WindowsNT
REM [ Windows NT ]
REM NT  3.10 - Windows NT 3.1
REM NT  3.50 - Windows NT 3.5
REM NT  3.51 - Windows NT 3.51
REM NT  4.0 - Windows NT 4.0
REM NT  5.0 - Windows 2000
REM NT  5.1 - Windows XP and Windows Server 2003
REM NT  5.2 - Windows XP Professional x64 and Windows Server 2003 R2
REM NT  6.0 - Windows Vista and Windows Server 2008
REM NT  6.1 - Windows 7 and Windows Server 2008 R2
REM NT  6.2 - Windows 8 and Windows Server 2012
REM NT  6.3 - Windows 8.1 and Windows Server 2012 R2
REM NT 10.0 - Windows 10 and Windows Server 2016
for /f "tokens=4-7 delims=[.] " %%i in ('ver') do (
    if %%i==Version (
	    set MajorVer=%%j
	    set MinorVer=%%k
	    set RTMBuild=%%l
	) else (
	    set MajorVer=%%i
	    set MinorVer=%%j
	    set RTMBuild=%%k
	)
)
if %MajorVer%%MinorVer% LSS 51 (
  color 4f
  echo NO SUPPORT Windows NT Version Less Than 5.1
  echo Your Windows NT Version is [%MajorVer%.%MinorVer%]
  pause
  exit
)

:creating_scheduled_tasks
ECHO [Creating scheduled tasks]
setlocal
set runlevel=
REM Get OS version from registry
for /f "tokens=2*" %%i in ('reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "CurrentVersion"') do set os_ver=%%j
REM Set run level (for Vista or later - version 6)
if /i "%os_ver:~,1%" GEQ "6" set runlevel=/rl HIGHEST
REM SCHTASKS /Create /TN "%~n0%~x0" /TR "%~f0" /SC MONTHLY /MO 1 /F /ru SYSTEM %runlevel%
REM SCHTASKS /Create /TN "%~n0%~x0" /TR "%~f0" /SC MONTHLY /MO 1 /F /ru administrators %runlevel%
SCHTASKS /Create /TN "%~n0%~x0" /TR "%~f0" /SC MONTHLY /MO first /D SAT /F /ru administrators %runlevel%
IF %ERRORLEVEL% EQU 0 goto firstWindows
IF %ERRORLEVEL% NEQ 0 color 4f && timeout 60 && goto creating_scheduled_tasks



:firstWindows
color 0f
cls

:getDateMyFomat
for /f %%x in ('wmic path win32_localtime get /format:list ^| findstr "="') do set %%x
if %Month% LSS 10 set Month=0%Month%
if %Day% LSS 10 set Day=0%Day%
if %Hour% LSS 10 set Hour=0%Hour%
if %Minute% LSS 10 set Minute=0%Minute%
set dateMyFomat=%Year%%Month%%Day%-%Hour%%Minute%

:getInternetStatus
SET ip=8.8.8.8
ping -n 1 %ip% | find "TTL="
IF not errorlevel 1 set InternetStatus=Online
IF errorlevel 1 set InternetStatus=Offline
cls

:getChocolateyStatus
where choco >nul 2>nul
IF %ERRORLEVEL% EQU 0 set ChocolateyStatus=Installed
IF %ERRORLEVEL% NEQ 0 set ChocolateyStatus=NA

:getCurlStatus
where curl >nul 2>nul
IF %ERRORLEVEL% EQU 0 set CurlStatus=Installed
IF %ERRORLEVEL% NEQ 0 set CurlStatus=NA

:getMd5Status
where md5 >nul 2>nul
IF %ERRORLEVEL% EQU 0 set Md5Status=Installed
IF %ERRORLEVEL% NEQ 0 set Md5Status=NA



:Main
REM SET Location=%~dp0%
REM SET Location=%systemroot%\Temp\chocolatey\
ECHO  ------------------------------------------------------------------------------
ECHO             ThisCMD: %~n0%~x0
ECHO  ------------------------------------------------------------------------------
ECHO     Windows Version: %MajorVer%.%MinorVer%
ECHO          Today Date: %dateMyFomat%
ECHO     Internet Status: %InternetStatus%
ECHO   Chocolatey Status: %ChocolateyStatus%
ECHO         Curl Status: %CurlStatus%
ECHO          Md5 Status: %Md5Status%
ECHO  ------------------------------------------------------------------------------
ECHO.
IF %InternetStatus%==Offline GOTO Windows_Offline
IF %ChocolateyStatus%==NA GOTO Windows_Install_Chocolatey
IF %CurlStatus%==NA GOTO Windows_Install_Curl
IF %Md5Status%==NA GOTO Windows_Install_Md5

for /f "tokens=1" %%i in ( 'curl -k -s https://raw.githubusercontent.com/susiang100/chocolatey/master/choco_upgrade.md5?t=%dateMyFomat%') do set md5_remote_choco_upgrade=%%i
for /f "tokens=1" %%i in ( 'md5 -l -n %~dp0%~n0%~x0') do set md5_local_choco_upgrade=%%i
echo     Md5 check local: [%md5_local_choco_upgrade%]
echo    Md5 check remote: [%md5_remote_choco_upgrade%]
ECHO  ------------------------------------------------------------------------------
ECHO.
rem IF %md5_remote_choco_upgrade% NEQ %md5_local_choco_upgrade% goto update_this_cmd_file
GOTO Windows_DoSome



:update_this_cmd_file
ECHO ############################
ECHO ### Update this CMD file ###
ECHO ############################
set run=curl -o %~dp0temp_%~n0%~x0 -k https://raw.githubusercontent.com/susiang100/chocolatey/master/choco_upgrade.cmd
rem echo %run%
rem echo.
%run%
for /f "tokens=1" %%i in ( 'md5 -l -n %~dp0temp_%~n0%~x0') do set md5_templocal_choco_upgrade=%%i
REM echo %md5_templocal_choco_upgrade% > %~dp0temp_%~n0%~x0.md5
echo      Md5 check temp: [%md5_templocal_choco_upgrade%]
echo    Md5 check remote: [%md5_remote_choco_upgrade%]
timeout 5
IF %md5_remote_choco_upgrade% NEQ %md5_templocal_choco_upgrade% goto firstWindows
echo copy temp to local
copy %~dp0temp_%~n0%~x0 %~dp0%~n0%~x0 && timeout 10 && start %~dp0%~n0%~x0 && del /q /f "%~dp0temp_%~n0%~x0" && exit
echo never run here!!!!
goto firstWindows

:Windows_Offline
color ce
ECHO [Oops! Unable to continue because the internet is not connected]
timeout 60
goto firstWindows

:Windows_Install_Chocolatey
color 9f
ECHO ##########################
ECHO ### install chocolatey ###
ECHO ##########################
ECHO [Requirements]
ECHO  - Windows 7+ / Windows Server 2003+
ECHO  - PowerShell v2+
ECHO  - .NET Framework 4+ (the installation will attempt to install .NET 4.0 if you do not have it installed)
ECHO [Chocolatey installing...]
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
goto firstWindows

:Windows_Install_Curl
color 9f
ECHO ####################
ECHO ### install curl ###
ECHO ####################
choco upgrade curl -y
goto firstWindows

:Windows_Install_Md5
color 9f
ECHO ####################
ECHO ### install md5 ###
ECHO ####################
choco upgrade md5 -y
goto firstWindows



:Windows_DoSome
choco upgrade chocolatey -y

:Detect_Is_Sever_Or_Client
for /f "tokens=3*" %%a in ('wmic os get caption ^| findstr /L "Server"') do set IsServer=%%a
if exist "%~dp0choco_upgrade\choco_upgrade.force.server.txt" goto Windows_Server_First_Install
if exist "%~dp0choco_upgrade\choco_upgrade.force.client.txt" goto Windows_Client_First_Install
if defined IsServer goto Windows_Server_First_Install
goto Windows_Client_First_Install

:Windows_Server_First_Install
IF EXIST "%~dp0choco_upgrade\choco_upgrade.first.lock" goto Windows_Server_General_Update
IF %MajorVer%%MinorVer% EQU 51 goto install_for_server2003
IF %MajorVer%%MinorVer% EQU 52 goto install_for_server2003r2
IF %MajorVer%%MinorVer% EQU 60 goto install_for_server2008
IF %MajorVer%%MinorVer% EQU 61 goto install_for_server2008r2
IF %MajorVer%%MinorVer% EQU 62 goto install_for_server2012
IF %MajorVer%%MinorVer% EQU 63 goto install_for_server2012r2
IF %MajorVer%%MinorVer% EQU 100 goto install_for_server2016

:Windows_Client_First_Install
IF EXIST "%~dp0choco_upgrade\choco_upgrade.first.lock" goto Windows_Client_General_Update
rem choco upgrade -y vcredist2005 vcredist2008 vcredist2010 vcredist2012 vcredist2013 vcredist2015 vcredist2017 
choco upgrade -y vcredist-all 
IF %MajorVer%%MinorVer% EQU 51 goto install_for_winxp
IF %MajorVer%%MinorVer% EQU 52 goto install_for_winxppro
IF %MajorVer%%MinorVer% EQU 60 goto install_for_vista
IF %MajorVer%%MinorVer% EQU 61 goto install_for_win7
IF %MajorVer%%MinorVer% EQU 62 goto install_for_win8
IF %MajorVer%%MinorVer% EQU 63 goto install_for_win8_1
IF %MajorVer%%MinorVer% EQU 100 goto install_for_win10

goto install_for_win10
REM force to install_for_win10, if cannot get the windows version

:install_for_server2003
:install_for_server2003r2
:install_for_winxp
:install_for_winxppro
ECHO ##############################################
ECHO install DirectX 9.29.1974(latest supported)
ECHO ##############################################
    REM https://support.microsoft.com/en-us/help/179113/how-to-install-the-latest-version-of-directx
    ECHO DirectX 9 only need on Windows XP and Windows Server 2003
    ECHO other Windows Version included DirectX, but it is the New Version of DirectX
    ECHO run DxDiag to check
    choco upgrade directx -y
ECHO ##############################################
ECHO download .Net Framework 3.5 and 4.0.3(latest supported)
ECHO ##############################################
ECHO The .NET Framework 4.0.3 is the latest supported on Windows XP and Windows Server 2003.
ECHO The .NET Framework 3.5 can be used to run applications built for .NET Framework 1.0 through 3.5.
    IF NOT EXIST "%~dp0dotnetfx35.exe" curl -o "%~dp0dotnetfx35.exe" -k "http://download.microsoft.com/download/2/0/E/20E90413-712F-438C-988E-FDAA79A8AC3D/dotnetfx35.exe"
    IF NOT EXIST "%~dp0dotNetFx40_Full_x86_x64.exe" curl -o "%~dp0dotNetFx40_Full_x86_x64.exe" -k "http://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe"
ECHO ##############################################
ECHO Flash Player - ActiveX(Internet Explorer)
ECHO ##############################################
  ECHO Note: This package is only supported on Windows XP to Windows 7, 
  ECHO because Windows 8 already contains an integrated Flash Player on Internet Explorer.
  ECHO Warning: The installation of Flash Player ActiveX fails with a 1603 error when Internet Explorer is open.
  choco upgrade flashplayeractivex -y
goto Finish_First_Install

:install_for_server2008
:install_for_vista
ECHO ##############################################
ECHO install .Net Framework 4.6(latest supported)
ECHO ##############################################
ECHO The .NET Framework 4.6 is the latest supported on Windows Vista and Windows Server 2008.
choco upgrade dotnet4.6 -y
DISM /Online /Enable-Feature /FeatureName:NetFx3 /NoRestart
rem unknow
ECHO ##############################################
ECHO Flash Player - ActiveX(Internet Explorer)
ECHO ##############################################
  ECHO Note: This package is only supported on Windows XP to Windows 7, 
  ECHO because Windows 8 already contains an integrated Flash Player on Internet Explorer.
  ECHO Warning: The installation of Flash Player ActiveX fails with a 1603 error when Internet Explorer is open.
  choco upgrade flashplayeractivex -y
goto Finish_First_Install

:install_for_server2008r2
:install_for_win7
ECHO ##############################################
ECHO install .Net Framework 4.7.2
ECHO ##############################################
ECHO The .NET Framework 4.7.2 is the latest version. It is supported on Windows 7 SP1 and Windows Server 2008 R2.
choco upgrade dotnet4.7.2 -y
DISM /Online /Enable-Feature /FeatureName:NetFx3 /NoRestart
rem In Windows 7, /All is not a valid option, just leave it out
goto Finish_First_Install

:install_for_server2012
ECHO ##############################################
ECHO install .Net Framework 4.7.2
ECHO ##############################################
ECHO The .NET Framework 4.7.2 is the latest version. It is supported on Windows Server 2012.
choco upgrade dotnet4.7.2 -y
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All
goto Finish_First_Install

:install_for_win8
ECHO ##############################################
ECHO install .Net Framework 4.6(latest supported)
ECHO ##############################################
ECHO The .NET Framework 4.6 is the latest supported on Windows 8.
choco upgrade dotnet4.6 -y
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All
goto Finish_First_Install

:install_for_server2012r2
:install_for_win8_1
ECHO The .NET Framework 4.7.2 is the latest version. It is supported on Windows 8.1 and Windows Server 2012 R2 
choco upgrade dotnet4.7.2 -y
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All
goto Finish_First_Install

:install_for_server2016
:install_for_win10
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All
goto Finish_First_Install

:Finish_First_Install
mkdir "%~dp0choco_upgrade"
echo. > "%~dp0choco_upgrade\choco_upgrade.first.lock"
if exist "%~dp0choco_upgrade\choco_upgrade.force.server.txt" goto Windows_Server_General_Update
if exist "%~dp0choco_upgrade\choco_upgrade.force.client.txt" goto Windows_Client_General_Update
if defined IsServer goto Windows_Server_General_Update
goto Windows_Client_General_Update

:Windows_Client_General_Update
if exist "%~dp0choco_upgrade\choco_upgrade.force.tree-dev.txt" goto Tree_Dev
choco upgrade javaruntime -y
choco upgrade silverlight -y
choco upgrade k-litecodecpackfull -y
choco upgrade vlc -y 
choco upgrade skype -y
choco upgrade teamviewer -y
choco upgrade dropbox -y
choco upgrade googledrive -y
REM choco upgrade ccleaner -y
IF %MajorVer%%MinorVer% LSS 100 choco upgrade adobereader-update -y

:Windows_Server_General_Update
if exist "%~dp0choco_upgrade\choco_upgrade.force.tree-dev.txt" goto Tree_Dev
choco upgrade googlechrome -y
choco upgrade -y peazip curl md5
goto The_END



:Tree_Dev
choco upgrade chocolateygui -y
choco upgrade -y peazip wget curl md5
choco upgrade -y googlechrome chromium firefoxesr opera adblockplusie
REM choco upgrade -y vivaldi
REM choco upgrade -y javaruntime silverlight
choco upgrade -y k-litecodecpackfull vlc
REM choco upgrade -y skype
REM choco upgrade -y google-hangouts-chrome
choco upgrade -y acrylic-dns-proxy
choco upgrade -y sql-server-2017 sql-server-management-studio
choco upgrade -y dbeaver
REM choco upgrade heroku-cli
REM choco upgrade cacher -y
rem choco upgrade -y eclipse orwelldevcpp
choco upgrade -y visualstudiocode atom notepadplusplus kdiff3
choco upgrade -y sourcetree github git winscp putty filezilla
REM choco upgrade teamviewer -y
choco upgrade -y --ignore-checksums google-backup-and-sync google-drive-file-stream
REM choco upgrade -y megasync dropbox owncloud-client
choco upgrade -y sass composer
choco upgrade -y ruby
gem install compass
goto The_END



REM choco upgrade windjview -y
REM choco upgrade webdeploy -y
REM choco upgrade lastpass -y
REM choco upgrade lastpass-for-applications -y
REM choco upgrade keeweb -y
choco upgrade -y wsus-offline-update
choco upgrade -y gcloudsdk nodejs
choco upgrade -y screentogif 
choco upgrade -y docker-for-windows docker-kitematic
choco upgrade -y docker docker-compose docker-toolbox






choco upgrade -y imdisk-toolkit


goto The_END
REM monogodb gui 
choco upgrade -y robo3t


REM k8s
REM https://www.jamessturtevant.com/posts/Running-Kubernetes-Minikube-on-Windows-10-with-WSL/
REM choco upgrade -y kubernetes-cli virtualbox
choco upgrade -y minikube
Get-NetAdapter  
New-VMSwitch -name minikube  -NetAdapterName <your-network-adapter-name> -AllowManagementOS $true  
minikube start --vm-driver hyperv --hyperv-virtual-switch minikube
kubectl get nodes

minikube ssh
minikube dashboard


:The_END
echo ##############################################
echo ##############################################
echo ##############################################
echo ##############################################
echo ##############################################
timeout 86400
exit