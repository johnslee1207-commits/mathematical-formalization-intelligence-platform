[CmdletBinding()]
param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$EnvironmentProfilePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'config/local/m0_environment.json')
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path $ProjectRoot).Path
$profileCandidate = if([IO.Path]::IsPathRooted($EnvironmentProfilePath)){$EnvironmentProfilePath}else{Join-Path $root $EnvironmentProfilePath}
$profilePath = (Resolve-Path $profileCandidate -ErrorAction Stop).Path
$replayPath = Join-Path $root 'reports/m7_replay_report.json'
$acceptancePath = Join-Path $root 'reports/m7_acceptance_report.json'
$m6Path = Join-Path $root 'reports/m6_readiness_report.json'
$manifestPath = Join-Path $root 'benchmarks/m7_benchmark_05.json'
$registryPath = Join-Path $root 'manifests/data_layers/registry.json'
$sourcePath = Join-Path $root 'M7/Benchmark.lean'
$negativePath = Join-Path $root 'M7/Negative.lean'
$workflowPath = Join-Path $root '.github/workflows/lean_action_ci.yml'
$replayEntry = 'scripts/replay_m7.ps1'

foreach($p in @($replayPath,$acceptancePath,$m6Path,$manifestPath,$registryPath,$sourcePath,$negativePath,$workflowPath)){ if(-not (Test-Path $p)){ throw "Missing M7 evidence path: $p" } }
$replay = Get-Content -Raw $replayPath | ConvertFrom-Json
$acceptance = Get-Content -Raw $acceptancePath | ConvertFrom-Json
$m6 = Get-Content -Raw $m6Path | ConvertFrom-Json
$profile = Get-Content -Raw $profilePath | ConvertFrom-Json
if($replay.schema -ne 'm7-replay-report.v1' -or $replay.replay_status -ne 'pass'){ throw 'M7 replay report is not passing' }
if($acceptance.status -ne 'pass' -or $m6.status -ne 'ready' -or -not $m6.next_phase_allowed){ throw 'M7/M6 readiness prerequisite failed' }
if($replay.profile_scope -ne $profile.profile_scope -or $replay.environment_profile -ne ($profilePath.Replace('\','/').Substring($root.Length+1))){ throw 'Environment profile binding mismatch' }
if($replay.workflow_entry_point -ne '.github/workflows/lean_action_ci.yml' -or $replay.replay_entry_point -ne $replayEntry){ throw 'Replay entry binding mismatch' }
if($replay.toolchain -ne $profile.project_toolchain){ throw 'Toolchain binding mismatch' }
$expected = @{
  manifest_sha256 = (Get-FileHash $manifestPath -Algorithm SHA256).Hash
  registry_sha256 = (Get-FileHash $registryPath -Algorithm SHA256).Hash
  benchmark_source_sha256 = (Get-FileHash $sourcePath -Algorithm SHA256).Hash
  negative_source_sha256 = (Get-FileHash $negativePath -Algorithm SHA256).Hash
  m6_readiness_sha256 = (Get-FileHash $m6Path -Algorithm SHA256).Hash
}
foreach($name in $expected.Keys){ if($replay.$name -ne $expected[$name]){ throw "M7 evidence hash mismatch: $name" } }
if($acceptance.manifest_sha256 -ne $expected.manifest_sha256 -or $acceptance.registry_sha256 -ne $expected.registry_sha256 -or $acceptance.toolchain -ne $profile.project_toolchain){ throw 'Acceptance and replay evidence diverge' }
$out = [ordered]@{
  schema='m7-evidence-binding-report.v1'; phase='M7'; status='pass'
  m6_readiness_sha256=$expected.m6_readiness_sha256; registry_sha256=$expected.registry_sha256
  manifest_sha256=$expected.manifest_sha256; benchmark_source_sha256=$expected.benchmark_source_sha256
  negative_source_sha256=$expected.negative_source_sha256; toolchain=$profile.project_toolchain
  environment_profile=$replay.environment_profile; workflow_entry_point=$replay.workflow_entry_point
  replay_entry_point=$replay.replay_entry_point
}
$out | ConvertTo-Json | Set-Content (Join-Path $root 'reports/m7_evidence_binding_report.json')
Write-Host 'M7 evidence binding: PASS'
