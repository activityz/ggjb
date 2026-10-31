# 一键构建双端发布产物。
#
#   pwsh -File tools/build-all.ps1                # 构建 APK + Windows 目录 + zip
#   pwsh -File tools/build-all.ps1 -SkipAndroid   # 只出 Windows
#   pwsh -File tools/build-all.ps1 -SkipWindows   # 只出 Android
#
# 产物统一放 dist/，文件名带上 pubspec.yaml 里的 version。
# 日志写到 build/_build.log（build/ 已在 .gitignore 里，不会脏了工作区）。

param(
  [switch]$SkipAndroid,
  [switch]$SkipWindows
)

$ErrorActionPreference = 'Continue'

$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root 'app'
$dist = Join-Path $root 'dist'
$logDir = Join-Path $root 'build'
New-Item -ItemType Directory -Force -Path $dist, $logDir | Out-Null
$log = Join-Path $logDir '_build.log'

# PATH 上的 flutter 常常不是当前工程用的那个版本，允许用环境变量覆盖。
$flutter = $env:FLUTTER_BIN
if (-not $flutter) {
  $candidate = 'D:\develop\flutter\fvm\versions\3.47.1\bin\flutter.bat'
  $flutter = if (Test-Path $candidate) { $candidate } else { 'flutter' }
}

function Say([string]$text) { Add-Content -Path $log -Value $text -Encoding utf8 }

# 版本号只从 pubspec 读，别再手改脚本
$pubspec = Get-Content (Join-Path $app 'pubspec.yaml') -Raw -Encoding utf8
$version = if ($pubspec -match '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)') { $Matches[1] } else { '0.0.0' }

Set-Content -Path $log -Value "=== build $version start $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -Encoding utf8
Say "FLUTTER=$flutter"

# ---------------- Android ----------------
if (-not $SkipAndroid) {
  Say "=== apk start $(Get-Date -Format 'HH:mm:ss') ==="
  $apkOut = Join-Path $logDir '_apk_out.log'
  $apkErr = Join-Path $logDir '_apk_err.log'
  $p = Start-Process -FilePath 'cmd.exe' `
    -ArgumentList '/c', $flutter, 'build', 'apk', '--release' `
    -WorkingDirectory $app `
    -RedirectStandardOutput $apkOut `
    -RedirectStandardError $apkErr `
    -NoNewWindow -PassThru
  $p.WaitForExit()
  Say "=== apk end $(Get-Date -Format 'HH:mm:ss') ==="

  $apkSrc = Join-Path $app 'build\app\outputs\flutter-apk\app-release.apk'
  if (Test-Path $apkSrc) {
    $apkDst = Join-Path $dist "ggjb-$version-release.apk"
    Copy-Item $apkSrc $apkDst -Force
    $sz = (Get-Item $apkDst).Length
    Say "APK_OK=$apkDst"
    Say "APK_BYTES=$sz"
    Say "APK_MB=$([math]::Round($sz / 1MB, 2))"
    Say "APK_SHA256=$((Get-FileHash $apkDst -Algorithm SHA256).Hash)"
  } else {
    Say 'APK_MISSING'
    Say (Get-Content $apkErr -Raw -ErrorAction SilentlyContinue)
  }
}

# ---------------- Windows ----------------
if (-not $SkipWindows) {
  Say "=== win start $(Get-Date -Format 'HH:mm:ss') ==="
  $winOut = Join-Path $logDir '_win_out.log'
  $winErr = Join-Path $logDir '_win_err.log'
  $p2 = Start-Process -FilePath 'cmd.exe' `
    -ArgumentList '/c', $flutter, 'build', 'windows', '--release' `
    -WorkingDirectory $app `
    -RedirectStandardOutput $winOut `
    -RedirectStandardError $winErr `
    -NoNewWindow -PassThru
  $p2.WaitForExit()
  Say "=== win end $(Get-Date -Format 'HH:mm:ss') ==="

  $winSrc = Join-Path $app 'build\windows\x64\runner\Release'
  if (Test-Path $winSrc) {
    $winDst = Join-Path $dist 'ggjb-windows-x64'
    # 先停 exe，否则 dll 被占用删不掉，旧目录会残留成嵌套结构
    Get-Process ggjb -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 500
    if (Test-Path $winDst) { cmd /c "rmdir /s /q `"$winDst`"" | Out-Null }
    New-Item -ItemType Directory -Path $winDst -Force | Out-Null
    # 必须拷 $winSrc\* 而不是 $winSrc —— 后者会嵌套成 $winDst\Release\
    Copy-Item (Join-Path $winSrc '*') $winDst -Recurse -Force

    $files = Get-ChildItem $winDst -Recurse -File
    $bytes = ($files | Measure-Object -Property Length -Sum).Sum
    Say "WIN_OK=$winDst"
    Say "WIN_NESTED=$(Test-Path (Join-Path $winDst 'Release'))"
    Say "WIN_FILES=$($files.Count)"
    Say "WIN_BYTES=$bytes"
    Say "WIN_MB=$([math]::Round($bytes / 1MB, 2))"

    $zip = Join-Path $dist "ggjb-$version-windows-x64.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Compress-Archive -Path "$winDst\*" -DestinationPath $zip -CompressionLevel Optimal
    $zb = (Get-Item $zip).Length
    Say "ZIP=$zip"
    Say "ZIP_BYTES=$zb"
    Say "ZIP_MB=$([math]::Round($zb / 1MB, 2))"
    Say "ZIP_SHA256=$((Get-FileHash $zip -Algorithm SHA256).Hash)"
  } else {
    Say 'WIN_MISSING'
    Say (Get-Content $winErr -Raw -ErrorAction SilentlyContinue)
  }
}

Say "=== build $version done $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
Write-Host "log: $log"
Get-Content $log -Encoding utf8 | Select-Object -Last 24
