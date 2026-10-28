[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot
& "$PSScriptRoot/check_m5_contract.ps1"
& "$PSScriptRoot/verify_m5_provenance.ps1"
& "$PSScriptRoot/test_m5_negative.ps1"
[pscustomobject]@{ schema='m5-replay-report.v1'; provenance_report_sha256=(Get-FileHash (Join-Path $projectRoot 'reports/m5_provenance_report.json') -Algorithm SHA256).Hash; registry_sha256=(Get-FileHash (Join-Path $projectRoot 'manifests/data_layers/registry.json') -Algorithm SHA256).Hash; replay_status='pass' } | ConvertTo-Json | Set-Content (Join-Path $projectRoot 'reports/m5_replay_report.json')
[pscustomobject]@{ schema='m5-readiness-report.v1'; phase='M5'; evidence='reports/m5_provenance_report.json'; blocking_items=@(); next_phase_allowed=$true; status='ready' } | ConvertTo-Json | Set-Content (Join-Path $projectRoot 'reports/m5_readiness_report.json')
Write-Host 'M5 reproducible handoff and readiness: PASS'
