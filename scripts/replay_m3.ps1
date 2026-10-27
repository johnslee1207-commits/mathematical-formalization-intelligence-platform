[CmdletBinding()]
param(
  [string]$EnvironmentProfilePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'config/local/m0_environment.json')
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$profile = Get-Content -Raw -LiteralPath $EnvironmentProfilePath | ConvertFrom-Json
$profileRelativePath = [IO.Path]::GetRelativePath($projectRoot, (Resolve-Path -LiteralPath $EnvironmentProfilePath).Path).Replace('\\', '/')
Set-Location -LiteralPath $projectRoot

& "$PSScriptRoot\check_m3_contract.ps1"
& "$PSScriptRoot\verify_m3.ps1" -EnvironmentProfilePath $EnvironmentProfilePath

$acceptancePath = Join-Path $projectRoot 'reports/m3_acceptance_report.json'
$readinessPath = Join-Path $projectRoot 'reports/m2_readiness_report.json'
$manifestPath = Join-Path $projectRoot 'benchmarks/m3_benchmark_05.json'
$registryPath = Join-Path $projectRoot 'manifests/data_layers/registry.json'
$sourcePath = Join-Path $projectRoot 'M3/Benchmark.lean'
$negativePath = Join-Path $projectRoot 'M3/Negative.lean'
$acceptance = Get-Content -Raw $acceptancePath | ConvertFrom-Json
$readiness = Get-Content -Raw $readinessPath | ConvertFrom-Json
if ($acceptance.status -ne 'pass') { throw 'M3 replay failed: acceptance report is not pass' }
if ($readiness.status -ne 'ready' -or -not $readiness.next_phase_allowed) { throw 'M3 replay failed: M2 readiness is not ready' }

[pscustomobject]@{
  schema = 'm3-replay-report.v1'
  benchmark_id = $acceptance.benchmark_id
  manifest_sha256 = (Get-FileHash $manifestPath -Algorithm SHA256).Hash
  registry_sha256 = (Get-FileHash $registryPath -Algorithm SHA256).Hash
  benchmark_source_sha256 = (Get-FileHash $sourcePath -Algorithm SHA256).Hash
  negative_source_sha256 = (Get-FileHash $negativePath -Algorithm SHA256).Hash
  m2_readiness_sha256 = (Get-FileHash $readinessPath -Algorithm SHA256).Hash
  profile_scope = $profile.profile_scope
  environment_profile = $profileRelativePath
  workflow_entry_point = '.github/workflows/lean_action_ci.yml'
  replay_entry_point = 'scripts/replay_m3.ps1'
  toolchain = (Get-Content -Raw (Join-Path $projectRoot 'lean-toolchain')).Trim()
  acceptance_status = $acceptance.status
  replay_status = 'pass'
} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $projectRoot 'reports/m3_replay_report.json') -Encoding utf8

Write-Host 'M3 deterministic replay: PASS'
