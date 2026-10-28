[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path $ProjectRoot).Path
$manifestPath = Join-Path $projectRoot 'benchmarks/m5_provenance_manifest.json'
$manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
if ($manifest.schema -ne 'm5-provenance-manifest.v1' -or $manifest.phases.Count -ne 5) { throw 'M5 provenance manifest mismatch' }
if ($manifest.toolchain -ne (Get-Content -Raw (Join-Path $projectRoot 'lean-toolchain')).Trim()) { throw 'M5 toolchain mismatch' }
$entries = @()
foreach ($item in $manifest.phases) {
  $reportPath = Join-Path $projectRoot $item.report
  $replayPath = Join-Path $projectRoot $item.replay
  if (-not (Test-Path $reportPath) -or -not (Test-Path $replayPath)) { throw "M5 provenance path missing: $($item.phase)" }
  $report = Get-Content -Raw $reportPath | ConvertFrom-Json
  if ($report.replay_status -ne 'pass') { throw "M5 phase replay is not passing: $($item.phase)" }
  $entries += [pscustomobject]@{ phase=$item.phase; report=$item.report; replay=$item.replay; report_sha256=(Get-FileHash $reportPath -Algorithm SHA256).Hash; replay_sha256=(Get-FileHash $replayPath -Algorithm SHA256).Hash }
}
[pscustomobject]@{ schema='m5-provenance-report.v1'; handoff_id=$manifest.handoff_id; manifest_sha256=(Get-FileHash $manifestPath -Algorithm SHA256).Hash; toolchain=$manifest.toolchain; phases=$entries; status='pass' } | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $projectRoot 'reports/m5_provenance_report.json')
Write-Host 'M5 provenance verification: PASS'
