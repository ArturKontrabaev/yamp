# YAMP — Yandex Music Player

## Последнее обновление
2026-03-29

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

## Репо
https://github.com/ArturKontrabaev/yamp

## Стабильный коммит
90ed388 — "auto-reinstall CDP wrapper if Yandex Music was updated"

## Что не доделано
- Раздельный размер иконки и шрифта (сломалось, откатили)
- Cmd+Q (убивает другие приложения, нужно переделать)
- Иконка приложения (в Dock/Launchpad)
- Прогресс-бар (сломал базовый функционал, откатили)
- Автосборка через GitHub Actions (токену не хватает workflow scope)

## Сборка
cd ~/yamp/YAMP && chmod +x build.sh && ./build.sh && sudo cp -R build/YAMP.app /Applications/YAMP.app
