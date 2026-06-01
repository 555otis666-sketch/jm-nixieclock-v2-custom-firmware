param(
    [string]$Firmware = "firmware\jm_nixieclock_v2_custom_firmware.s19"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$stvp = "C:\Program Files (x86)\STMicroelectronics\st_toolset\stvp\STVP_CmdLine.exe"

if (-not (Test-Path -LiteralPath $stvp)) {
    throw "Missing STVP command line: $stvp"
}

$firmwarePath = Join-Path $root $Firmware
if (-not (Test-Path -LiteralPath $firmwarePath)) {
    throw "Missing firmware image: $firmwarePath"
}

$fileArg = "-FileProg=$firmwarePath"

& $stvp `
    -BoardName=ST-LINK `
    -Port=USB `
    -ProgMode=SWIM `
    -Device=STM8S003F3 `
    $fileArg `
    -no_erase `
    -verif `
    -verbose `
    -no_log `
    -no_warn_protect `
    -no_loop

if ($LASTEXITCODE -ne 0) {
    throw "STVP failed with code $LASTEXITCODE"
}

Write-Host "Flashed: $Firmware"
