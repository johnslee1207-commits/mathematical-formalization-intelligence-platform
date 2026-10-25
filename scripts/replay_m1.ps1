[CmdletBinding()]
param(
  [string]$EnvironmentProfilePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'config/local/m0_environment.json')
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

& "$PSScriptRoot\check_m1_contract.ps1"
& "$PSScriptRoot\test_m1_negative.ps1"
& "$PSScriptRoot\verify_m1.ps1" -EnvironmentProfilePath $EnvironmentProfilePath

$manifestPath = Join-Path $projectRoot 'benchmarks/m1_benchmark_10.json'
$reportPath = Join-Path $projectRoot 'reports/m1_acceptance_report.json'
$registryPath = Join-Path $projectRoot 'manifests/data_layers/registry.json'
$sourcePath = Join-Path $projectRoot 'M1/Benchmark.lean'
$negativePath = Join-Path $projectRoot 'M1/Negative.lean'
$manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
$report = Get-Content -Raw $reportPath | ConvertFrom-Json
$registryHash = (Get-FileHash $registryPath -Algorithm SHA256).Hash
$manifestHash = (Get-FileHash $manifestPath -Algorithm SHA256).Hash
$sourceHash = (Get-FileHash $sourcePath -Algorithm SHA256).Hash
$negativeHash = (Get-FileHash $negativePath -Algorithm SHA256).Hash

if ($report.status -ne 'pass') { throw 'M1 replay failed: acceptance report is not pass' }
if ($report.data_layer_registry_sha256 -ne $registryHash) { throw 'M1 replay failed: data-layer registry hash mismatch' }
if ($report.profile_scope -ne (Get-Content -Raw $EnvironmentProfilePath | ConvertFrom-Json).profile_scope) { throw 'M1 replay failed: profile scope mismatch' }
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
  profile_scope = $report.profile_scope
  data_layer_registry_sha256 = $registryHash
  toolchain = (Get-Content -Raw (Join-Path $projectRoot 'lean-toolchain')).Trim()
  acceptance_status = $report.status
  negative_contract_status = 'pass'
  replay_status = 'pass'
} | ConvertTo-Json -Depth 5 | Set-Content $reportPath -Encoding utf8

Write-Host 'M1 deterministic replay: PASS'

