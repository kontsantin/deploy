@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "SSH_PORT=2222"
set "SSH_KEY_PATH=C:\Users\user\.ssh\deploy_hosting"
set "SSH_HOST=109.196.102.2"
set "SSH_USER=root"
set "REMOTE_PATH=/root/gggg"
set "SSH_PASS="

echo START
if not defined SSH_PORT set "SSH_PORT=22"
if not defined SSH_KEY_PATH set /p "SSH_KEY_PATH=Path: "
if not exist "%SSH_KEY_PATH%" (
  echo KEY MISS
  exit /b 1
)
if not exist ".github\workflows" mkdir ".github\workflows"
echo STEP1
powershell -NoProfile -ExecutionPolicy Bypass -File "write-workflow.ps1" -OutPath ".github\workflows\deploy.yml"
if errorlevel 1 (
  echo WF FAIL
  exit /b 1
)
echo STEP2
where gh >nul 2>&1
if errorlevel 1 (
  echo GH MISSING
  exit /b 0
)
gh secret set SSH_HOST --body "%SSH_HOST%"
if errorlevel 1 echo GH1 FAIL

gh secret set SSH_USER --body "%SSH_USER%"
if errorlevel 1 echo GH2 FAIL

gh secret set SSH_PORT --body "%SSH_PORT%"
if errorlevel 1 echo GH3 FAIL

gh secret set REMOTE_PATH --body "%REMOTE_PATH%"
if errorlevel 1 echo GH4 FAIL

gh secret set SSH_KEY < "%SSH_KEY_PATH%"
if errorlevel 1 echo GH5 FAIL

if defined SSH_PASS gh secret set SSH_PASSWORD --body "%SSH_PASS%" >nul 2>&1

echo DONE
