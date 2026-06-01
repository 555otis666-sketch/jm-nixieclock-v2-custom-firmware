# Flashing

This firmware is for an `STM8S003F3P6` target programmed through `SWIM` with an ST-Link V2.

## Required tools

- ST-Link V2
- ST Visual Programmer / STVP
- `firmware/jm_nixieclock_v2_custom_firmware.s19`

## Wiring

Connect ST-Link V2 to the clock board:

| ST-Link | Clock board |
| --- | --- |
| SWIM | SWIM |
| GND | GND |
| 3.3 V | 3.3 V |
| NRST | NRST, if available |

Do not connect the clock's external DC power supply while programming.

## STVP settings

Use these STVP settings:

| Setting | Value |
| --- | --- |
| Programmer | ST-LINK |
| Port | USB |
| Mode | SWIM |
| Device | STM8S003F3 |

Load this file into program memory:

```text
firmware/jm_nixieclock_v2_custom_firmware.s19
```

Then run `Program` and `Verify`.

## If the MCU is protected

Some original boards have read-out protection enabled. In STVP this may appear as a protected device or communication/programming failure.

To unlock the MCU:

1. Open the `OPTION BYTE` tab in STVP.
2. Set `ROP` / read-out protection to `OFF`.
3. Program/write the option bytes while still on the `OPTION BYTE` tab.
4. The STM8 will be erased. This is normal.
5. Return to program memory.
6. Program `firmware/jm_nixieclock_v2_custom_firmware.s19`.
7. Run `Verify`.

Warning: disabling ROP erases the original firmware. If the original firmware was protected, it cannot be backed up first.

