[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

$contract = Get-Content -Raw (Join-Path $projectRoot 'M2/phase_contract.json') | ConvertFrom-Json
if ($contract.schema -ne 'm2-task-contract.v1') { throw 'M2 contract schema mismatch' }
if ($contract.phase -ne 'M2') { throw 'M2 phase mismatch' }
if ($contract.status -ne 'started') { throw 'M2 contract must start in started state' }
if ($contract.deliverables.Count -ne 5) { throw 'M2 must contain five deliverables' }
if (-not $contract.replay_policy.locked_toolchain) { throw 'M2 must retain locked toolchain policy' }
if (-not $contract.replay_policy.cross_phase_hash_lineage) { throw 'M2 must retain cross-phase hash lineage' }
if (-not $contract.replay_policy.temporary_fixture_negative_tests) { throw 'M2 must include fixture negative tests' }
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'M2/README.md'))) { throw 'M2 README is missing' }
$registry = Get-Content -Raw (Join-Path $projectRoot 'manifests/data_layers/registry.json') | ConvertFrom-Json
if (-not ($registry.layers.domain_common -contains 'M2/')) { throw 'M2 path is not registered as domain common' }
Write-Host 'M2 contract verification: PASS'

