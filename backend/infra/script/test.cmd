@echo off
setlocal EnableDelayedExpansion
REM Usage: test.cmd [dev|staging|prod]

set "STAGE=%~1"
if "%STAGE%"=="" set "STAGE=dev"
if not "%AWS_REGION%"=="" (set "REGION=%AWS_REGION%") else (set "REGION=us-west-2")
set "STACK_NAME=cloud-formation-api-%STAGE%"

if /I not "%STAGE%"=="dev" if /I not "%STAGE%"=="staging" if /I not "%STAGE%"=="prod" (
  echo Error: stage must be dev, staging, or prod
  exit /b 1
)

set "BASE_URL="
where aws >nul 2>&1
if not errorlevel 1 (
  for /f "delims=" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --region %REGION% --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text 2^>nul') do set "BASE_URL=%%i"
)

if "!BASE_URL!"=="" (
  cd /d "%~dp0..\.."
  for /f "tokens=*" %%i in ('npx serverless info --stage %STAGE% --region %REGION% 2^>nul ^| findstr /i "HttpApiUrl endpoint"') do (
    for %%j in (%%i) do set "BASE_URL=%%j"
  )
)

if "!BASE_URL!"=="" (
  echo Error: Could not resolve API URL for stage %STAGE%
  exit /b 1
)

echo ==^> GET !BASE_URL!/health
curl -s "!BASE_URL!/health"
echo.
echo.
echo ==^> POST !BASE_URL!/ai/chat
curl -s -X POST "!BASE_URL!/ai/chat" -H "Content-Type: application/json" -d "{\"message\":\"Hello from local test\"}"
echo.
endlocal
