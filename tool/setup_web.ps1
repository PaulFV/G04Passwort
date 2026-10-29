# Windows variant of tool/setup_web.sh – run after `flutter pub get`.
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
function Get-Ver($pkg) {
  $lines = Get-Content pubspec.lock
  $i = [array]::IndexOf($lines, "  ${pkg}:")
  for ($j = $i; $j -lt $i + 8; $j++) { if ($lines[$j] -match 'version: "(.+)"') { return $Matches[1] } }
}
$drift = Get-Ver 'drift'; $sqlite = Get-Ver 'sqlite3'
Write-Host "drift $drift - sqlite3 $sqlite"
Invoke-WebRequest "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$sqlite/sqlite3.wasm" -OutFile web/sqlite3.wasm
Invoke-WebRequest "https://github.com/simolus3/drift/releases/download/drift-$drift/drift_worker.js" -OutFile web/drift_worker.js
Write-Host 'web/sqlite3.wasm and web/drift_worker.js updated.'
