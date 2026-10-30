[CmdletBinding()]
param([string]$EnvironmentProfilePath=(Join-Path (Split-Path -Parent $PSScriptRoot) 'config/local/m0_environment.json'))
$ErrorActionPreference='Stop'; & "$PSScriptRoot/check_m7_contract.ps1"; & "$PSScriptRoot/verify_m7.ps1" -EnvironmentProfilePath $EnvironmentProfilePath
$root=Split-Path -Parent $PSScriptRoot; & "$PSScriptRoot/test_m7_negative.ps1" -ProjectRoot $root
$a=Get-Content -Raw (Join-Path $root 'reports/m7_acceptance_report.json')|ConvertFrom-Json; if($a.status -ne 'pass'){throw 'M7 acceptance failed'}
[pscustomobject]@{schema='m7-replay-report.v1';benchmark_id=$a.benchmark_id;manifest_sha256=$a.manifest_sha256;registry_sha256=$a.registry_sha256;benchmark_source_sha256=$a.benchmark_source_sha256;negative_source_sha256=$a.negative_source_sha256;profile_scope=$a.profile_scope;replay_status='pass'}|ConvertTo-Json|Set-Content (Join-Path $root 'reports/m7_replay_report.json')
[pscustomobject]@{schema='m7-readiness-report.v1';phase='M7';blocking_items=@();next_phase_allowed=$true;status='ready'}|ConvertTo-Json|Set-Content (Join-Path $root 'reports/m7_readiness_report.json'); Write-Host 'M7 deterministic replay and readiness: PASS'
