# house_robbery

Zaawansowany skrypt rabowania domow pod `es_extended`, `ox_lib` i `ox_inventory`.

## Co dostajesz

- pelny flow napadu z czasem na rabunek
- system alarmu i alertu dla policji
- skillchecki przy wlamaniu, sejfie i przeszukiwaniu
- rozne tier-y domow i pule lootu
- broker zlecen z kontraktem na konkretny dom
- dedykowany HUD NUI pokazujacy status rabunku
- wsparcie dla `ox_target` jesli zasob jest uruchomiony
- fallback na klasyczne `E`, jesli nie chcesz targeta

## Wymagania

- `es_extended`
- `ox_lib`
- `ox_inventory`

## Opcjonalnie

- `ox_target`

## Instalacja

1. Wrzuc folder `house_robbery` do `resources`.
2. Dodaj do `server.cfg`:

```cfg
ensure ox_lib
ensure ox_inventory
ensure es_extended
ensure house_robbery
```

3. Jesli chcesz target:

```cfg
ensure ox_target
```

4. Upewnij sie, ze masz itemy z configu w `ox_inventory/data/items.lua`.

## Gdzie konfigurowac

- balans i timery: `config.lua`
- broker i kontrakty: `config.lua`
- domy, spoty, sejfy i tier: `config.lua`
- logike klienta: `client.lua`
- logike sesji, alarmu i lootu: `server.lua`
- wyglad HUD: `web/style.css`

## Uwagi

- policja dostaje waypoint na dom po alarmie
- kontrakt mozna wziac od brokera przed rabunkiem
- loot jest liczony przez pule nagrod
- safe spot moze miec osobny reward pool
- po wyjsciu lub disconnectcie wlacza sie cooldown
