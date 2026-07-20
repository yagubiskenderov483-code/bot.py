# Как запустить Rojo (чтобы игра появилась в Studio)

Rojo **не открывает Studio сам**. Нужны 2 шага: сервер + кнопка Connect в Studio.

## Шаг 1 — запустить сервер Rojo

Откройте **терминал** (PowerShell / CMD) **в этой папке репозитория** и напишите:

```bat
rojo serve
```

Должно появиться что-то вроде:

```
Rojo server listening on port 34872
```

Если пишет `rojo не распознано` — Rojo не в PATH. Тогда:

1. Установите Rojo: https://rojo.space/docs/getting-started/installation
2. Или в VS Code/Cursor: расширение **Rojo**, потом Command Palette → `Rojo: Start Server`

## Шаг 2 — подключить Studio

1. Откройте **Roblox Studio** (новый Baseplate или ваш Place)
2. Установите плагин Rojo (если ещё нет):  
   https://www.roblox.com/library/13916111004/Rojo
3. В Studio сверху / в Plugins нажмите **Rojo**
4. Нажмите **Connect** (адрес обычно `localhost:34872`)
5. Скрипты появятся в Explorer: `ServerScriptService`, `ReplicatedStorage`, и т.д.

## Частые ошибки

| Проблема | Решение |
|----------|---------|
| Открыл папку — ничего не происходит | Так и должно быть. Нужен `rojo serve`, не двойной клик по папке |
| Connect серый / не коннектится | Сначала `rojo serve` в терминале, потом Connect |
| Не тот проект | В корне репо должен быть файл `default.project.json` (уже есть) |
| Старые скрипты мешают | Удалите `MainServer`, `GameServer`, `GameClockServer` перед sync |

## Проверка

После Connect в Output Studio должно быть примерно:

```
[Europe] Bootstrap: Remotes готовы...
[Europe] Карта построена...
[Europe] WarAndEconomyServer запущен
```

Потом нажмите **Play**.
