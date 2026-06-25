@echo off
cls
chcp 65001

if "%1"=="" (
    set PROJECT=examples
) else (
    set PROJECT=examples\%1
)

rem cd ..


del /Q .target\*.*

if not exist "ppl7.exe" goto COMPILE
del ppl7.exe

:COMPILE
dub build --parallel --build=debug --config=test --arch=x86_64 --compiler=dmd


if not exist "ppl7.exe" goto FAIL
ppl7.exe %PROJECT%


if not exist ".target\test.exe" goto FAIL
call getfilesize.bat .target\test.exe
echo.
echo Running [.target\test.exe] (%filesize% bytes)
echo.
.target\test.exe
IF %ERRORLEVEL% NEQ 0 (
  echo.
  echo.
  echo !! Exit code was %ERRORLEVEL%
)
echo.
goto END


:FAIL


:END

echo.
