[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

$contract = Get-Content -Raw 'M1\phase_contract.json' | ConvertFrom-Json
if ($contract.schema -ne 'm1-task-contract.v1') { throw 'M1 contract schema mismatch' }
if ($contract.phase -ne 'M1') { throw 'M1 phase mismatch' }
if ($contract.status -notin @('started', 'in_progress')) { throw 'M1 contract must be started before implementation' }
if ($contract.deliverables.Count -lt 5) { throw 'M1 contract must contain at least five deliverables' }
if ($contract.negative_corpus_requirements.minimum_distinct_checks -lt 2) { throw 'M1 negative corpus minimum is too small' }
if (-not $contract.independent_verifier.must_run_without_lake_build) { throw 'M1 verifier must be independent of lake build' }
if (-not $contract.replay_policy.hash_manifest) { throw 'M1 replay must hash the manifest' }
if (-not $contract.replay_policy.hash_sources) { throw 'M1 replay must hash sources' }
if (-not $contract.replay_policy.hash_data_layer_registry) { throw 'M1 replay must hash the registry' }
if (-not (Test-Path -LiteralPath 'M1\README.md')) { throw 'M1 README is missing' }
$registry = Get-Content -Raw 'manifests\data_layers\registry.json' | ConvertFrom-Json
if (-not ($registry.layers.domain_common -contains 'M1/')) { throw 'M1 path is not registered as domain common' }
Write-Host 'M1 contract verification: PASS'

