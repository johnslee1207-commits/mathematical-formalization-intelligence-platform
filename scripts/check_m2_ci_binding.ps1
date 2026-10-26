[CmdletBinding()]
param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$workflowRelativePath = '.github/workflows/lean_action_ci.yml'
$workflowPath = Join-Path $projectRoot $workflowRelativePath
if (-not (Test-Path -LiteralPath $workflowPath)) { throw 'CI workflow entry point is missing' }
$workflow = Get-Content -Raw -LiteralPath $workflowPath
$bindings = @()

foreach ($phase in @('M0', 'M1')) {
  $phaseLower = $phase.ToLower()
  $reportPath = Join-Path $projectRoot "reports/${phaseLower}_replay_report.json"
  $report = Get-Content -Raw -LiteralPath $reportPath | ConvertFrom-Json
  foreach ($field in @('environment_profile', 'workflow_entry_point', 'replay_entry_point', 'profile_scope')) {
    if ([string]::IsNullOrWhiteSpace([string]$report.$field)) { throw "$phase CI binding is missing: $field" }
  }
  if ($report.workflow_entry_point -ne $workflowRelativePath) { throw "$phase workflow entry point mismatch" }
  if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $report.environment_profile))) { throw "$phase environment profile is missing" }
  if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $report.replay_entry_point))) { throw "$phase replay entry point is missing" }
  $profile = Get-Content -Raw -LiteralPath (Join-Path $projectRoot $report.environment_profile) | ConvertFrom-Json
  if ($profile.profile_scope -ne $report.profile_scope) { throw "$phase profile scope mismatch" }
  if ($workflow -notlike "*$($report.replay_entry_point)*") { throw "$phase replay entry point is not bound in CI workflow" }
  $bindings += [pscustomobject]@{
    phase = $phase
    environment_profile = $report.environment_profile
    workflow_entry_point = $report.workflow_entry_point
    replay_entry_point = $report.replay_entry_point
    profile_scope = $report.profile_scope
    replay_status = $report.replay_status
  }
}

[pscustomobject]@{
  schema = 'm2-ci-binding-report.v1'
  workflow_sha256 = (Get-FileHash -LiteralPath $workflowPath -Algorithm SHA256).Hash
  bindings = $bindings
  status = 'pass'
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $projectRoot 'reports/m2_ci_binding_report.json') -Encoding utf8

Write-Host 'M2 CI evidence binding: PASS'
