@echo off
setlocal EnableDelayedExpansion
REM Usage: deploy.cmd [dev|staging|prod]

set "STAGE=%~1"
if "%STAGE%"=="" set "STAGE=dev"
if not "%AWS_REGION%"=="" (set "REGION=%AWS_REGION%") else (set "REGION=us-west-2")

set "INFRA_DIR=%~dp0.."
set "FRONTEND_DIR=%~dp0..\.."
set "TEMPLATE=%INFRA_DIR%template.yaml"
set "PARAMS_FILE=%INFRA_DIR%parameters\%STAGE%.json"
set "STACK_NAME=cloud-formation-web-%STAGE%"
set "BACKEND_STACK=cloud-formation-api-%STAGE%"

if /I not "%STAGE%"=="dev" if /I not "%STAGE%"=="staging" if /I not "%STAGE%"=="prod" (
  echo Error: stage must be dev, staging, or prod
  exit /b 1
)

where aws >nul 2>&1
if errorlevel 1 (
  echo Error: AWS CLI is required.
  exit /b 1
)

where npm >nul 2>&1
if errorlevel 1 (
  echo Error: Node.js/npm is required.
  exit /b 1
)

if not exist "%PARAMS_FILE%" (
  echo Error: parameters file not found: %PARAMS_FILE%
  exit /b 1
)

echo ==^> Frontend deploy ^(CloudFormation^) ^| stage=%STAGE% ^| region=%REGION%

echo ==^> Deploying stack: %STACK_NAME%
aws cloudformation deploy --template-file "%TEMPLATE%" --stack-name %STACK_NAME% --region %REGION% --parameter-overrides file://"%PARAMS_FILE%" --no-fail-on-empty-changeset
if errorlevel 1 exit /b 1

for /f "delims=" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --region %REGION% --query "Stacks[0].Outputs[?OutputKey=='WebsiteBucketName'].OutputValue" --output text') do set "BUCKET=%%i"
for /f "delims=" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --region %REGION% --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionId'].OutputValue" --output text') do set "DIST_ID=%%i"
for /f "delims=" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --region %REGION% --query "Stacks[0].Outputs[?OutputKey=='WebsiteUrl'].OutputValue" --output text') do set "WEBSITE_URL=%%i"

set "API_URL="
aws cloudformation describe-stacks --stack-name %BACKEND_STACK% --region %REGION% >nul 2>&1
if not errorlevel 1 (
  for /f "delims=" %%i in ('aws cloudformation describe-stacks --stack-name %BACKEND_STACK% --region %REGION% --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text') do set "API_URL=%%i"
)

set "VITE_STAGE=%STAGE%"
set "VITE_API_URL=!API_URL!"
set "VITE_APP_URL=!WEBSITE_URL!"

call "%~dp0build.cmd" %STAGE%
if errorlevel 1 exit /b 1

echo ==^> Uploading dist/ to s3://!BUCKET!/
aws s3 sync "%FRONTEND_DIR%\dist\" "s3://!BUCKET!/" --region %REGION% --delete --cache-control "public,max-age=31536000,immutable" --exclude "index.html" --exclude "*.html"
if errorlevel 1 exit /b 1

aws s3 sync "%FRONTEND_DIR%\dist\" "s3://!BUCKET!/" --region %REGION% --exclude "*" --include "*.html" --cache-control "public,max-age=0,must-revalidate"
if errorlevel 1 exit /b 1

echo ==^> Invalidating CloudFront cache...
aws cloudfront create-invalidation --distribution-id !DIST_ID! --paths "/*" --output text --query "Invalidation.Id" >nul

echo.
echo ==^> WebsiteUrl: !WEBSITE_URL!
endlocal
