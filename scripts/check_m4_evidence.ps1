[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path $ProjectRoot).Path
$reportPath = Join-Path $projectRoot 'reports/m4_replay_report.json'
$report = Get-Content -Raw $reportPath | ConvertFrom-Json
if ($report.schema -ne 'm4-replay-report.v1' -or $report.replay_status -ne 'pass') { throw 'M4 replay report is not passing' }
$suitePath = Join-Path $projectRoot 'reports/m4_suite_report.json'
if ($report.suite_report_sha256 -ne (Get-FileHash $suitePath -Algorithm SHA256).Hash) { throw 'M4 suite report hash mismatch' }
if ($report.registry_sha256 -ne (Get-FileHash (Join-Path $projectRoot 'manifests/data_layers/registry.json') -Algorithm SHA256).Hash) { throw 'M4 registry hash mismatch' }
if ($report.workflow_entry_point -ne '.github/workflows/lean_action_ci.yml' -or -not (Test-Path (Join-Path $projectRoot $report.workflow_entry_point))) { throw 'M4 workflow binding mismatch' }
if (-not (Test-Path (Join-Path $projectRoot $report.environment_profile))) { throw 'M4 environment profile binding missing' }
[pscustomobject]@{ schema='m4-evidence-binding-report.v1'; suite_report_sha256=$report.suite_report_sha256; registry_sha256=$report.registry_sha256; workflow_entry_point=$report.workflow_entry_point; environment_profile=$report.environment_profile; status='pass' } | ConvertTo-Json | Set-Content (Join-Path $projectRoot 'reports/m4_evidence_binding_report.json')
Write-Host 'M4 evidence binding: PASS'
