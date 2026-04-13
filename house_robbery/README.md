# house_robbery

Prosty skrypt rabowania domow pod `es_extended`, `ox_lib` i `ox_inventory`.

## Wymagania

- `es_extended`
- `ox_lib`
- `ox_inventory`

## Instalacja

1. Wrzuc folder `house_robbery` do `resources`.
2. Dodaj do `server.cfg`:

```cfg
ensure ox_lib
ensure ox_inventory
ensure es_extended
ensure house_robbery
```

3. Upewnij sie, ze w `ox_inventory/data/items.lua` masz przedmioty uzyte w configu:
- `lockpick`
- `goldchain`
- `diamond_ring`
- `rolex`
- `black_money` lub zmien nagrody pod swoj serwer

## Konfiguracja

W pliku `config.lua` zmienisz:

- liczbe wymaganej policji
- cooldown
- godziny rabunku
- wymagany item
- nagrody
- domy i pozycje przeszukiwania

## Jak dziala

- Gracz podchodzi do domu i wciska `E`
- System sprawdza godzine, cooldown, policje i `lockpick`
- Po wejsciu do interioru gracz przeszukuje punkty
- Kazdy punkt mozna przeszukac tylko raz
- Po wyjsciu wlacza sie cooldown na dom
