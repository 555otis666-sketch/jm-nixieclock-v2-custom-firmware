# Hardware notes

Confirmed on the tested Geek Styles / `JM NixieClock V2.0` board.

## Main chips

- MCU: `STM8S003F3P6`
- RTC: `DS3231NS`
- Tube driver chain: `74HC595D` shift registers plus `ULN2003G` transistor arrays
- Tubes: 6x `IN-14`

## STM8 pin map

| Function | STM8 pin | GPIO |
| --- | ---: | --- |
| 74HC595 DATA | 17 | PC7 |
| 74HC595 LATCH / RCLK | 15 | PC5 |
| 74HC595 CLOCK / SRCLK | 20 | PD3 |
| 74HC595 OE | 19 | PD2 |
| DS3231 SCL | 12 | PB4 |
| DS3231 SDA | 11 | PB5 |
| Button SET | 10 | PA3 |
| Button UP | 5 | PA1 |
| Button DOWN | 6 | PA2 |
| RGB red | - | PC3 |
| RGB blue | - | PC4 |
| RGB green | - | PC6 |
| Colon `HH:MM` | - | PD4 |
| Colon `MM:SS` | - | PD5 |

Button inputs are active low.

Colon outputs:

- low = off
- high = on

## Display driver notes

The current firmware contains the working bit mapping for all six IN-14 tubes. Static `123456`, live time display and anti-poison animation were tested on the physical board.

`U22` is `ULN2003G`, not a `74HC595`. The first shift-register chain starts at `U14`.

## EEPROM settings

Settings are stored in STM8 EEPROM starting at `0x4000`.

| Address | Setting |
| ---: | --- |
| `0x4000` | magic byte |
| `0x4001` | night blanking enabled |
| `0x4002` | night start hour |
| `0x4003` | night start minute |
| `0x4004` | night end hour |
| `0x4005` | night end minute |
| `0x4006` | anti-poison interval in minutes |
| `0x4007` | RGB mode |
| `0x4008` | 12h/24h mode |
