@echo off
setlocal EnableDelayedExpansion
REM Usage: build.cmd [dev|staging|prod]

set "STAGE=%~1"
if "%STAGE%"=="" set "STAGE=dev"
if not "%AWS_REGION%"=="" (set "REGION=%AWS_REGION%") else (set "REGION=us-west-2")

if /I not "%STAGE%"=="dev" if /I not "%STAGE%"=="staging" if /I not "%STAGE%"=="prod" (
  echo Error: stage must be dev, staging, or prod
  exit /b 1
)

cd /d "%~dp0..\.."
if errorlevel 1 exit /b 1

set "VITE_STAGE=%STAGE%"
set "VITE_API_URL="
set "VITE_APP_URL="

where aws >nul 2>&1
if not errorlevel 1 (
  for /f "delims=" %%i in ('aws cloudformation describe-stacks --stack-name cloud-formation-api-%STAGE% --region %REGION% --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text 2^>nul') do set "VITE_API_URL=%%i"
  for /f "delims=" %%i in ('aws cloudformation describe-stacks --stack-name cloud-formation-web-%STAGE% --region %REGION% --query "Stacks[0].Outputs[?OutputKey=='WebsiteUrl'].OutputValue" --output text 2^>nul') do set "VITE_APP_URL=%%i"
)

echo ==^> Frontend build ^| stage=%STAGE%
call npm ci 2>nul
if errorlevel 1 call npm install
if errorlevel 1 exit /b 1
call npm run build:%STAGE%
if errorlevel 1 exit /b 1

echo ==^> Dist ready: %cd%\dist
endlocal
