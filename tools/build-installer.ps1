# 用 Inno Setup 把 dist/ggjb-windows-x64 打成单文件安装包。
#
#   pwsh -File tools/build-installer.ps1
#
# 前置：先跑 tools/build-all.ps1 -SkipAndroid 出 Windows 目录，
#       并确认已安装 Inno Setup 6。

$ErrorActionPreference = 'Continue'

$root = Split-Path -Parent $PSScriptRoot
$iss = Join-Path $root 'installer\ggjb.iss'
$src = Join-Path $root 'dist\ggjb-windows-x64'

$iscc = $env:ISCC_PATH
if (-not $iscc) {
  $candidates = @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    'C:\Program Files\Inno Setup 6\ISCC.exe'
  )
  $iscc = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}

if (-not $iscc) {
  Write-Error 'ISCC.exe not found. Install Inno Setup 6, or set ISCC_PATH.'
  exit 1
}
if (-not (Test-Path $src)) {
  Write-Error "missing $src — run tools/build-all.ps1 -SkipAndroid first."
  exit 1
}

Write-Host "ISCC=$iscc"
& $iscc $iss
$code = $LASTEXITCODE
Write-Host "RC_ISCC=$code"

if ($code -eq 0) {
  Get-ChildItem (Join-Path $root 'dist') -Filter '*windows-setup.exe' |
    ForEach-Object {
      $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
      Write-Host "SETUP=$($_.FullName)"
      Write-Host "SETUP_BYTES=$($_.Length)"
      Write-Host "SETUP_MB=$([math]::Round($_.Length / 1MB, 2))"
      Write-Host "SETUP_SHA256=$h"
    }
}
exit $code
