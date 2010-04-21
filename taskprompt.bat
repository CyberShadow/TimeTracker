@echo off
set /P TASK=New task: 
if "%TASK%"=="" exit
WorkOn %TASK%
