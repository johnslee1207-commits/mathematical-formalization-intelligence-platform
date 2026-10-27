[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path $ProjectRoot).Path
$contract = Get-Content -Raw (Join-Path $projectRoot 'M3/phase_contract.json') | ConvertFrom-Json
foreach ($name in @('m3_acceptance_report.json','m3_replay_report.json','m3_evidence_binding_report.json')) {
  $report = Get-Content -Raw (Join-Path $projectRoot "reports/$name") | ConvertFrom-Json
  $status = if ($report.status) { $report.status } else { $report.replay_status }
  if ($status -ne 'pass') { throw "M3 readiness evidence is not passing: $name" }
}
[pscustomobject]@{ schema='m3-readiness-report.v1'; phase='M3'; contract_schema=$contract.schema; blocking_items=@(); next_phase_allowed=$true; status='ready' } | ConvertTo-Json | Set-Content (Join-Path $projectRoot 'reports/m3_readiness_report.json')
Write-Host 'M3 readiness gate: PASS'
