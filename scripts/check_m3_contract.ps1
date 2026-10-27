[CmdletBinding()]
param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$contractPath = Join-Path $projectRoot 'M3/phase_contract.json'
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
if ($contract.schema -ne 'm3-task-contract.v1') { throw 'M3 contract schema mismatch' }
if ($contract.phase -ne 'M3') { throw 'M3 phase mismatch' }
if ($contract.status -ne 'started') { throw 'M3 contract must start in started state' }
if ($contract.deliverables.Count -ne 5) { throw 'M3 must contain five deliverables' }
if (-not $contract.replay_policy.locked_toolchain) { throw 'M3 must retain locked toolchain policy' }
if (-not $contract.replay_policy.m2_readiness_required) { throw 'M3 must require M2 readiness' }
if (-not $contract.replay_policy.temporary_fixture_negative_tests) { throw 'M3 must include fixture negative tests' }
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'M3/README.md'))) { throw 'M3 README is missing' }
$registry = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'manifests/data_layers/registry.json') | ConvertFrom-Json
if (-not ($registry.layers.domain_common -contains 'M3/')) { throw 'M3 path is not registered as domain common' }
$readiness = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'reports/m2_readiness_report.json') | ConvertFrom-Json
if ($readiness.status -ne 'ready' -or -not $readiness.next_phase_allowed) { throw 'M2 readiness does not permit M3' }
Write-Host 'M3 contract verification: PASS'
