@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion
title Universal Deploy System

cd /d "%~dp0"
cd ..

:: Проверка наличия папки deploy
if not exist "deploy" mkdir "deploy"

:: Загружаем конфигурацию
if not exist "deploy\config.json" (
    echo.
    echo ╔════════════════════════════════════════════════════╗
    echo ║           🚀 ДОБРО ПОЖАЛОВАТЬ!                     ║
    echo ║  Похоже, это первый запуск в этом проекте.         ║
    echo ║  Давайте создадим конфигурацию.                    ║
    echo ╚════════════════════════════════════════════════════╝
    echo.
    goto first_setup
)

:: Извлекаем данные через временный JS скрипт
echo var fso = WScript.CreateObject("Scripting.FileSystemObject"); > deploy\parse.js
echo var data = fso.OpenTextFile("deploy\\config.json", 1).ReadAll(); >> deploy\parse.js
echo var json = eval("(" + data + ")"); >> deploy\parse.js
echo function safe(v) { return (v || "").toString().trim(); } >> deploy\parse.js
echo WScript.Echo("set \"PROJECT_NAME=" + safe(json.project.name) + "\""); >> deploy\parse.js
echo WScript.Echo("set \"REPO_URL=" + safe(json.github.repository_url) + "\""); >> deploy\parse.js
echo WScript.Echo("set \"BRANCH=" + safe(json.github.branch) + "\""); >> deploy\parse.js
echo WScript.Echo("set \"SSH_HOST=" + safe(json.hosting.ssh_host) + "\""); >> deploy\parse.js
echo WScript.Echo("set \"SSH_USER=" + safe(json.hosting.ssh_user) + "\""); >> deploy\parse.js
echo WScript.Echo("set \"SSH_PASS=" + safe(json.hosting.ssh_password) + "\""); >> deploy\parse.js
echo WScript.Echo("set \"REMOTE_PATH=" + safe(json.hosting.remote_path) + "\""); >> deploy\parse.js

cscript //nologo deploy\parse.js > deploy\env.bat
if exist deploy\env.bat (
    call deploy\env.bat
    del deploy\env.bat
)
if exist deploy\parse.js del deploy\parse.js

:menu
cls
echo.
echo ╔════════════════════════════════════════════════════╗
echo ║              🚀 UNIVERSAL DEPLOY 🚀                ║
echo ╠════════════════════════════════════════════════════╣
echo ║                                                    ║
echo ║  📂 Проект: !PROJECT_NAME!                        ║  
echo ║  🌐 GitHub: !REPO_URL!
echo ║  🖥️  Хостинг: !SSH_USER!@!SSH_HOST!               ║
echo ║                                                    ║
echo ╠════════════════════════════════════════════════════╣
echo ║                                                    ║
echo ║  1. 📤 Сохранить в GitHub (+ Авто-деплой Action)  ║
echo ║  2. 🔗 Только залить на сервер (SSH с ПК)         ║
echo ║  3. 🚀 Ручной деплой (В Git и сразу на Сервер)    ║
echo ║  4. 🤖 Настроить GitHub Actions (Авто-деплой)     ║
echo ║  5. ⚙️  Изменить настройки                         ║
echo ║  6. 📊 Статус                                      ║
echo ║  7. ❌ Выход                                       ║
echo ║                                                    ║
echo ╚════════════════════════════════════════════════════╝
echo.

set /p choice="Выберите опцию (1-7): "

if "%choice%"=="1" goto github_deploy
if "%choice%"=="2" goto ssh_deploy  
if "%choice%"=="3" goto full_deploy
if "%choice%"=="4" goto setup_actions
if "%choice%"=="5" goto configure
if "%choice%"=="6" goto status
if "%choice%"=="7" goto exit
goto invalid

:first_setup
echo ⚙️  ПЕРВОНАЧАЛЬНАЯ НАСТРОЙКА
echo ════════════════════════════════
echo.
set /p "PROJECT_NAME=📌 Имя проекта (по-английски): "
set /p "REPO_URL=🌐 URL репозитория GitHub (https://github.com/user/repo.git): "
set /p "BRANCH=🌿 Ветка GitHub (master/main) [master]: "
if "!BRANCH!"=="" set "BRANCH=master"

echo.
echo 🔑 Настройки SSH (хостинг)
set /p "SSH_HOST=🖥️  Хост (например, host.beget.com): "
set /p "SSH_USER=👤 Пользователь SSH: "
set /p "SSH_PASS=🔑 Пароль SSH: "
set /p "REMOTE_PATH=📂 Путь на сервере (например, ~/public_html): "

goto save_full_config

