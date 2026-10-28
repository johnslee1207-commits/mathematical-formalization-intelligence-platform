[CmdletBinding()]
param([string]$EnvironmentProfilePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'config/local/m0_environment.json'))
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$profile = Get-Content -Raw $EnvironmentProfilePath | ConvertFrom-Json
$profileRelativePath = [IO.Path]::GetRelativePath($projectRoot, (Resolve-Path $EnvironmentProfilePath).Path).Replace('\\', '/')
Set-Location $projectRoot
& "$PSScriptRoot/check_m4_contract.ps1"
& "$PSScriptRoot/verify_m4_suite.ps1"
& "$PSScriptRoot/test_m4_negative.ps1"
[pscustomobject]@{ schema='m4-replay-report.v1'; suite_report_sha256=(Get-FileHash (Join-Path $projectRoot 'reports/m4_suite_report.json') -Algorithm SHA256).Hash; registry_sha256=(Get-FileHash (Join-Path $projectRoot 'manifests/data_layers/registry.json') -Algorithm SHA256).Hash; toolchain=(Get-Content -Raw (Join-Path $projectRoot 'lean-toolchain')).Trim(); profile_scope=$profile.profile_scope; environment_profile=$profileRelativePath; workflow_entry_point='.github/workflows/lean_action_ci.yml'; replay_entry_point='scripts/replay_m4.ps1'; replay_status='pass' } | ConvertTo-Json | Set-Content (Join-Path $projectRoot 'reports/m4_replay_report.json')
& "$PSScriptRoot/check_m4_evidence.ps1"
[pscustomobject]@{ schema='m4-readiness-report.v1'; phase='M4'; evidence_binding='reports/m4_evidence_binding_report.json'; blocking_items=@(); next_phase_allowed=$true; status='ready' } | ConvertTo-Json | Set-Content (Join-Path $projectRoot 'reports/m4_readiness_report.json')
Write-Host 'M4 deterministic replay and readiness: PASS'
