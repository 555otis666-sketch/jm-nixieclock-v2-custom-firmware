param(
    [string]$Source = "firmware\jm_nixieclock_v2_custom_firmware.asm"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$asmDir = "C:\Program Files (x86)\STMicroelectronics\st_toolset\asm"
$asmExe = Join-Path $asmDir "asm.exe"
$lynExe = Join-Path $asmDir "lyn.exe"
$obsendExe = Join-Path $asmDir "obsend.exe"

foreach ($tool in @($asmExe, $lynExe, $obsendExe)) {
    if (-not (Test-Path -LiteralPath $tool)) {
        throw "Missing tool: $tool"
    }
}

$sourcePath = Join-Path $root $Source
if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "Missing source file: $sourcePath"
}

$firmwareDir = Split-Path -Parent $sourcePath
$base = [IO.Path]::GetFileNameWithoutExtension($sourcePath)

Push-Location $firmwareDir
try {
    & cmd.exe /c "`"$asmExe`" -sym -li=$base.lsr $base"
    if ($LASTEXITCODE -ne 0) { throw "asm.exe failed with code $LASTEXITCODE" }

    & cmd.exe /c "`"$lynExe`" $base.obj,$base,;"
    if ($LASTEXITCODE -ne 0) { throw "lyn.exe failed with code $LASTEXITCODE" }

    & cmd.exe /c "`"$obsendExe`" $base,f,$base.s19,s"
    if ($LASTEXITCODE -ne 0) { throw "obsend.exe failed with code $LASTEXITCODE" }
}
finally {
    Pop-Location
}

Write-Host "Built: $Source -> firmware\$base.s19"
