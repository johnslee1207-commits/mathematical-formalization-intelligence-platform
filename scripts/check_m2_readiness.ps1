[CmdletBinding()]
param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$contract = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'M2/phase_contract.json') | ConvertFrom-Json
$requiredReports = @(
  @{ name = 'm2_evidence_index.json'; status = 'status'; expected = 'pass' },
  @{ name = 'm2_benchmark_metadata_report.json'; status = 'status'; expected = 'pass' },
  @{ name = 'm2_ci_binding_report.json'; status = 'status'; expected = 'pass' },
  @{ name = 'm2_replay_report.json'; status = 'replay_status'; expected = 'pass' }
)

foreach ($item in $requiredReports) {
  $path = Join-Path $projectRoot "reports/$($item.name)"
  if (-not (Test-Path -LiteralPath $path)) { throw "Readiness evidence is missing: $($item.name)" }
  $report = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
  if ([string]$report.($item.status) -ne $item.expected) { throw "Readiness evidence is not passing: $($item.name)" }
}

$oraclePaths = @($contract.oracle.contract, $contract.oracle.metadata, $contract.oracle.negative_tests, $contract.oracle.ci_binding, $contract.oracle.replay, $contract.oracle.evidence, $contract.oracle.replay_report)
foreach ($relativePath in $oraclePaths) {
  if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $relativePath))) { throw "Readiness oracle path is missing: $relativePath" }
}

[pscustomobject]@{
  schema = 'm2-readiness-report.v1'
  phase = 'M2'
  contract_schema = $contract.schema
  evidence_reports = @($requiredReports.name)
  blocking_items = @()
  next_phase_allowed = $true
  status = 'ready'
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $projectRoot 'reports/m2_readiness_report.json') -Encoding utf8

Write-Host 'M2 readiness gate: PASS'
