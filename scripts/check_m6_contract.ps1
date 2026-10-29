[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path $ProjectRoot).Path
$contract = Get-Content -Raw (Join-Path $projectRoot 'M6/phase_contract.json') | ConvertFrom-Json
if ($contract.schema -ne 'm6-task-contract.v1' -or $contract.phase -ne 'M6') { throw 'M6 contract schema or phase mismatch' }
if ($contract.status -ne 'started' -or $contract.deliverables.Count -ne 5) { throw 'M6 contract status or deliverables mismatch' }
if (-not $contract.replay_policy.locked_toolchain -or -not $contract.replay_policy.m5_readiness_required) { throw 'M6 replay policy is incomplete' }
if (-not (Test-Path (Join-Path $projectRoot 'M6/README.md'))) { throw 'M6 README is missing' }
$registry = Get-Content -Raw (Join-Path $projectRoot 'manifests/data_layers/registry.json') | ConvertFrom-Json
if (-not ($registry.layers.domain_common -contains 'M6/')) { throw 'M6 path is not registered as domain common' }
$readiness = Get-Content -Raw (Join-Path $projectRoot 'reports/m5_readiness_report.json') | ConvertFrom-Json
if ($readiness.status -ne 'ready' -or -not $readiness.next_phase_allowed) { throw 'M5 readiness does not permit M6' }
Write-Host 'M6 contract verification: PASS'
