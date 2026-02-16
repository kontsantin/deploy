@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title Universal Deploy System

cd /d "%~dp0"
if not exist ".git" (
    cd ..
)

if not exist "deploy" mkdir "deploy"

call :load_config
if errorlevel 1 goto first_setup
goto menu

:load_config
if not exist "deploy\config.json" exit /b 1

set "env_file=deploy\env_%random%%random%.bat"
powershell -NoProfile -ExecutionPolicy Bypass -File "read-config.ps1" -ConfigPath "deploy\config.json" -OutPath "!env_file!" >nul 2>&1
if errorlevel 1 exit /b 1
if not exist "!env_file!" exit /b 1

call "!env_file!"
del "!env_file!" >nul 2>&1

if not defined BRANCH set "BRANCH=main"
if not defined SSH_PORT set "SSH_PORT=22"
exit /b 0

:first_setup
cls
echo.
echo ============================================================
echo               ПЕРВИЧНАЯ НАСТРОЙКА DEPLOY
echo ============================================================
echo Заполните данные проекта. Позже их можно изменить в меню.
echo.
set /p "PROJECT_NAME=Название проекта: "
set /p "REPO_URL=URL GitHub репозитория (https://github.com/user/repo.git): "
set /p "BRANCH=Рабочая ветка GitHub [main]: "
if not defined BRANCH set "BRANCH=main"

echo.
echo --------------------- SSH НАСТРОЙКИ ------------------------
set /p "SSH_HOST=SSH host (например host.beget.com): "
set /p "SSH_PORT=SSH port [22]: "
if not defined SSH_PORT set "SSH_PORT=22"
set /p "SSH_USER=SSH user: "
set /p "SSH_KEY_PATH=Путь к приватному ключу (например C:\Users\user\.ssh\id_rsa): "
set /p "SSH_PASS=Пароль SSH (необязательно, fallback): "
set /p "REMOTE_PATH=Путь на сервере (например ~/public_html): "

goto save_config

:configure
cls
echo.
echo ============================================================
echo                    ИЗМЕНЕНИЕ НАСТРОЕК
echo ============================================================
echo Нажмите Enter, чтобы оставить текущее значение.

echo.
set /p "new_project_name=Имя проекта [!PROJECT_NAME!]: "
if defined new_project_name set "PROJECT_NAME=!new_project_name!"

set /p "new_repo_url=URL репозитория [!REPO_URL!]: "
if defined new_repo_url set "REPO_URL=!new_repo_url!"

set /p "new_branch=Ветка [!BRANCH!]: "
if defined new_branch set "BRANCH=!new_branch!"

echo.
echo --------------------- SSH НАСТРОЙКИ ------------------------
set /p "new_ssh_host=SSH host [!SSH_HOST!]: "
if defined new_ssh_host set "SSH_HOST=!new_ssh_host!"

set /p "new_ssh_port=SSH port [!SSH_PORT!]: "
if defined new_ssh_port set "SSH_PORT=!new_ssh_port!"

set /p "new_ssh_user=SSH user [!SSH_USER!]: "
if defined new_ssh_user set "SSH_USER=!new_ssh_user!"

set /p "new_ssh_key_path=Путь к ключу [!SSH_KEY_PATH!]: "
if defined new_ssh_key_path set "SSH_KEY_PATH=!new_ssh_key_path!"

set /p "new_ssh_pass=SSH пароль [скрыт]: "
if defined new_ssh_pass set "SSH_PASS=!new_ssh_pass!"

set /p "new_remote_path=Путь на сервере [!REMOTE_PATH!]: "
if defined new_remote_path set "REMOTE_PATH=!new_remote_path!"

goto save_config

:json_escape
setlocal EnableDelayedExpansion
set "val=!%~1!"
set "val=!val:\=\\!"
set "val=!val:"=\"!"
endlocal & set "%~2=%val%"
exit /b

