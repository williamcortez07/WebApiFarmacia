@echo off
title Sistema infectado...
color 0a
echo.
echo *******************************************************************************************
echo* ALERTA: VIRUS DETECTADO
echo *******************************************************************************************
echo.
timeout /t 3 > null
:loop
echo Se ha detectado actividad sospechosa
Start cmd
timeout /t 2 > null
goto loop