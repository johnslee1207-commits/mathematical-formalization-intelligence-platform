[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path $ProjectRoot).Path
$manifestPath = Join-Path $projectRoot 'benchmarks/m4_suite_manifest.json'
$manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
if ($manifest.schema -ne 'm4-suite-manifest.v1' -or $manifest.phases.Count -ne 4) { throw 'M4 suite manifest schema or phase count mismatch' }
$entries = @()
foreach ($item in $manifest.phases) {
  $readinessPath = Join-Path $projectRoot $item.readiness
  $replayPath = Join-Path $projectRoot $item.replay
  if (-not (Test-Path $readinessPath) -or -not (Test-Path $replayPath)) { throw "M4 phase evidence missing: $($item.phase)" }
  $readiness = Get-Content -Raw $readinessPath | ConvertFrom-Json
  $replay = Get-Content -Raw $replayPath | ConvertFrom-Json
  $readinessStatus = if ($readiness.status) { $readiness.status } else { $readiness.replay_status }
  if ($readinessStatus -notin @('pass','ready') -or $replay.replay_status -ne 'pass') { throw "M4 phase evidence is not passing: $($item.phase)" }
  $entries += [pscustomobject]@{ phase=$item.phase; readiness=$item.readiness; replay=$item.replay; readiness_sha256=(Get-FileHash $readinessPath -Algorithm SHA256).Hash; replay_sha256=(Get-FileHash $replayPath -Algorithm SHA256).Hash }
}
[pscustomobject]@{ schema='m4-suite-report.v1'; suite_id=$manifest.suite_id; manifest_sha256=(Get-FileHash $manifestPath -Algorithm SHA256).Hash; phases=$entries; status='pass' } | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $projectRoot 'reports/m4_suite_report.json')
Write-Host 'M4 suite selection verification: PASS'