:save_config
if not exist "deploy" mkdir "deploy"

call :json_escape PROJECT_NAME PROJECT_NAME_J
call :json_escape REPO_URL REPO_URL_J
call :json_escape BRANCH BRANCH_J
call :json_escape SSH_HOST SSH_HOST_J
call :json_escape SSH_PORT SSH_PORT_J
call :json_escape SSH_USER SSH_USER_J
call :json_escape SSH_PASS SSH_PASS_J
call :json_escape SSH_KEY_PATH SSH_KEY_PATH_J
call :json_escape REMOTE_PATH REMOTE_PATH_J

(
    echo {
    echo   "project": {
    echo     "name": "!PROJECT_NAME_J!",
    echo     "description": "Auto-generated project"
    echo   },
    echo   "github": {
    echo     "repository_url": "!REPO_URL_J!",
    echo     "branch": "!BRANCH_J!",
    echo     "auto_commit": true
    echo   },
    echo   "hosting": {
    echo     "provider": "custom",
    echo     "ssh_host": "!SSH_HOST_J!",
    echo     "ssh_port": "!SSH_PORT_J!",
    echo     "ssh_user": "!SSH_USER_J!",
    echo     "ssh_password": "!SSH_PASS_J!",
    echo     "ssh_key_path": "!SSH_KEY_PATH_J!",
    echo     "remote_path": "!REMOTE_PATH_J!",
    echo     "backup_enabled": true
    echo   },
    echo   "deploy": {
    echo     "exclude_files": [
    echo       "deploy/",
    echo       ".git/",
    echo       "node_modules/",
    echo       "*.log",
    echo       ".env*",
    echo       "README.md"
    echo     ],
    echo     "create_backup": true
    echo   }
    echo }
) > "deploy\config.json"

echo.
echo ============================================================
echo Настройки успешно сохранены в deploy\config.json
echo ============================================================
pause
goto menu

:menu
cls
echo.
echo ============================================================
echo                   UNIVERSAL DEPLOY (UTF-8)
echo ============================================================
echo Проект        : !PROJECT_NAME!
echo GitHub        : !REPO_URL!
echo Хостинг       : !SSH_USER!@!SSH_HOST!:!SSH_PORT!
echo Ключ SSH      : !SSH_KEY_PATH!
echo Remote path   : !REMOTE_PATH!
echo.
echo 1. Сохранить изменения в GitHub
echo 2. Залить на сервер (локальный SSH деплой)
echo 3. Полный деплой (GitHub + сервер)
echo 4. Настроить GitHub Actions (деплой по SSH ключу)
echo 5. Изменить настройки проекта
echo 6. Проверить статус
echo 7. Выход
echo.
set /p "choice=Выберите опцию (1-7): "

if "%choice%"=="1" goto github_deploy
if "%choice%"=="2" goto ssh_deploy
if "%choice%"=="3" goto full_deploy
if "%choice%"=="4" goto setup_actions
if "%choice%"=="5" goto configure
if "%choice%"=="6" goto status
if "%choice%"=="7" goto exit

echo.
echo Неверный выбор. Укажите число от 1 до 7.
timeout /t 2 >nul
goto menu

:ensure_git
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    git init
)

git remote get-url origin >nul 2>&1
if errorlevel 1 (
    git remote add origin "!REPO_URL!"
) else (
    for /f "usebackq delims=" %%u in (`git remote get-url origin`) do set "CURRENT_REMOTE=%%u"
    if /i not "!CURRENT_REMOTE!"=="!REPO_URL!" git remote set-url origin "!REPO_URL!"
)
exit /b 0

:github_deploy
call :ensure_git

echo.
echo ============================================================
echo                      GITHUB DEPLOY
echo ============================================================
echo Шаг 1/3: Добавляем файлы в индекс...
git add .

