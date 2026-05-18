@echo off
setlocal
REM Usage: deploy.cmd [dev|staging|prod]

set "STAGE=%~1"
if "%STAGE%"=="" set "STAGE=dev"
if not "%AWS_REGION%"=="" (set "REGION=%AWS_REGION%") else (set "REGION=us-west-2")

if /I not "%STAGE%"=="dev" if /I not "%STAGE%"=="staging" if /I not "%STAGE%"=="prod" (
  echo Error: stage must be dev, staging, or prod
  exit /b 1
)

cd /d "%~dp0..\.."
if errorlevel 1 exit /b 1

where npx >nul 2>&1
if errorlevel 1 (
  echo Error: Node.js/npx is required.
  exit /b 1
)

if not exist "node_modules\" (
  echo ==^> Installing Serverless dependencies...
  call npm install
  if errorlevel 1 exit /b 1
)

echo ==^> Backend deploy ^(Serverless^) ^| stage=%STAGE% ^| region=%REGION%
call npx serverless deploy --stage %STAGE% --region %REGION%
if errorlevel 1 exit /b 1

echo.
echo ==^> Endpoints:
call npx serverless info --stage %STAGE% --region %REGION%

where aws >nul 2>&1
if not errorlevel 1 (
  echo.
  echo ==^> Stack outputs:
  aws cloudformation describe-stacks --stack-name cloud-formation-api-%STAGE% --region %REGION% --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" --output table 2>nul
)

endlocal
