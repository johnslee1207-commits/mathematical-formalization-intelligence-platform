[CmdletBinding()]
param([string]$EnvironmentProfilePath=(Join-Path (Split-Path -Parent $PSScriptRoot) 'config/local/m0_environment.json'))
$ErrorActionPreference='Stop'; & "$PSScriptRoot/check_m7_contract.ps1"; & "$PSScriptRoot/verify_m7.ps1" -EnvironmentProfilePath $EnvironmentProfilePath
$root=(Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path; $profileCandidate=if([IO.Path]::IsPathRooted($EnvironmentProfilePath)){$EnvironmentProfilePath}else{Join-Path $root $EnvironmentProfilePath}; $profilePath=(Resolve-Path $profileCandidate).Path; $profile=Get-Content -Raw $profilePath|ConvertFrom-Json
& "$PSScriptRoot/test_m7_negative.ps1" -ProjectRoot $root
$a=Get-Content -Raw (Join-Path $root 'reports/m7_acceptance_report.json')|ConvertFrom-Json; if($a.status -ne 'pass'){throw 'M7 acceptance failed'}
$m6Path=Join-Path $root 'reports/m6_readiness_report.json'; $workflow='.github/workflows/lean_action_ci.yml'; $replayEntry='scripts/replay_m7.ps1'
[pscustomobject]@{schema='m7-replay-report.v1';benchmark_id=$a.benchmark_id;manifest_sha256=$a.manifest_sha256;registry_sha256=$a.registry_sha256;benchmark_source_sha256=$a.benchmark_source_sha256;negative_source_sha256=$a.negative_source_sha256;m6_readiness_sha256=(Get-FileHash $m6Path -Algorithm SHA256).Hash;profile_scope=$a.profile_scope;toolchain=$profile.project_toolchain;environment_profile=$profilePath.Replace('\','/').Substring($root.Length+1);workflow_entry_point=$workflow;replay_entry_point=$replayEntry;replay_status='pass'}|ConvertTo-Json|Set-Content (Join-Path $root 'reports/m7_replay_report.json')
& "$PSScriptRoot/check_m7_evidence.ps1" -ProjectRoot $root -EnvironmentProfilePath $profilePath
$e=Get-FileHash (Join-Path $root 'reports/m7_evidence_binding_report.json') -Algorithm SHA256
[pscustomobject]@{schema='m7-readiness-report.v1';phase='M7';blocking_items=@();evidence_binding='reports/m7_evidence_binding_report.json';evidence_binding_sha256=$e.Hash;next_phase_allowed=$true;status='ready'}|ConvertTo-Json|Set-Content (Join-Path $root 'reports/m7_readiness_report.json'); Write-Host 'M7 deterministic replay and readiness: PASS'