set "commit_msg="
set /p "commit_msg=Сообщение коммита (Enter = авто): "
if not defined commit_msg set "commit_msg=Deploy %date% %time%"

echo Шаг 2/3: Создаем коммит...
git commit -m "!commit_msg!" >nul 2>&1
for /f "usebackq delims=" %%b in (`git branch --show-current`) do set "CURRENT_BRANCH=%%b"
if not defined CURRENT_BRANCH set "CURRENT_BRANCH=!BRANCH!"

echo Шаг 3/3: Push в origin/!BRANCH!...
git push -u origin "!CURRENT_BRANCH!:!BRANCH!"
if errorlevel 1 (
    echo Ошибка push.
) else (
    echo Успешно отправлено в GitHub.
)
pause
goto menu

:ssh_deploy
echo.
echo ============================================================
echo                     SSH ДЕПЛОЙ (ЛОКАЛЬНО)
echo ============================================================
call :ssh_deploy_process
pause
goto menu

:ssh_deploy_process
if not defined SSH_HOST (
    echo Ошибка: не задан SSH_HOST.
    exit /b 1
)
if not defined SSH_USER (
    echo Ошибка: не задан SSH_USER.
    exit /b 1
)
if not defined REMOTE_PATH (
    echo Ошибка: не задан REMOTE_PATH.
    exit /b 1
)
if not defined SSH_PORT set "SSH_PORT=22"

echo Подготовка файлов к отправке...

if defined SSH_KEY_PATH (
    if exist "!SSH_KEY_PATH!" goto ssh_with_key
)
if defined SSH_PASS goto ssh_with_password

echo Не найден корректный путь к SSH ключу и нет SSH пароля для fallback.
exit /b 1

:ssh_with_key
where ssh >nul 2>&1
if errorlevel 1 (
    echo Не найден ssh клиент.
    exit /b 1
)
where scp >nul 2>&1
if errorlevel 1 (
    echo Не найден scp клиент.
    exit /b 1
)

echo Подключаемся к серверу по SSH ключу...
echo Создаем директорию назначения...
ssh -i "!SSH_KEY_PATH!" -p !SSH_PORT! -o StrictHostKeyChecking=accept-new "!SSH_USER!@!SSH_HOST!" "mkdir -p \"!REMOTE_PATH!\""
if errorlevel 1 (
    echo Ошибка подключения к серверу по ключу.
    exit /b 1
)

echo Загружаем файлы по SSH ключу...
scp -i "!SSH_KEY_PATH!" -P !SSH_PORT! -o StrictHostKeyChecking=accept-new -r ".\*" "!SSH_USER!@!SSH_HOST!:!REMOTE_PATH!/"
if errorlevel 1 (
    echo Ошибка загрузки файлов по SSH key.
    exit /b 1
)

echo SSH деплой завершен (ключ).
exit /b 0

:ssh_with_password
where plink >nul 2>&1
if errorlevel 1 (
    echo Для деплоя по паролю нужен plink.
    exit /b 1
)
where pscp >nul 2>&1
if errorlevel 1 (
    echo Для деплоя по паролю нужен pscp.
    exit /b 1
)

echo Ключ не найден. Используем fallback по паролю...
echo Создаем директорию на сервере (пароль)...
echo y | plink -ssh -P !SSH_PORT! -l "!SSH_USER!" -pw "!SSH_PASS!" "!SSH_HOST!" "mkdir -p !REMOTE_PATH!" >nul
if errorlevel 1 (
    echo Ошибка подключения к серверу по паролю.
    exit /b 1
)

echo Загружаем файлы (пароль)...
echo y | pscp -P !SSH_PORT! -r -pw "!SSH_PASS!" ".\*" "!SSH_USER!@!SSH_HOST!:!REMOTE_PATH!/" >nul
if errorlevel 1 (
    echo Ошибка загрузки файлов по паролю.
    exit /b 1
)

echo SSH деплой завершен (пароль fallback).
exit /b 0

