@echo off
setlocal EnableDelayedExpansion
REM Usage: destroy.cmd [dev|staging|prod]

set "STAGE=%~1"
if "%STAGE%"=="" set "STAGE=dev"
if not "%AWS_REGION%"=="" (set "REGION=%AWS_REGION%") else (set "REGION=us-west-2")
set "STACK_NAME=cloud-formation-web-%STAGE%"

if /I not "%STAGE%"=="dev" if /I not "%STAGE%"=="staging" if /I not "%STAGE%"=="prod" (
  echo Error: stage must be dev, staging, or prod
  exit /b 1
)

aws cloudformation describe-stacks --stack-name %STACK_NAME% --region %REGION% >nul 2>&1
if errorlevel 1 (
  echo ==^> Stack not found.
  exit /b 0
)

set "BUCKET="
for /f "delims=" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --region %REGION% --query "Stacks[0].Outputs[?OutputKey=='WebsiteBucketName'].OutputValue" --output text 2^>nul') do set "BUCKET=%%i"

if not "!BUCKET!"=="" (
  aws s3api head-bucket --bucket !BUCKET! --region %REGION% >nul 2>&1
  if not errorlevel 1 (
    echo ==^> Emptying s3://!BUCKET!/
    aws s3 rm "s3://!BUCKET!/" --recursive --region %REGION%
  )
)

echo ==^> Deleting stack %STACK_NAME%
aws cloudformation delete-stack --stack-name %STACK_NAME% --region %REGION%
if errorlevel 1 exit /b 1

aws cloudformation wait stack-delete-complete --stack-name %STACK_NAME% --region %REGION%
if errorlevel 1 exit /b 1

echo ==^> Frontend stack deleted.
endlocal
