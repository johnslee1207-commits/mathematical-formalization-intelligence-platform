[CmdletBinding()]
param(
  [string]$EnvironmentProfilePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'config\local\m0_environment.json')
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

& "$PSScriptRoot\check_m1_contract.ps1"
& "$PSScriptRoot\test_m1_negative.ps1"
& "$PSScriptRoot\verify_m1.ps1" -EnvironmentProfilePath $EnvironmentProfilePath

$manifest = Get-Content -Raw 'benchmarks\m1_benchmark_05.json' | ConvertFrom-Json
$report = Get-Content -Raw 'reports\m1_acceptance_report.json' | ConvertFrom-Json
$registryHash = (Get-FileHash 'manifests\data_layers\registry.json' -Algorithm SHA256).Hash
$manifestHash = (Get-FileHash 'benchmarks\m1_benchmark_05.json' -Algorithm SHA256).Hash
$sourceHash = (Get-FileHash 'M1\Benchmark.lean' -Algorithm SHA256).Hash
$negativeHash = (Get-FileHash 'M1\Negative.lean' -Algorithm SHA256).Hash

if ($report.status -ne 'pass') { throw 'M1 replay failed: acceptance report is not pass' }
if ($report.manifest_sha256 -ne $manifestHash) { throw 'M1 replay failed: manifest hash mismatch' }
if ($report.benchmark_source_sha256 -ne $sourceHash) { throw 'M1 replay failed: benchmark source hash mismatch' }
if ($report.negative_source_sha256 -ne $negativeHash) { throw 'M1 replay failed: negative source hash mismatch' }

[pscustomobject]@{
  schema = 'm1-replay-report.v1'
  benchmark_id = $manifest.benchmark_id
  manifest_sha256 = $manifestHash
  registry_sha256 = $registryHash
  benchmark_source_sha256 = $sourceHash
  negative_source_sha256 = $negativeHash
  toolchain = (Get-Content -Raw 'lean-toolchain').Trim()
  acceptance_status = $report.status
  negative_contract_status = 'pass'
  replay_status = 'pass'
} | ConvertTo-Json -Depth 5 | Set-Content 'reports\m1_replay_report.json' -Encoding utf8

Write-Host 'M1 deterministic replay: PASS'

