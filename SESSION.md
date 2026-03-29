# YAMP — Yandex Music Player (menubar app)

## Последнее обновление
2026-03-29

## Статус
MVP работает — показывает трек в menu bar. Артур решил что системный Now Playing достаточно, кроме функции "добавить в избранное".

## Что сделано
- Исследовали все способы получения трека (MediaRemote, Accessibility, window title, distributed notifications — всё заблокировано на macOS 26 Tahoe)
- Нашли рабочий подход: Chrome DevTools Protocol через `--remote-debugging-port=9222`
- MVP: menubar app показывает трек, есть hover-панель с кнопками, настройки длины
- Playback controls через CDP (нужно доработать селекторы)
- Репо: https://github.com/ArturKontrabaev/yamp

## Что не доделано
- Кнопки play/pause/next/prev — нужны правильные CSS-селекторы из DOM
- Hover-панель — кнопки кликаются но действия не срабатывают (селекторы)
- Lyrics — заготовка есть, нужно найти селектор
- Добавление в избранное — основная недостающая фичa vs системный Now Playing
- GitHub Actions для автосборки (токену не хватает workflow scope)
- Запуск Яндекс Музыки с --remote-debugging-port автоматически

## Техническое
- Сборка: `cd YAMP && chmod +x build.sh && ./build.sh && open build/YAMP.app`
- Требует: `killall "Яндекс Музыка"; open -a "Яндекс Музыка" --args --remote-debugging-port=9222`
- macOS 26 Tahoe, Swift 5.8, без Xcode (только Command Line Tools)
