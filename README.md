# Universal Deploy (Windows)

Короткий batch-скрипт для деплоя проекта: GitHub push, локальный SSH/SCP деплой и настройка GitHub Actions.

## Что в репозитории
- `deploy.bat` — основное меню деплоя.
- `read-config.ps1` — чтение `deploy/config.json`.
- `write-workflow.ps1` — генерация `.github/workflows/deploy.yml`.
- `deploy/config.json` — создается/обновляется скриптом.

## Требования
- Windows + PowerShell.
- `git`.
- Для SSH-деплоя: `ssh`+`scp` (OpenSSH) или `plink`+`pscp` (PuTTY).
- Для пункта `4` (Actions): `gh` (GitHub CLI) и авторизация `gh auth login`.

## Быстрый старт
```powershell
git clone https://github.com/ver-tuego/deploy-test.git
cd deploy-test
.\deploy.bat
```

При первом запуске скрипт попросит:
- `REPO_URL` (ваш GitHub репозиторий),
- SSH данные (`SSH_HOST`, `SSH_PORT`, `SSH_USER`, `SSH_KEY_PATH`, `REMOTE_PATH`),
- при необходимости `SSH_PASS` как fallback.

## Меню
1. Сохранить изменения в GitHub.
2. Залить на сервер (локальный SSH деплой).
3. Полный деплой (1 + 2).
4. Настроить GitHub Actions (workflow + secrets).
5. Изменить настройки.
6. Проверить статус.
7. Выход.

## Важно
- Пункт `4` отправляет secrets в репозиторий, который берется из `REPO_URL` в конфиге.
- Перед `4` проверьте `REPO_URL` через пункт `5`, чтобы secrets не ушли в другой репозиторий.
