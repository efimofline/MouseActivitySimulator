#!/usr/bin/env bash
# =============================================================================
# build_dmg.sh — сборка Mouse Activity Simulator и упаковка в DMG
#
# Использование:
#   chmod +x build_dmg.sh
#   ./build_dmg.sh                   # автоматический режим
#   ./build_dmg.sh --adhoc           # ad-hoc подпись (без Developer ID)
#   ./build_dmg.sh --developer-id    # Developer ID подпись (нужен сертификат)
#   ./build_dmg.sh --notarize        # Developer ID + нотаризация Apple
#
# Требования:
#   - macOS 14+ (Sonoma)
#   - Xcode 16 с command-line tools: xcode-select --install
# =============================================================================

set -euo pipefail

# ─── Цвета для вывода ────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

step()    { echo -e "\n${BOLD}${BLUE}▶ $*${NC}"; }
ok()      { echo -e "  ${GREEN}✓${NC} $*"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $*"; }
die()     { echo -e "\n  ${RED}✗ ОШИБКА:${NC} $*\n"; exit 1; }

# ─── Конфигурация ────────────────────────────────────────────────────────────
APP_NAME="MouseActivitySimulator"
SCHEME="MouseActivitySimulator"
VERSION="1.0.0"
BUNDLE_ID="com.yourname.MouseActivitySimulator"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
DMG_STAGING="$BUILD_DIR/dmg_staging"
DMG_VOLUME="$APP_NAME $VERSION"
DMG_OUTPUT="$SCRIPT_DIR/$APP_NAME-$VERSION.dmg"
TMP_DMG="$BUILD_DIR/tmp_rw.dmg"

# ─── Аргументы ───────────────────────────────────────────────────────────────
MODE="auto"
NOTARIZE=false

for arg in "$@"; do
    case $arg in
        --adhoc)        MODE="adhoc" ;;
        --developer-id) MODE="developer-id" ;;
        --notarize)     MODE="developer-id"; NOTARIZE=true ;;
    esac
done

# ─── Проверки окружения ──────────────────────────────────────────────────────
step "Проверка окружения"

[[ "$(uname)" == "Darwin" ]] || die "Скрипт работает только на macOS"

command -v xcodebuild >/dev/null 2>&1 || \
    die "Xcode не найден. Установите: xcode-select --install"

command -v hdiutil >/dev/null 2>&1 || \
    die "hdiutil не найден (нужен macOS)"

XCODE_VER=$(xcodebuild -version | head -1)
ok "$XCODE_VER"
ok "hdiutil $(hdiutil version | head -1)"
ok "Скрипт-директория: $SCRIPT_DIR"

# ─── Определение режима подписи ──────────────────────────────────────────────
if [[ "$MODE" == "auto" ]]; then
    # Проверяем наличие Developer ID сертификата в Keychain
    if security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
        MODE="developer-id"
        ok "Найден Developer ID сертификат → режим: developer-id"
    else
        MODE="adhoc"
        warn "Developer ID сертификат не найден → режим: ad-hoc (только локальное использование)"
    fi
fi

ok "Режим сборки: ${BOLD}$MODE${NC}"

# ─── Очистка ─────────────────────────────────────────────────────────────────
step "Очистка предыдущей сборки"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$EXPORT_DIR" "$DMG_STAGING"
ok "build/ очищена"

# ─── Archive ─────────────────────────────────────────────────────────────────
step "xcodebuild archive (Release)"

SIGN_FLAGS=()
if [[ "$MODE" == "adhoc" ]]; then
    SIGN_FLAGS=(
        CODE_SIGN_IDENTITY="-"
        CODE_SIGNING_REQUIRED=YES
        CODE_SIGN_STYLE=Manual
        DEVELOPMENT_TEAM=""
    )
fi

xcodebuild archive \
    -project "$SCRIPT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -archivePath "$ARCHIVE_PATH" \
    "${SIGN_FLAGS[@]}" \
    ONLY_ACTIVE_ARCH=NO \
    2>&1 | grep -E "(error:|warning:|FAILED|BUILD SUCCEEDED|Compiling|Linking)" || true

[[ -d "$ARCHIVE_PATH" ]] || die "Архив не создан. Запустите с полным выводом:\n  xcodebuild archive ... 2>&1 | tee build.log"
ok "Архив: $ARCHIVE_PATH"

# ─── Export .app ─────────────────────────────────────────────────────────────
step "Export .app"

if [[ "$MODE" == "adhoc" ]]; then
    # Для ad-hoc просто копируем .app из архива
    APP_IN_ARCHIVE=$(find "$ARCHIVE_PATH/Products" -name "*.app" -maxdepth 3 | head -1)
    [[ -n "$APP_IN_ARCHIVE" ]] || die ".app не найден в архиве"
    cp -R "$APP_IN_ARCHIVE" "$EXPORT_DIR/$APP_NAME.app"
    ok "Скопировано из архива (ad-hoc)"
else
    # Для Developer ID используем ExportOptions.plist
    EXPORT_PLIST="$SCRIPT_DIR/ExportOptions.plist"
    [[ -f "$EXPORT_PLIST" ]] || die "ExportOptions.plist не найден"

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_DIR" \
        -exportOptionsPlist "$EXPORT_PLIST" \
        2>&1 | grep -E "(error:|Exported|FAILED)" || true

    ok "Экспортировано с Developer ID"
fi

