[CmdletBinding()]
param(
  [string]$EnvironmentProfilePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'config\local\m0_environment.json')
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$profile = Get-Content -Raw -LiteralPath $EnvironmentProfilePath | ConvertFrom-Json
if ($profile.elan_home) { $env:ELAN_HOME = $profile.elan_home }
if ($profile.elan_bin) { $env:Path = $profile.elan_bin + [IO.Path]::PathSeparator + $env:Path }
Set-Location -LiteralPath $projectRoot

$manifest = Get-Content -Raw 'benchmarks\m0_benchmark_10.json' | ConvertFrom-Json
$registry = Get-Content -Raw 'manifests\data_layers\registry.json' | ConvertFrom-Json
if ($manifest.cases.Count -ne 10) { throw 'Replay failed: benchmark case count is not 10' }
if (-not $registry.layers.domain_common -contains 'benchmarks/') { throw 'Replay failed: benchmark layer is not registered' }
if (-not $registry.layers.local_machine_specific -contains 'config/local/') { throw 'Replay failed: local profile layer is not registered' }
if (-not $registry.layers.local_machine_specific -contains 'config/ci/') { throw 'Replay failed: CI profile layer is not registered' }

& "$PSScriptRoot\verify_m0.ps1" -EnvironmentProfilePath $EnvironmentProfilePath
if ($LASTEXITCODE -ne 0) { throw "Replay failed: acceptance exit code $LASTEXITCODE" }

$report = Get-Content -Raw 'reports\m0_acceptance_report.json' | ConvertFrom-Json
if ($report.status -ne 'pass') { throw 'Replay failed: acceptance report is not pass' }
if ($report.case_count -ne 10) { throw 'Replay failed: report case count mismatch' }
$expectedManifestHash = (Get-FileHash 'benchmarks\m0_benchmark_10.json' -Algorithm SHA256).Hash
if ($report.manifest_sha256 -ne $expectedManifestHash) { throw 'Replay failed: acceptance manifest hash mismatch' }
$expectedBenchmarkHash = (Get-FileHash 'M0\Benchmark.lean' -Algorithm SHA256).Hash
if ($report.benchmark_source_sha256 -ne $expectedBenchmarkHash) { throw 'Replay failed: benchmark source hash mismatch' }
$expectedNegativeHash = (Get-FileHash 'M0\Negative.lean' -Algorithm SHA256).Hash
if ($report.negative_source_sha256 -ne $expectedNegativeHash) { throw 'Replay failed: negative source hash mismatch' }

[pscustomobject]@{
  schema = 'm0-replay-report.v1'
  benchmark_id = $manifest.benchmark_id
  manifest_sha256 = $expectedManifestHash
  registry_sha256 = (Get-FileHash 'manifests\data_layers\registry.json' -Algorithm SHA256).Hash
  benchmark_source_sha256 = $expectedBenchmarkHash
  negative_source_sha256 = $expectedNegativeHash
  toolchain = (Get-Content -Raw 'lean-toolchain').Trim()
  acceptance_status = $report.status
  replay_status = 'pass'
} | ConvertTo-Json -Depth 5 | Set-Content 'reports\m0_replay_report.json' -Encoding utf8

Write-Host 'M0 deterministic replay: PASS'
