# setup_github.ps1 — создаёт GitHub-репозиторий и запускает CI-сборку DMG
# Запуск: правой кнопкой по файлу → "Run with PowerShell"
#         или в терминале: powershell -ExecutionPolicy Bypass -File setup_github.ps1

param(
    [string]$Token    = "",   # GitHub PAT (если передан аргументом)
    [string]$RepoName = "MouseActivitySimulator",
    [switch]$Private  = $true
)

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ─── Цвета ────────────────────────────────────────────────────────────────────
function Write-Step  { param($msg) Write-Host "`n▶  $msg" -ForegroundColor Cyan }
function Write-OK    { param($msg) Write-Host "   ✓  $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "   ⚠  $msg" -ForegroundColor Yellow }
function Write-Fail  { param($msg) Write-Host "`n✗  ОШИБКА: $msg" -ForegroundColor Red; Read-Host "Нажмите Enter"; exit 1 }

Clear-Host
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Mouse Activity Simulator — Публикация на GitHub CI   " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan

# ─── Шаг 0: Проверка git ──────────────────────────────────────────────────────
Write-Step "Проверка git"
try   { $v = git --version 2>&1; Write-OK $v }
catch { Write-Fail "git не найден. Установите: https://git-scm.com/download/win" }

# ─── Шаг 1: GitHub Personal Access Token ────────────────────────────────────
Write-Step "GitHub Personal Access Token (PAT)"
Write-Host ""
Write-Host "   Как получить PAT (1 минута):" -ForegroundColor White
Write-Host "   1. Открыть: https://github.com/settings/tokens/new" -ForegroundColor Gray
Write-Host "   2. Note: MouseActivitySimulator" -ForegroundColor Gray
Write-Host "   3. Expiration: 7 days" -ForegroundColor Gray
Write-Host "   4. Scopes: поставить галочку [x] repo" -ForegroundColor Gray
Write-Host "   5. Нажать 'Generate token', скопировать" -ForegroundColor Gray
Write-Host ""

if ($Token -eq "") {
    # Открываем браузер на странице создания токена
    Start-Process "https://github.com/settings/tokens/new?description=MouseActivitySimulator&scopes=repo"
    $secureToken = Read-Host "   Вставьте токен (ghp_...)" -AsSecureString
    $Token = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                 [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken))
}

if ($Token -notmatch "^gh[ps]_") {
    Write-Fail "Токен должен начинаться с ghp_ или ghs_"
}
Write-OK "Токен принят"

# ─── Шаг 2: GitHub username ───────────────────────────────────────────────────
Write-Step "Получение GitHub username"
$headers = @{
    Authorization = "Bearer $Token"
    Accept        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

try {
    $user = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
    $username = $user.login
    Write-OK "Вы вошли как: $username"
} catch {
    Write-Fail "Ошибка авторизации. Проверьте токен.`nОтвет: $($_.Exception.Message)"
}

# ─── Шаг 3: Создать репозиторий ───────────────────────────────────────────────
Write-Step "Создание репозитория $username/$RepoName"

$repoUrl   = "https://github.com/$username/$RepoName"
$cloneUrl  = "https://$Token@github.com/$username/$RepoName.git"

# Проверяем, существует ли уже репо
try {
    $existing = Invoke-RestMethod -Uri "https://api.github.com/repos/$username/$RepoName" `
                                  -Headers $headers -ErrorAction Stop
    Write-Warn "Репозиторий уже существует: $repoUrl"
    $useExisting = Read-Host "   Использовать существующий? (y/n)"
    if ($useExisting -ne "y") { Write-Fail "Отмена" }
} catch {
    # 404 = репо не существует, создаём
    $body = @{
        name        = $RepoName
        description = "macOS mouse activity simulator — keeps your session active"
        private     = [bool]$Private
        auto_init   = $false
    } | ConvertTo-Json

    try {
        $repo = Invoke-RestMethod -Uri "https://api.github.com/user/repos" `
                                  -Method Post -Headers $headers `
                                  -Body $body -ContentType "application/json"
        Write-OK "Репозиторий создан: $repoUrl"
    } catch {
        Write-Fail "Не удалось создать репозиторий: $($_.Exception.Message)"
    }
}

# ─── Шаг 4: git init + commit ──────────────────────────────────────────────
Write-Step "Инициализация git и первый коммит"

$projectDir = $PSScriptRoot

Set-Location $projectDir

# Инициализируем если ещё не git-репо
if (-not (Test-Path ".git")) {
    git init -q
    Write-OK "git init"
}

# Настраиваем remote
$remotes = git remote 2>&1
if ($remotes -match "origin") {
    git remote set-url origin $cloneUrl
    Write-OK "Remote 'origin' обновлён"
} else {
    git remote add origin $cloneUrl
    Write-OK "Remote 'origin' добавлен"
}

# Настраиваем автора если не задан
$gitUser  = git config user.name  2>&1
$gitEmail = git config user.email 2>&1
if (-not $gitUser  -or $gitUser  -match "^fatal") {
    git config user.name  $username
    git config user.email "$username@users.noreply.github.com"
}

git branch -M main 2>&1 | Out-Null

# Stage + commit
git add . 2>&1 | Out-Null
$staged = git diff --cached --name-only 2>&1
if ($staged) {
    git commit -m "Initial commit: Mouse Activity Simulator v1.0.0" -q
    Write-OK "Коммит создан ($(@($staged).Count) файлов)"
} else {
    Write-Warn "Нет изменений для коммита (уже закоммичено)"
}

# ─── Шаг 5: Push ──────────────────────────────────────────────────────────────
Write-Step "git push → GitHub"

git push -u origin main --force 2>&1 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }

if ($LASTEXITCODE -ne 0) {
    Write-Fail "Push не удался. Проверьте права токена (нужен scope: repo)."
}
Write-OK "Код загружен на GitHub"

# ─── Шаг 6: Запустить workflow вручную (workflow_dispatch) ────────────────────
Write-Step "Запуск GitHub Actions workflow"

Start-Sleep -Seconds 3   # Даём GitHub секунду зарегистрировать пуш

$dispatchBody = @{ ref = "main" } | ConvertTo-Json

try {
    Invoke-RestMethod `
        -Uri     "https://api.github.com/repos/$username/$RepoName/actions/workflows/build.yml/dispatches" `
        -Method  Post `
        -Headers $headers `
        -Body    $dispatchBody `
        -ContentType "application/json" | Out-Null
    Write-OK "Workflow запущен"
} catch {
    Write-Warn "Автозапуск не удался (workflow уже мог запуститься от push): $($_.Exception.Message)"
}

# ─── Шаг 7: Открыть браузер ───────────────────────────────────────────────────
Write-Step "Открываем GitHub Actions в браузере"
$actionsUrl = "https://github.com/$username/$RepoName/actions"
Start-Process $actionsUrl
Write-OK "Браузер открыт: $actionsUrl"

# ─── Итог ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "   ✓  Готово!                                          " -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "   Репозиторий : $repoUrl" -ForegroundColor White
Write-Host "   Actions     : $actionsUrl" -ForegroundColor White
Write-Host ""
Write-Host "   Сборка займёт ~5-8 минут. Когда появится" -ForegroundColor Gray
Write-Host "   зелёная галочка → кликните на неё → раздел" -ForegroundColor Gray
Write-Host "   Artifacts → скачайте MouseActivitySimulator-1.0.0-macOS.zip" -ForegroundColor Gray
Write-Host ""
Read-Host "Нажмите Enter для выхода"