:configure
cls
echo ⚙️  ИЗМЕНЕНИЕ НАСТРОЕК
echo ══════════════════════════
echo Введите новые данные (или Enter, чтобы оставить старые)
echo.

set /p "new_project_name=📌 Имя проекта [!PROJECT_NAME!]: "
if not "!new_project_name!"=="" set "PROJECT_NAME=!new_project_name!"

set /p "new_repo_url=🌐 URL репозитория GitHub [!REPO_URL!]: "
if not "!new_repo_url!"=="" set "REPO_URL=!new_repo_url!"

set /p "new_branch=🌿 Ветка GitHub [!BRANCH!]: "
if not "!new_branch!"=="" set "BRANCH=!new_branch!"

echo.
echo 🔑 Настройки SSH
set /p "new_ssh_host=🖥️  Хост [!SSH_HOST!]: "
if not "!new_ssh_host!"=="" set "SSH_HOST=!new_ssh_host!"

set /p "new_ssh_user=👤 Пользователь [!SSH_USER!]: "
if not "!new_ssh_user!"=="" set "SSH_USER=!new_ssh_user!"

set /p "new_ssh_pass=🔑 Пароль [*******]: "
if not "!new_ssh_pass!"=="" set "SSH_PASS=!new_ssh_pass!"

set /p "new_remote_path=📂 Путь [!REMOTE_PATH!]: "
if not "!new_remote_path!"=="" set "REMOTE_PATH=!new_remote_path!"

:save_full_config
echo.
echo 💾 Сохраняем настройки в deploy\config.json...

