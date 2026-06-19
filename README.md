# Mouse Activity Simulator

Утилита для macOS, которая имитирует активность мыши — перемещение курсора и клики — чтобы предотвратить переход системы в режим сна, блокировку экрана или отключение по таймеру бездействия.

## Возможности

- **Случайное перемещение курсора** — плавное движение с кубической интерполяцией (ease-in-out), настраиваемое расстояние от 1 до 200 px
- **Имитация кликов** — случайные одиночные клики с настраиваемой вероятностью (5–50 %)
- **Гибкие интервалы** — задержка между действиями от 1 до 120 секунд
- **Глобальные горячие клавиши** — работают в любом приложении:
  - `⌃⌥⌘S` — Старт
  - `⌃⌥⌘X` — Стоп
  - `⌃⌥⌘P` — Пауза / Продолжить
  - `⌃⌥⌘R` — Сбросить статистику
- **Иконка в строке меню** — быстрый доступ без открытия окна
- **Статистика** — счётчик времени работы, количества движений и кликов
- **Детектор прав доступа** — подсказка по настройке Accessibility, если разрешения не выданы

## Скриншоты

| Главное окно | Окно разрешений |
|---|---|
| ![Simulator](docs/simulator.png) | ![Permission](docs/permission.png) |

## Требования

| Ветка | macOS | Xcode |
|---|---|---|
| `macos-14` (main-like) | macOS 14 Sonoma и новее | Xcode 16+ |
| `macos-10.15` | macOS 10.15 Catalina и новее | Xcode 12+ |

## Установка

### Скачать готовый DMG

Перейдите в раздел [Releases](https://github.com/efimofline/MouseActivitySimulator/releases) и скачайте актуальный `.dmg`-файл.

1. Откройте `.dmg`
2. Перетащите `Mouse Activity Simulator.app` в папку `Applications`
3. При первом запуске macOS запросит разрешение **Accessibility** — без него симуляция не работает

### Сборка из исходников

```bash
# Клонировать нужную ветку
git clone -b macos-10.15 https://github.com/efimofline/MouseActivitySimulator.git
# или для macOS 14+:
# git clone -b macos-14 https://github.com/efimofline/MouseActivitySimulator.git

cd MouseActivitySimulator

# Собрать и упаковать в DMG
xcodebuild archive \
  -project MouseActivitySimulator.xcodeproj \
  -scheme MouseActivitySimulator \
  -configuration Release \
  -archivePath /tmp/MouseActivitySimulator.xcarchive \
  CODE_SIGN_IDENTITY="-"
```

## Gatekeeper — «Не смогло проверить ПО»

Приложение собрано без платного Apple Developer ID, поэтому macOS блокирует его при первом запуске. Это не ошибка программы. Обойти можно любым из способов:

**Способ 1 — правая кнопка:**
1. Найдите `MouseActivitySimulator.app` в Finder
2. **Правая кнопка мыши → Открыть**
3. В диалоге нажмите **Открыть** ещё раз

**Способ 2 — Системные настройки:**
Системные настройки → Защита и безопасность → Основные → **Всё равно открыть**

**Способ 3 — Terminal:**
```bash
xattr -dr com.apple.quarantine /Applications/MouseActivitySimulator.app
```

Достаточно сделать один раз — macOS запомнит исключение.

---

## Разрешения

После первого запуска необходимо выдать приложению доступ к **Accessibility**:

1. Откройте **Системные настройки → Конфиденциальность и безопасность → Универсальный доступ**
2. Нажмите `+` и добавьте `Mouse Activity Simulator`
3. Перезапустите приложение или нажмите **Проверить снова** в окне подсказки

> Доступ к Accessibility требуется как для симуляции мыши, так и для работы глобальных горячих клавиш.

## Архитектура

```
MouseActivitySimulator/
├── main.swift                  # Точка входа (AppKit, macOS 10.15+)
├── AppDelegate.swift           # NSWindow + жизненный цикл приложения
├── Models/
│   └── SimulationConfig.swift  # Параметры симуляции
├── Services/
│   ├── MouseSimulationService.swift  # CGEvent, движение курсора
│   ├── HotKeyManager.swift           # CGEventTap, глобальные хоткеи
│   └── MenuBarManager.swift          # NSStatusItem, меню в строке меню
├── ViewModels/
│   └── SimulationViewModel.swift     # ObservableObject, MVVM
└── Views/
    ├── ContentView.swift        # Корневой SwiftUI-вид
    └── PermissionView.swift     # Экран запроса разрешений
```

**Стек:** Swift 5 · SwiftUI · AppKit · Combine · CoreGraphics

## CI / Автосборка

GitHub Actions собирает `.dmg` при каждом пуше в `main`. Конфигурация: [`.github/workflows/build.yml`](.github/workflows/build.yml).

## Лицензия

MIT — используйте свободно.
