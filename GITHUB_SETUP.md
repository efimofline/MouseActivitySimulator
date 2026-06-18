# Сборка DMG через GitHub Actions (без Mac)

GitHub предоставляет бесплатные macOS Sonoma раннеры.
Весь процесс занимает 5–8 минут.

---

## Шаг 1 — Создать репозиторий на GitHub

1. Открыть https://github.com/new
2. Заполнить:
   - **Repository name**: `MouseActivitySimulator`
   - **Visibility**: Private (рекомендуется)
   - **НЕ ставить** галочки «Add README», «Add .gitignore» — файлы уже есть
3. Нажать **Create repository**

---

## Шаг 2 — Загрузить код

### Вариант А — через Git (PowerShell / CMD)

```powershell
# Перейти в папку проекта
cd "C:\ИИ\Мой софт\MouseActivitySimulator"

# Инициализировать git (если ещё не сделано)
git init
git branch -M main

# Добавить все файлы
git add .
git commit -m "Initial commit: Mouse Activity Simulator"

# Подключить GitHub репозиторий (заменить YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/MouseActivitySimulator.git

# Отправить
git push -u origin main
```

### Вариант Б — через GitHub Desktop (GUI)

1. Скачать GitHub Desktop: https://desktop.github.com
2. File → Add Local Repository → выбрать папку `MouseActivitySimulator`
3. Publish repository → выбрать имя и видимость

### Вариант В — загрузить ZIP через браузер

1. Запаковать папку `MouseActivitySimulator` в ZIP (без скрытых папок `.github` — их GitHub Desktop добавит автоматически)
2. Альтернатива: использовать GitHub CLI

---

## Шаг 3 — Запустить сборку

**Автоматически:** сборка запускается сама при каждом `git push` в ветку `main`.

**Вручную (кнопкой):**
1. Открыть репозиторий на GitHub
2. Перейти на вкладку **Actions**
3. В списке слева выбрать **Build & Package DMG**
4. Нажать **Run workflow** → выбрать ветку `main` → нажать зелёную кнопку

---

## Шаг 4 — Скачать DMG

1. Перейти на вкладку **Actions**
2. Кликнуть на последний запуск (зелёная галочка = успех)
3. Внизу страницы раздел **Artifacts**
4. Скачать `MouseActivitySimulator-1.0.0-macOS`
5. Распаковать ZIP → получить `.dmg`

```
Время сборки: ~5–8 минут
Артефакт хранится: 30 дней
```

---

## Выпуск версии (Release) с DMG

Чтобы создать публичный релиз со ссылкой на скачивание:

```powershell
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions автоматически создаст Release и прикрепит `.dmg`.
Ссылка будет: `https://github.com/YOUR_USERNAME/MouseActivitySimulator/releases`

---

## Мониторинг сборки

Если сборка упала (красный крестик):

1. Кликнуть на провалившийся запуск
2. Кликнуть на джоб `Build DMG (macOS Sonoma)`
3. Раскрыть шаг `xcodebuild archive`
4. Скачать артефакт `build-log` — там полный вывод компилятора

---

## Почему не Docker?

| Способ | Работает на Windows? | Сложность |
|---|---|---|
| GitHub Actions | ✅ Да, из браузера | Низкая |
| Docker-OSX (QEMU+KVM) | ❌ Нет (нет KVM в Docker Desktop) | Очень высокая |
| Swift on Linux Docker | ❌ Нет (AppKit/SwiftUI — только macOS) | Невозможно |
| Арендовать Mac (MacStadium, etc.) | ✅ Да | Средняя, платно |

GitHub Actions — единственный бесплатный способ собрать macOS-приложение без Mac.
