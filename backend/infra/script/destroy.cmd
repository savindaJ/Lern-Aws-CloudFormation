@echo off
setlocal
REM Usage: destroy.cmd [dev|staging|prod]

set "STAGE=%~1"
if "%STAGE%"=="" set "STAGE=dev"
if not "%AWS_REGION%"=="" (set "REGION=%AWS_REGION%") else (set "REGION=us-west-2")

if /I not "%STAGE%"=="dev" if /I not "%STAGE%"=="staging" if /I not "%STAGE%"=="prod" (
  echo Error: stage must be dev, staging, or prod
  exit /b 1
)

cd /d "%~dp0..\.."
if errorlevel 1 exit /b 1

echo ==^> Removing Serverless stack ^| stage=%STAGE% ^| region=%REGION%
call npx serverless remove --stage %STAGE% --region %REGION%
if errorlevel 1 exit /b 1

echo ==^> Backend stack removed.
endlocal
