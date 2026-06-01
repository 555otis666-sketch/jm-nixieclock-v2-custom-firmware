# Menu map

Open `menu_map.html` for the visual diagram.

## Normal display

The clock shows `HHMMSS`.

Short button actions:

| Button | Action |
| --- | --- |
| `SET` short | enter time setting |
| `DOWN` short | change RGB mode |
| `UP` short | toggle 24h / 12h |

Long button actions:

| Button | Action |
| --- | --- |
| `SET` long | toggle night blanking on/off |
| `DOWN` long | set night blanking start and end time |
| `UP` long | set anti-poison interval |

## Time setting

`SET` short enters time setting.

- only four lamps are used: `HHMM--`
- seconds lamps are off
- the selected digit blinks
- `UP` / `DOWN` changes the selected digit
- `SET` moves to the next digit
- after the last digit, the time is written to DS3231 and seconds are reset

Digit limits:

- hour tens: `0-2`
- hour ones: `0-9`, but `0-3` when hour tens is `2`
- minute tens: `0-5`
- minute ones: `0-9`

## Night blanking

`SET` long toggles night blanking:

- ON confirmation: tubes blank briefly
- OFF confirmation: all tubes show `000000` briefly

`DOWN` long opens night time setting:

1. start time `HHMM--`
2. end time `HHMM--`

When night blanking is active, all tubes and both colon separators are off.

## Anti-poison

`UP` long opens anti-poison interval setting.

- only lamp 1 shows the value
- values: `1-9` minutes
- default: `1`
- `SET` saves to EEPROM

The anti-poison routine runs `0-9` across all lamps for about 3 seconds. The next interval is counted from the end of the routine.

## RGB modes

`DOWN` short cycles through:

```text
AUTO -> OFF -> RED -> PURPLE -> YELLOW -> PINK -> GREEN -> BLUE
```

The board has simple RGB outputs without PWM, so mixed colors may look similar depending on the LEDs.

