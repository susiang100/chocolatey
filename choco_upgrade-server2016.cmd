@echo off
:Detect_WhichOne_WindowsVersion
IF "%OS%"=="Windows_NT" GOTO Is_WindowsNT
GOTO Is_Windows9x
:Is_Windows9x
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
REM 3.2 - Windows 3.2
REM [ Windows 9x ]
REM 4.00 - Windows 95
REM 4.10 - Windows 98
REM 4.90 - Windows ME
EXIT

:Is_WindowsNT
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
for /f "delims=[] tokens=2" %%i in ( 'ver ') do set WindowsVersion=%%i
for /f "tokens=2" %%i in ( 'echo %WindowsVersion% ') do set WindowsVersion=%%i
echo WindowsVersion == %WindowsVersion%
for /f "tokens=1,2,3 delims=." %%i in ( 'echo %WindowsVersion% ') do (
  set MajorVer=%%i  && set MinorVer=%%j && set RTMBuild=%%k
)
echo MajorVer == %MajorVer%
echo MinorVer == %MinorVer%
echo RTMBuild == %RTMBuild%
if %MajorVer% LSS 6 (
  echo NO SUPPORT
  pause
  exit
)

:creat_scheduled_tasks
cls
ECHO [Creating scheduled tasks]
setlocal
set runlevel=
REM Get OS version from registry
for /f "tokens=2*" %%i in ('reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "CurrentVersion"') do set os_ver=%%j
REM Set run level (for Vista or later - version 6)
if /i "%os_ver:~,1%" GEQ "6" set runlevel=/rl HIGHEST
REM SCHTASKS /Create /TN "%~n0%~x0" /TR "%~f0" /SC MONTHLY /MO 1 /F /ru SYSTEM %runlevel%
SCHTASKS /Create /TN "%~n0%~x0" /TR "%~f0" /SC MONTHLY /MO 1 /F /ru administrators %runlevel%
IF %ERRORLEVEL% EQU 0 goto firstWindows
IF %ERRORLEVEL% NEQ 0 color ce && timeout 60 && goto creat_scheduled_tasks



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
ECHO     Windows Version: %WindowsVersion%
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

for /f "tokens=1" %%i in ( 'curl -k -s https://raw.githubusercontent.com/susiang100/chocolatey/master/choco_upgrade-server2016.md5?t=%dateMyFomat%') do set md5_remote_choco_upgrade=%%i
for /f "tokens=1" %%i in ( 'md5 -l -n %~dp0%~n0%~x0') do set md5_local_choco_upgrade=%%i
echo     Md5 check local: [%md5_local_choco_upgrade%]
echo    Md5 check remote: [%md5_remote_choco_upgrade%]
ECHO  ------------------------------------------------------------------------------
ECHO.
IF %md5_remote_choco_upgrade% NEQ %md5_local_choco_upgrade% goto update_this_cmd_file
GOTO Windows_DoSome



:update_this_cmd_file
ECHO ############################
ECHO ### Update this CMD file ###
ECHO ############################
set run=curl -o %~dp0temp_%~n0%~x0 -k https://raw.githubusercontent.com/susiang100/chocolatey/master/choco_upgrade-server2016.cmd
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
timeout 1000
goto firstWindows

md5 -l -n %~dp0temp_%~n0%~x0
curl -Ok https://raw.githubusercontent.com/susiang100/chocolatey/master/choco_upgrade.cmd




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
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
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
echo ##############################################
rem choco upgrade vcredist2005 -y
echo ##############################################
rem choco upgrade vcredist2008 -y
echo ##############################################
rem choco upgrade vcredist2010 -y
echo ##############################################
rem choco upgrade vcredist2012 -y
echo ##############################################
rem choco upgrade vcredist2013 -y
echo ##############################################
rem choco upgrade vcredist2015 -y
echo ##############################################
rem choco upgrade dotnet4.6.2 -y
echo ##############################################
REM choco upgrade flashplayerplugin -y
echo ##############################################
REM choco upgrade flashplayeractivex -y
echo ##############################################
REM choco upgrade javaruntime -y
echo ##############################################
REM choco upgrade silverlight -y
echo ##############################################
rem choco upgrade k-litecodecpackfull -y
echo ##############################################
choco upgrade peazip -y
echo ##############################################
choco upgrade googlechrome -y
echo ##############################################
REM choco upgrade ccleaner -y
echo ##############################################
rem choco upgrade teamviewer -y
echo ##############################################
rem choco upgrade skype -y
echo ##############################################
rem choco upgrade dropbox -y
echo ##############################################
rem choco upgrade googledrive -y
rem choco upgrade google-drive-file-stream -y
rem choco upgrade google-backup-and-sync -y
echo ##############################################
rem choco upgrade adobereader-update -y
echo ##############################################
rem choco upgrade windjview -y
echo ##############################################
rem choco upgrade vlc -y
echo ##############################################
choco upgrade curl -y
echo ##############################################
choco upgrade md5 -y
echo ##############################################
choco upgrade visualstudio2017community -y
timeout 300
exit