(
echo {
echo   "project": {
echo     "name": "!PROJECT_NAME!",
echo     "description": "Auto-generated project"
echo   },
echo   "github": {
echo     "repository_url": "!REPO_URL!",
echo     "branch": "!BRANCH!",
echo     "auto_commit": true
echo   },
echo   "hosting": {
echo     "provider": "custom",
echo     "ssh_host": "!SSH_HOST!",
echo     "ssh_user": "!SSH_USER!",
echo     "ssh_password": "!SSH_PASS!",
echo     "remote_path": "!REMOTE_PATH!",
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
) > deploy\config.json

echo ✅ Настройки сохранены!
if exist deploy\parse.js del deploy\parse.js
if exist deploy\env.bat del deploy\env.bat
pause
goto menu

:github_deploy
echo.
echo 📤 GITHUB ДЕПЛОЙ
echo ═══════════════════
echo.

:: Проверяем git
git status >nul 2>&1
if errorlevel 1 (
    echo ❌ Git репозиторий не инициализирован.
    echo Инициализируем...
    git init
    git remote add origin !REPO_URL!
) else (
    :: Проверяем, совпадает ли URL, и исправляем если нет
    for /f "tokens=*" %%u in ('git remote get-url origin') do set "CURRENT_REMOTE=%%u"
    
    if not "!CURRENT_REMOTE!"=="!REPO_URL!" (
        echo ⚠️  URL репозитория изменился!
        echo Было: !CURRENT_REMOTE!
        echo Стало: !REPO_URL!
        echo Обновляем...
        git remote set-url origin !REPO_URL!
    )
)

:: Проверка и создание .gitignore
if not exist ".gitignore" (
    echo 📄 Создаем .gitignore...
    (
        echo # WordPress
        echo wp-config.php
        echo wp-content/uploads/
        echo wp-content/cache/
        echo.
        echo # Deploy system
        echo deploy/config.json
        echo.
        echo # Logs
        echo *.log
        echo.
        echo # IDE
        echo .vscode/
        echo .idea/
        echo.
        echo # OS files
        echo .DS_Store
        echo Thumbs.db
        echo.
        echo # Dependencies
        echo node_modules/
        echo.
        echo # System
        echo .gitignore
        echo deploy/
    ) > ".gitignore"
    echo ✅ .gitignore создан!
)

echo Добавляем файлы...
git add .

set /p commit_msg="💬 Сообщение коммита (Enter для автоматического): "
if "!commit_msg!"=="" (
    for /f "tokens=1-3 delims=./ " %%a in ('date /t') do (
        for /f "tokens=1-2 delims=: " %%d in ('time /t') do (
            set "commit_msg=Деплой %%c.%%b.%%a %%d:%%e"
        )
    )
)

echo Коммит: !commit_msg!
git commit -m "!commit_msg!"

:: Определяем текущую ветку
for /f "tokens=*" %%a in ('git branch --show-current') do set "CURRENT_BRANCH=%%a"
if "!CURRENT_BRANCH!"=="" set "CURRENT_BRANCH=master"

echo.
echo 🌿 Текущая ветка: !CURRENT_BRANCH!
echo 🎯 Целевая ветка: !BRANCH!

echo Загружаем на GitHub...
git push origin !CURRENT_BRANCH!:!BRANCH!

if errorlevel 1 (
    echo.
    echo ❌ Ошибка загрузки.
    echo 🔧 Попытка Force Push ^(если истории разошлись^)...
    set /p force_push="🔥 Выполнить Force Push? (y/n): "
    if /i "!force_push!"=="y" (
        git push origin !CURRENT_BRANCH!:!BRANCH! --force
        if not errorlevel 1 echo ✅ Успешно загружено (Force Push^)^^!
    )
) else (
    echo ✅ Успешно загружено на GitHub!
)
pause
goto menu

:ssh_deploy
call :ssh_deploy_process
pause
goto menu

:ssh_deploy_process
echo.  
echo 🔗 SSH ДЕПЛОЙ НА ХОСТИНГ
echo ══════════════════════════
echo.

:: Проверяем SSH клиент
where scp >nul 2>&1 || where plink >nul 2>&1
if errorlevel 1 (
    echo ❌ SSH клиент не найден!
    echo Установите PuTTY или OpenSSH
    exit /b 1
)

echo 📦 Подготавливаем файлы...
set "temp_dir=temp_deploy_%random%"
mkdir "%temp_dir%"

:: Копируем основные типы файлов (можно расширить список)
echo Копирование PHP, CSS, JS...
xcopy *.php "%temp_dir%\" /y /q >nul 2>&1
xcopy *.css "%temp_dir%\" /y /q >nul 2>&1  
xcopy *.js "%temp_dir%\" /y /q >nul 2>&1
xcopy *.html "%temp_dir%\" /y /q >nul 2>&1

:: Копируем папки рекурсивно
if exist assets xcopy assets "%temp_dir%\assets\" /s /i /y /q >nul 2>&1
if exist inc xcopy inc "%temp_dir%\inc\" /s /i /y /q >nul 2>&1
if exist html xcopy html "%temp_dir%\html\" /s /i /y /q >nul 2>&1

:: Убираем конфиг (безопасность)
if exist "%temp_dir%\deploy" rmdir /s /q "%temp_dir%\deploy"

echo 🚀 Загружаем на сервер...

:: Создаем директории на сервере
where plink >nul 2>&1
if not errorlevel 1 (
    echo y | plink -ssh -l "!SSH_USER!" -pw "!SSH_PASS!" "!SSH_HOST!" "mkdir -p !REMOTE_PATH!"
) else (
    ssh "!SSH_USER!@!SSH_HOST!" "mkdir -p !REMOTE_PATH!"
)

:: Загрузка
where pscp >nul 2>&1
if not errorlevel 1 (
    echo y | pscp -r -pw "!SSH_PASS!" "%temp_dir%\*" "!SSH_USER!@!SSH_HOST!:!REMOTE_PATH!/"
) else (
    scp -r "%temp_dir%\*" "!SSH_USER!@!SSH_HOST!:!REMOTE_PATH!/"
)

rmdir /s /q "%temp_dir%"
echo ✅ SSH деплой завершен!
exit /b 0

:full_deploy
echo.
echo 🚀 ПОЛНЫЙ ДЕПЛОЙ (GitHub + Хостинг)
echo ═══════════════════════════════════
echo 1️⃣  Сохраняем и отправляем на GitHub...
call :github_deploy_silent
echo.
echo 2️⃣  Загружаем файлы на хостинг...
call :ssh_deploy_process
echo.
echo ✅ Полный деплой завершен!
pause
goto menu

:setup_actions
echo.
echo 🤖 НАСТРОЙКА GITHUB ACTIONS
echo ════════════════════════════
echo.

:: 1. Проверяем GH CLI
where gh >nul 2>&1
if errorlevel 1 (
    echo ⚠️  GitHub CLI (gh^) не найден.
    echo Попытка установки через Winget...
    winget install --id GitHub.cli -e --source winget
    if errorlevel 1 (
         echo ❌ Не удалось установить GH CLI.
         echo Установите вручную: https://cli.github.com/
         pause
         goto menu
    )
    set "PATH=%PATH%;%ProgramFiles%\GitHub CLI"
)

:: 2. Авторизация
echo 🔑 Проверка авторизации GitHub...
gh auth status >nul 2>&1
if errorlevel 1 (
    echo Требуется вход в систему...
    gh auth login -p https -w
)

:: ПРОВЕРКА ЛОКАЛЬНОГО СОЕДИНЕНИЯ (ПРЕЖДЕ ЧЕМ ОТПРАВЛЯТЬ)
echo.
echo 🔍 Проверка SSH соединения с хостингом...
where plink >nul 2>&1
if not errorlevel 1 (
    echo y | plink -ssh -l "!SSH_USER!" -pw "!SSH_PASS!" "!SSH_HOST!" "exit" >nul 2>&1
    if errorlevel 1 (
        echo.
        echo ❌ ОШИБКА: Ваши логин или пароль НЕ РАБОТАЮТ!
        echo Сервер !SSH_HOST! отверг подключение.
        echo.
        echo Логин: '!SSH_USER!'
        echo Пароль: ******* (проверьте config.json)
        echo.
        pause
        goto menu
    ) else (
        echo ✅ Логин и пароль верные!
    )
) else (
    echo ⚠️ Plink не найден, пропускаем локальную проверку...
)

:: 3. Создаем Workflow
echo [1/2] 📝 Обновляем файл workflow...
if not exist ".github\workflows" mkdir ".github\workflows"
(
    echo name: Deploy to Hosting
    echo on:
    echo   push:
    echo     branches: [ "master", "main" ]
    echo jobs:
    echo   deploy:
    echo     runs-on: ubuntu-latest
    echo     steps:
    echo       - name: Checkout Repository
    echo         uses: actions/checkout@v3
    echo       - name: Deploy to Hosting
    echo         uses: appleboy/scp-action@master
    echo         with:
    echo           host: ${{ secrets.SSH_HOST }}
    echo           username: ${{ secrets.SSH_USER }}
    echo           password: ${{ secrets.SSH_PASSWORD }}
    echo           source: "."
    echo           target: ${{ secrets.REMOTE_PATH }}
    echo           strip_components: 0
    echo           debug: true
) > ".github\workflows\deploy.yml"
echo ✅ Файл workflow обновлен (включен debug режим).

:: 4. Настройка секретов
echo [2/2] 🔐 Загрузка секретов в репозиторий (!REPO_SLUG!)...
echo.

:: ПРОВЕРКА: Пароль в памяти
if "!SSH_PASS!"=="" (
    echo ⚠️  Пароль не загружен из конфига.
    set /p "SSH_PASS=🔑 Введите SSH пароль для отправки: "
)

:: ПРОВЕРКА: Если все равно пустой
if "!SSH_PASS!"=="" (
    echo ❌ ОШИБКА: Пароль пустой! Нечего отправлять.
    pause
    goto menu
)

echo ⏳ Отправляем секреты...

:: Обычные поля
echo   1. SSH_HOST
echo !SSH_HOST! | gh secret set SSH_HOST -R "!REPO_SLUG!"
echo   2. SSH_USER
echo !SSH_USER! | gh secret set SSH_USER -R "!REPO_SLUG!"
echo   3. REMOTE_PATH
echo !REMOTE_PATH! | gh secret set REMOTE_PATH -R "!REPO_SLUG!"

:: Пароль (через PowerShell для надежности)
echo   4. SSH_PASSWORD
powershell -Command "[IO.File]::WriteAllText('pass.tmp', '!SSH_PASS!')"

if not exist pass.tmp (
    echo ❌ Не удалось создать временный файл с паролем.
    pause
    goto menu
)

gh secret set SSH_PASSWORD -R "!REPO_SLUG!" < pass.tmp
del pass.tmp

if errorlevel 1 (
    echo ❌ Ошибка GitHub CLI при отправке пароля.
) else (
    echo ✅ Пароль успешно загружен!
)

echo.
echo 📊 Проверка списка секретов на GitHub:
gh secret list -R "!REPO_SLUG!"
echo.
echo (Если вы видите список выше - значит связь есть)
pause
goto menu

:github_deploy_silent
git add . >nul 2>&1
git commit -m "Auto deploy" >nul 2>&1
git push origin !BRANCH!
if errorlevel 1 git push origin !BRANCH! --force
exit /b

:status
echo.
echo 📊 СТАТУС
git status
pause
goto menu

:exit
exit
:invalid
goto menu
echo 📊 СТАТУС ПРОЕКТА  
echo ══════════════════
echo.
git status 2>nul || echo ❌ Git не инициализирован
git remote -v 2>nul
echo.
where scp >nul 2>&1 && echo ✅ SCP найден || echo ❌ SCP не найден
where plink >nul 2>&1 && echo ✅ PuTTY найден || echo ❌ PuTTY не найден
echo.
pause
goto menu

:github_deploy_silent
echo   • Коммит и Push...
git add . >nul 2>&1
git commit -m "Автоматический деплой %date% %time%" >nul 2>&1
git push origin !BRANCH!
echo   ✅ Готово
exit /b

:invalid
echo ❌ Неверный выбор!
timeout /t 2 >nul
goto menu

:exit
echo 👋 До свидания!
timeout /t 1 >nul
