[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path $ProjectRoot).Path
$fixture = Join-Path ([IO.Path]::GetTempPath()) ("m6-negative-" + [guid]::NewGuid().ToString('N'))
try {
  New-Item -ItemType Directory -Path (Join-Path $fixture 'benchmarks') -Force | Out-Null
  Copy-Item (Join-Path $projectRoot 'benchmarks/m6_review_manifest.json') (Join-Path $fixture 'benchmarks')
  $p = Join-Path $fixture 'benchmarks/m6_review_manifest.json'; $m = Get-Content -Raw $p | ConvertFrom-Json; $m.artifacts[0].replay = 'reports/missing.json'; $m | ConvertTo-Json -Depth 8 | Set-Content $p
  try { & (Join-Path $projectRoot 'scripts/verify_m6_review.ps1') -ProjectRoot $fixture; throw 'M6 review mutation was accepted' } catch { if ($_.Exception.Message -eq 'M6 review mutation was accepted') { throw } }
  Write-Host 'M6 review negative gate: PASS'
} finally { if (Test-Path $fixture) { Remove-Item $fixture -Recurse -Force } }
