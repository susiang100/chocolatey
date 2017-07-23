@echo off

:firstWindows
CLS

:getDateMyFomat
for /f %%x in ('wmic path win32_localtime get /format:list ^| findstr "="') do set %%x
if %Month% LSS 10 set Month=0%Month%
if %Day% LSS 10 set Day=0%Day%
if %Hour% LSS 10 set Hour=0%Hour%
if %Minute% LSS 10 set Minute=0%Minute%
set dateMyFomat=%Year%%Month%%Day%-%Hour%%Minute%

:check_md5_only
ECHO ######################
ECHO ### Check Md5 Only ###
ECHO ######################
curl -o %~dp0temp_check_md5_only_%~n0%~x0 -k https://raw.githubusercontent.com/susiang100/chocolatey/master/choco_upgrade.cmd?t=%dateMyFomat%

for /f "tokens=1" %%i in ( 'md5 -l -n %~dp0temp_check_md5_only_%~n0%~x0') do set md5_templocal_choco_upgrade=%%i
echo %md5_templocal_choco_upgrade% > %~dp0temp_check_md5_only_%~n0%~x0.md5

echo      Md5 check temp: [%md5_templocal_choco_upgrade%]

del /q /f "%~dp0temp_check_md5_only_%~n0%~x0"
pause
goto firstWindows

md5 -l -n %~dp0temp_%~n0%~x0
curl -Ok https://raw.githubusercontent.com/susiang100/chocolatey/master/choco_upgrade.cmd



