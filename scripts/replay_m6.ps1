[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot
& "$PSScriptRoot/check_m6_contract.ps1"
& "$PSScriptRoot/verify_m6_review.ps1"
& "$PSScriptRoot/test_m6_negative.ps1"
[pscustomobject]@{ schema='m6-replay-report.v1'; review_report_sha256=(Get-FileHash (Join-Path $projectRoot 'reports/m6_review_report.json') -Algorithm SHA256).Hash; registry_sha256=(Get-FileHash (Join-Path $projectRoot 'manifests/data_layers/registry.json') -Algorithm SHA256).Hash; replay_status='pass' } | ConvertTo-Json | Set-Content (Join-Path $projectRoot 'reports/m6_replay_report.json')
[pscustomobject]@{ schema='m6-readiness-report.v1'; phase='M6'; evidence='reports/m6_review_report.json'; blocking_items=@(); next_phase_allowed=$true; status='ready' } | ConvertTo-Json | Set-Content (Join-Path $projectRoot 'reports/m6_readiness_report.json')
Write-Host 'M6 review replay and readiness: PASS'
