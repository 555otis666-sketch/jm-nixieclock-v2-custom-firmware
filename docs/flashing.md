# Build and flashing

## Required tools

- ST Toolset / ST Visual Develop for STM8
- STVP command line
- ST-Link V2 connected through SWIM

The scripts use the default install path:

```text
C:\Program Files (x86)\STMicroelectronics\st_toolset\
```

## Build

From the repository root:

```powershell
.\build.ps1
```

If script execution is blocked:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

This builds:

```text
firmware\jm_nixieclock_v2_custom_firmware.s19
```

## Flash

From the repository root:

```powershell
.\flash.ps1
```

If script execution is blocked:

```powershell
powershell -ExecutionPolicy Bypass -File .\flash.ps1
```

By default it flashes:

```text
firmware\jm_nixieclock_v2_custom_firmware.s19
```

## Manual flash command

```powershell
& 'C:\Program Files (x86)\STMicroelectronics\st_toolset\stvp\STVP_CmdLine.exe' `
  -BoardName=ST-LINK `
  -Port=USB `
  -ProgMode=SWIM `
  -Device=STM8S003F3 `
  -FileProg=C:\Users\OTIS\Documents\Nixie\firmware\jm_nixieclock_v2_custom_firmware.s19 `
  -no_erase `
  -verif `
  -verbose `
  -no_log `
  -no_warn_protect `
  -no_loop
```

If STVP cannot communicate with the MCU, disconnect external DC power, reconnect ST-Link USB, then try again.