:setup_actions
echo.
echo ============================================================
echo                 НАСТРОЙКА GITHUB ACTIONS
echo ============================================================
where gh >nul 2>&1
if errorlevel 1 (
    echo Не найден GitHub CLI ^(gh^). Установите: https://cli.github.com/
    pause
    goto menu
)

gh auth status >nul 2>&1
if errorlevel 1 (
    echo Требуется авторизация в GitHub CLI. Откроется окно входа.
    gh auth login -p https -w
)

if not defined SSH_PORT set "SSH_PORT=22"
if not defined SSH_KEY_PATH set /p "SSH_KEY_PATH=Путь к приватному ключу для GitHub Actions: "
if not exist "%SSH_KEY_PATH%" (
    echo Файл ключа не найден: %SSH_KEY_PATH%
    pause
    goto menu
)

if not exist ".github\workflows" mkdir ".github\workflows"
echo Шаг 1/2: Создаем workflow .github\workflows\deploy.yml
powershell -NoProfile -ExecutionPolicy Bypass -File "write-workflow.ps1" -OutPath ".github\workflows\deploy.yml"
if errorlevel 1 goto gh_secret_error

set "REPO_SLUG=!REPO_URL!"
set "REPO_SLUG=!REPO_SLUG:https://github.com/=!"
set "REPO_SLUG=!REPO_SLUG:http://github.com/=!"
set "REPO_SLUG=!REPO_SLUG:git@github.com:=!"
if "!REPO_SLUG:~-4!"==".git" set "REPO_SLUG=!REPO_SLUG:~0,-4!"
if "!REPO_SLUG:~-1!"=="/" set "REPO_SLUG=!REPO_SLUG:~0,-1!"

if "!REPO_SLUG!"=="" (
    echo Не удалось определить repo slug из REPO_URL: !REPO_URL!
    goto gh_secret_error
)

echo Шаг 2/2: Загружаем secrets в репозиторий !REPO_SLUG!...
gh secret set SSH_HOST --body "%SSH_HOST%" -R "!REPO_SLUG!"
if errorlevel 1 goto gh_secret_error
gh secret set SSH_USER --body "%SSH_USER%" -R "!REPO_SLUG!"
if errorlevel 1 goto gh_secret_error
gh secret set SSH_PORT --body "%SSH_PORT%" -R "!REPO_SLUG!"
if errorlevel 1 goto gh_secret_error
gh secret set REMOTE_PATH --body "%REMOTE_PATH%" -R "!REPO_SLUG!"
if errorlevel 1 goto gh_secret_error

gh secret set SSH_KEY -R "!REPO_SLUG!" < "%SSH_KEY_PATH%"
if errorlevel 1 goto gh_secret_error

if defined SSH_PASS gh secret set SSH_PASSWORD --body "%SSH_PASS%" -R "!REPO_SLUG!" >nul 2>&1

echo.
echo Готово. Workflow и secrets настроены.
gh secret list -R "!REPO_SLUG!"
pause
goto menu

:gh_secret_error
echo Ошибка при загрузке secrets через gh.
pause
goto menu

:github_deploy_silent
call :ensure_git
git add . >nul 2>&1
git commit -m "Auto deploy %date% %time%" >nul 2>&1
git push -u origin "!BRANCH!" >nul 2>&1
exit /b

:full_deploy
call :github_deploy_silent
call :ssh_deploy_process
pause
goto menu

:status
echo.
echo ============================================================
echo                           СТАТУС
echo ============================================================
git status 2>nul
if errorlevel 1 echo Git не инициализирован.

git remote -v 2>nul
echo.
echo SSH host: !SSH_HOST!
echo SSH user: !SSH_USER!
echo SSH port: !SSH_PORT!
echo SSH key : !SSH_KEY_PATH!
echo Remote path: !REMOTE_PATH!
pause
goto menu

:exit
exit /b 0
