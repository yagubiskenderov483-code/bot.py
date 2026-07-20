# Европа — стратегия для Roblox Studio

Я **не могу сам открыть ваш Place в Roblox Studio**. Ниже — как перенести готовые скрипты вручную (5–10 минут).

## Быстрый перенос (без Rojo)

1. Откройте **Roblox Studio** → ваш Place (или новый Baseplate).
2. В **Explorer** создайте структуру:

```
ReplicatedStorage
  Modules
    EuropeCountries   ← ModuleScript
    EuropeGrid        ← ModuleScript
  Remotes             ← Folder (пусто; Bootstrap создаст RemoteEvent'ы)

ServerScriptService
  Bootstrap           ← Script          (файл Bootstrap.server.lua)
  CountryState        ← ModuleScript
  WorldMapGenerator   ← Script          (файл WorldMapGenerator.server.lua)
  WarAndEconomyServer ← Script          (файл WarAndEconomyServer.server.lua)

StarterPlayer
  StarterPlayerScripts
    TopBarClient        ← LocalScript   (файл TopBarClient.client.lua)
    ActionPanelsClient  ← LocalScript   (файл ActionPanelsClient.client.lua)
```

3. Откройте каждый файл из папки `src/` в этом репозитории и **скопируйте содержимое** в соответствующий скрипт в Studio.
4. **Удалите или отключите** старые конфликтующие скрипты, если они есть:
   - `MainServer`, `GameServer`, `GameClockServer`
   - любой другой LocalScript с топ-баром / выбором страны
5. Нажмите **Play**. Должно появиться:
   - карта Европы (вода + цветные страны)
   - города и жёлтые столицы
   - топ-бар и панель слева после клика по стране

## Через Rojo (если установлен)

```bash
cd roblox-europe
rojo serve
```

В Studio: плагин Rojo → Connect → sync.

## Управление

| Действие | Как |
|----------|-----|
| Взять страну | Клик по свободной стране |
| Купить фабрику / солдат / исследование | Кнопки на панели |
| Объявить войну | Открыть чужую страну → «Объявить войну» |
| Закрыть панель | Esc |

## Важно

- Не запускайте параллельно старые серверные скрипты с той же логикой — будет двойной спавн / двойные remotes.
- `Bootstrap` обязан быть в `ServerScriptService` и стартовать раньше карты (`CharacterAutoLoads = false`).
