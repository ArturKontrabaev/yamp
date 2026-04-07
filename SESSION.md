# YAMP — Yandex Music Player

## Последнее обновление
2026-04-07

## Статус
Стабильная рабочая версия. Опубликован на GitHub.

## Что работает
- Показ трека в menu bar (артист — название)
- Now Playing popover (обложка, трек, артист, кнопки)
- Play/Pause, Next, Previous, Like, Dislike через CDP
- Глобальные настраиваемые хоткеи
- Выбор иконки menu bar
- Настройка размера шрифта
- Hide track on pause
- Launch at login
- Автоматическая обёртка для Яндекс Музыки (CDP всегда включен)
- Авто-переустановка обёртки при обновлении ЯМ
- Кнопка Quit в попover
- Like только добавляет (не убирает)
- Определение liked state через SVG xlink:href
- **Уведомления через Notification Center** (osascript) — при лайке показывает ♥ Артист — Трек, при дизлайке 👎

## Репо
https://github.com/ArturKontrabaev/yamp

## Что не доделано
- Раздельный размер иконки и шрифта (сломалось, откатили)
- Cmd+Q (убивает другие приложения, нужно переделать)
- Иконка приложения (в Dock/Launchpad)
- Прогресс-бар (сломал базовый функционал, откатили)
- Автосборка через GitHub Actions (токену не хватает workflow scope)

## Сборка
killall YAMP; cd ~/yamp && git pull && cd YAMP && ./build.sh && open build/YAMP.app

Для установки в /Applications:
killall YAMP; cd ~/yamp && git pull && cd YAMP && ./build.sh && sudo cp -R build/YAMP.app /Applications/YAMP.app && open /Applications/YAMP.app
