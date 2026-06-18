# Mouse Activity Simulator — Build & Setup Instructions

## Project Structure

```
MouseActivitySimulator/
├── MouseActivitySimulator.xcodeproj        ← создать в Xcode
└── MouseActivitySimulator/
    ├── MouseActivitySimulatorApp.swift     ← @main, App entry point
    ├── AppDelegate.swift                   ← NSApplicationDelegate + NSWindowDelegate
    ├── Info.plist                          ← bundle metadata
    ├── MouseActivitySimulator.entitlements ← отключён sandbox
    ├── Models/
    │   └── SimulationConfig.swift          ← параметры симуляции
    ├── Services/
    │   ├── MouseSimulationService.swift    ← CGEvent-движки (DispatchSourceTimer)
    │   ├── HotKeyManager.swift             ← Carbon RegisterEventHotKey
    │   └── MenuBarManager.swift            ← NSStatusBar + NSMenu
    ├── ViewModels/
    │   └── SimulationViewModel.swift       ← ObservableObject / MVVM
    └── Views/
        ├── ContentView.swift               ← корневой + SimulatorView
        └── PermissionView.swift            ← экран запроса доступа
```

---

## 1. Создание проекта в Xcode 16

1. **File → New → Project**
2. Выбрать шаблон: **macOS → App**
3. Настройки:
   - Product Name: `MouseActivitySimulator`
   - Team: `<ваша команда>`
   - Bundle Identifier: `com.yourname.MouseActivitySimulator`
   - Interface: **SwiftUI**
   - Life Cycle: **SwiftUI App**
   - Language: **Swift**
   - ✅ Include Tests — по желанию
4. Сохранить проект.

---

## 2. Добавление файлов

1. Удалить файлы-заглушки, которые Xcode создаёт автоматически (`ContentView.swift`, `<AppName>App.swift`).
2. Создать группы (папки) в навигаторе проекта:
   - `Models`, `Services`, `ViewModels`, `Views`
3. Перетащить или скопировать все `.swift`-файлы в соответствующие группы.
4. Убедиться, что у каждого файла стоит галочка **Target Membership → MouseActivitySimulator**.

---

## 3. Настройка Build Settings

### Signing & Capabilities
- **Signing**: Automatic, выбрать свою команду
- **Hardened Runtime**: включить (`ENABLE_HARDENED_RUNTIME = YES`)
- **App Sandbox**: **ОТКЛЮЧИТЬ** (иначе CGEvent не может постить глобальные события)

### Info.plist
Xcode 16 использует `Info.plist` из папки таргета. Убедитесь, что в Build Settings:
```
INFOPLIST_FILE = MouseActivitySimulator/Info.plist
```

### Entitlements
В Build Settings (Signing):
```
CODE_SIGN_ENTITLEMENTS = MouseActivitySimulator/MouseActivitySimulator.entitlements
```

### Deployment Target
```
MACOSX_DEPLOYMENT_TARGET = 14.0
```

### Swift Version
```
SWIFT_VERSION = 5.0
```

### Frameworks (автоматически, но проверьте)
- `Carbon.framework` — для RegisterEventHotKey в HotKeyManager
- `CoreGraphics.framework` — для CGEvent
- `AppKit.framework` — автоматически
- Добавить через: **Build Phases → Link Binary With Libraries**

---

## 4. Выдача разрешения Accessibility

После первого запуска приложение само откроет окно запроса.

**Ручные шаги:**
1. Запустить приложение (⌘R).
2. Нажать **Open Settings** — откроется раздел Privacy & Security.
3. Перейти: **System Settings → Privacy & Security → Accessibility**
4. Нажать `+` или включить тумблер рядом с **Mouse Activity Simulator**.
5. Ввести пароль администратора, если потребуется.
6. Вернуться в приложение, нажать **Check Again**.

> **Важно:** каждый раз, когда бинарный файл пересобирается (меняется подпись), macOS сбрасывает разрешение. Нужно добавить приложение снова.

---

## 5. Упаковка в .app (Direct Distribution)

### Шаг 1 — Archive
```
Product → Archive
```

### Шаг 2 — Export
В Organizer нажать **Distribute App**:
- **Direct Distribution** (вне App Store)
- Выбрать **Export** или **Notarize**

### Шаг 3 — Нотаризация (обязательна для macOS 14+)
```bash
xcrun notarytool submit MouseActivitySimulator.zip \
    --apple-id "your@email.com" \
    --team-id  "XXXXXXXXXX" \
    --password "xxxx-xxxx-xxxx-xxxx" \
    --wait

xcrun stapler staple MouseActivitySimulator.app
```

### Шаг 4 — DMG (опционально)
```bash
hdiutil create -volname "Mouse Activity Simulator" \
    -srcfolder MouseActivitySimulator.app \
    -ov -format UDZO \
    MouseActivitySimulator.dmg
```

---

## 6. Горячие клавиши

| Комбинация | Действие              |
|------------|-----------------------|
| ⌃⌥⌘S       | Запустить симуляцию   |
| ⌃⌥⌘X       | Остановить симуляцию  |
| ⌃⌥⌘P       | Пауза / Продолжение   |
| ⌃⌥⌘R       | Сброс статистики      |

Горячие клавиши работают системно через Carbon `RegisterEventHotKey` — активны, даже когда приложение не на переднем плане.

---

## 7. Особенности реализации

| Компонент               | Технология                             |
|-------------------------|----------------------------------------|
| Движение курсора        | `CGEvent(.mouseMoved)` + cubic ease    |
| Клики                   | `CGEvent(.leftMouseDown/.Up)`          |
| Таймер событий          | `DispatchSourceTimer` (фоновый поток)  |
| Глобальные хоткеи       | Carbon `RegisterEventHotKey`           |
| Статус-бар              | `NSStatusBar` + `NSMenu`              |
| Анимация в окне         | SwiftUI `@Published` + `Timer`         |
| Архитектура             | MVVM (`SimulationViewModel`)           |

---

## 8. Известные ограничения

- **App Store**: не совместимо — CGEvent с `.cghidEventTap` запрещён в sandbox.
- **Multi-display**: курсор ограничен главным экраном (`NSScreen.main`).
- **Sleep**: симуляция не предотвращает переход Mac в сон — используйте `caffeinate` или `PMAssertion` параллельно при необходимости.