APP_PATH="$EXPORT_DIR/$APP_NAME.app"
[[ -d "$APP_PATH" ]] || die ".app не найден: $APP_PATH"
ok "App: $APP_PATH"

# ─── Нотаризация (опционально) ───────────────────────────────────────────────
if $NOTARIZE; then
    step "Нотаризация Apple"
    warn "Укажите переменные окружения перед запуском:"
    warn "  export APPLE_ID=your@email.com"
    warn "  export APPLE_TEAM_ID=XXXXXXXXXX"
    warn "  export APPLE_APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx"

    [[ -n "${APPLE_ID:-}"       ]] || die "APPLE_ID не задан"
    [[ -n "${APPLE_TEAM_ID:-}"  ]] || die "APPLE_TEAM_ID не задан"
    [[ -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]] || die "APPLE_APP_SPECIFIC_PASSWORD не задан"

    # Создаём zip для notarytool
    NOTARIZE_ZIP="$BUILD_DIR/${APP_NAME}_notarize.zip"
    ditto -c -k --keepParent "$APP_PATH" "$NOTARIZE_ZIP"

    ok "Отправляем на нотаризацию..."
    xcrun notarytool submit "$NOTARIZE_ZIP" \
        --apple-id     "$APPLE_ID" \
        --team-id      "$APPLE_TEAM_ID" \
        --password     "$APPLE_APP_SPECIFIC_PASSWORD" \
        --wait \
        --timeout 30m

    ok "Прикрепляем staple-ticket..."
    xcrun stapler staple "$APP_PATH"
    ok "Нотаризация завершена"
fi

# ─── Staging: заполняем временную папку для DMG ───────────────────────────────
step "Подготовка содержимого DMG"
cp -R "$APP_PATH" "$DMG_STAGING/$APP_NAME.app"
ln -sf /Applications "$DMG_STAGING/Applications"
ok "Содержимое DMG готово"

# ─── Создание временного RW-образа ───────────────────────────────────────────
step "Создание DMG"

# Вычисляем нужный размер (+20MB запас)
APP_SIZE_KB=$(du -sk "$DMG_STAGING" | awk '{print $1}')
DMG_SIZE_MB=$(( (APP_SIZE_KB / 1024) + 25 ))

hdiutil create \
    -srcfolder "$DMG_STAGING" \
    -volname   "$DMG_VOLUME" \
    -fs        HFS+ \
    -fsargs    "-c c=64,a=16,b=16" \
    -format    UDRW \
    -size      "${DMG_SIZE_MB}m" \
    "$TMP_DMG" \
    > /dev/null

ok "Временный образ создан (${DMG_SIZE_MB} MB)"

# ─── Монтируем и настраиваем внешний вид окна Finder ─────────────────────────
DEVICE=$(hdiutil attach \
    -readwrite -noverify -noautoopen \
    "$TMP_DMG" 2>/dev/null \
    | awk '/^\/dev\/disk/ {print $1; exit}')

MOUNT="/Volumes/$DMG_VOLUME"

ok "Образ смонтирован: $MOUNT (device: $DEVICE)"

# AppleScript: настраиваем окно Finder
osascript - "$DMG_VOLUME" "$APP_NAME" <<'APPLESCRIPT' || warn "Кастомизация Finder пропущена (не критично)"
on run {volumeName, appName}
    tell application "Finder"
        tell disk volumeName
            open
            set current view of container window to icon view
            set toolbar visible    of container window to false
            set statusbar visible  of container window to false
            set bounds             of container window to {200, 120, 760, 450}
            set theViewOptions to the icon view options of container window
            set arrangement  of theViewOptions to not arranged
            set icon size    of theViewOptions to 128
            -- Позиции иконок: приложение слева, Applications справа
            set position of item (appName & ".app") of container window to {160, 175}
            set position of item "Applications"     of container window to {400, 175}
            close
            open
            update without registering applications
            delay 3
            close
        end tell
    end tell
end run
APPLESCRIPT

sync
hdiutil detach "$DEVICE" -quiet
ok "Образ отмонтирован"

# ─── Конвертируем в сжатый read-only DMG ─────────────────────────────────────
hdiutil convert "$TMP_DMG" \
    -format   UDZO \
    -imagekey zlib-level=9 \
    -o        "$DMG_OUTPUT" \
    > /dev/null

rm -f "$TMP_DMG"

# ─── Проверяем DMG ───────────────────────────────────────────────────────────
hdiutil verify "$DMG_OUTPUT" > /dev/null && ok "DMG верифицирован" || warn "Верификация не прошла"

# ─── Итог ────────────────────────────────────────────────────────────────────
DMG_SIZE=$(du -sh "$DMG_OUTPUT" | awk '{print $1}')

echo ""
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  ✓ Готово!${NC}"
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "  Файл:  ${BOLD}$DMG_OUTPUT${NC}"
echo -e "  Размер: $DMG_SIZE"
echo -e "  Режим:  $MODE"
if [[ "$MODE" == "adhoc" ]]; then
    echo ""
    warn "Ad-hoc сборка: работает только на вашем Mac."
    warn "Для раздачи другим пользователям нужен Developer ID."
fi
if ! $NOTARIZE && [[ "$MODE" == "developer-id" ]]; then
    echo ""
    warn "Нотаризация не выполнена. Для дистрибуции запустите:"
    warn "  ./build_dmg.sh --notarize"
fi
echo ""
