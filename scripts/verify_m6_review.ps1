[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path $ProjectRoot).Path
$manifestPath = Join-Path $projectRoot 'benchmarks/m6_review_manifest.json'
$manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
if ($manifest.schema -ne 'm6-review-manifest.v1' -or $manifest.artifacts.Count -ne 6) { throw 'M6 review manifest mismatch' }
$entries = @()
foreach ($item in $manifest.artifacts) {
  foreach ($relativePath in @($item.readiness, $item.replay, $item.entry)) { if (-not (Test-Path (Join-Path $projectRoot $relativePath))) { throw "M6 review artifact missing: $relativePath" } }
  $readiness = Get-Content -Raw (Join-Path $projectRoot $item.readiness) | ConvertFrom-Json
  $replay = Get-Content -Raw (Join-Path $projectRoot $item.replay) | ConvertFrom-Json
  $ready = if ($readiness.status) { $readiness.status } else { $readiness.replay_status }
  if ($ready -notin @('pass','ready') -or $replay.replay_status -ne 'pass') { throw "M6 review artifact is not passing: $($item.id)" }
  $entries += [pscustomobject]@{ id=$item.id; readiness=$item.readiness; replay=$item.replay; entry=$item.entry; readiness_sha256=(Get-FileHash (Join-Path $projectRoot $item.readiness) -Algorithm SHA256).Hash; replay_sha256=(Get-FileHash (Join-Path $projectRoot $item.replay) -Algorithm SHA256).Hash }
}
[pscustomobject]@{ schema='m6-review-report.v1'; package_id=$manifest.package_id; manifest_sha256=(Get-FileHash $manifestPath -Algorithm SHA256).Hash; artifacts=$entries; status='pass' } | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $projectRoot 'reports/m6_review_report.json')
Write-Host 'M6 review package verification: PASS'
