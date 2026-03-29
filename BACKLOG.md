# YAMP — Бэклог

## В работе

## Запланировано
1. **Найти CSS-селекторы всех кнопок** — запустить `python3 get_track.py dump`, найти лайк, play, next, prev
2. **Глобальные хоткеи** — привязать Cmd+Shift+... к play/pause, next, prev, лайк через CDP
3. **Кнопка лайка** — в hover-панель и/или хоткей
4. **Починить play/pause/next/prev** — правильные селекторы в DOM
5. **Автозапуск Яндекс Музыки с --remote-debugging-port** — чтобы не вводить вручную
6. Launch at Login
7. GitHub Actions автосборка

## Сделано
- MVP: показ трека в menu bar через CDP
- Hover-панель с кнопками (визуально работает)
- Настройка длины строки
- Меню по клику (трек, артист, controls, lyrics, settings, quit)
