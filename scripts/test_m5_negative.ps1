[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path $ProjectRoot).Path
$fixture = Join-Path ([IO.Path]::GetTempPath()) ("m5-negative-" + [guid]::NewGuid().ToString('N'))
try {
  New-Item -ItemType Directory -Path (Join-Path $fixture 'benchmarks') -Force | Out-Null
  Copy-Item (Join-Path $projectRoot 'benchmarks/m5_provenance_manifest.json') (Join-Path $fixture 'benchmarks')
  $p = Join-Path $fixture 'benchmarks/m5_provenance_manifest.json'; $m = Get-Content -Raw $p | ConvertFrom-Json; $m.toolchain = 'corrupted-toolchain'; $m | ConvertTo-Json -Depth 8 | Set-Content $p
  try { & (Join-Path $projectRoot 'scripts/verify_m5_provenance.ps1') -ProjectRoot $fixture; throw 'M5 provenance mutation was accepted' } catch { if ($_.Exception.Message -eq 'M5 provenance mutation was accepted') { throw } }
  Write-Host 'M5 provenance negative gate: PASS'
} finally { if (Test-Path $fixture) { Remove-Item $fixture -Recurse -Force } }
