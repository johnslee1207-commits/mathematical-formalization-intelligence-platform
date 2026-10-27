[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path $ProjectRoot).Path
$contract = Get-Content -Raw (Join-Path $projectRoot 'M4/phase_contract.json') | ConvertFrom-Json
if ($contract.schema -ne 'm4-task-contract.v1' -or $contract.phase -ne 'M4') { throw 'M4 contract schema or phase mismatch' }
if ($contract.status -ne 'started' -or $contract.deliverables.Count -ne 5) { throw 'M4 contract status or deliverables mismatch' }
if (-not $contract.replay_policy.locked_toolchain -or -not $contract.replay_policy.phase_readiness_required) { throw 'M4 replay policy is incomplete' }
if (-not (Test-Path (Join-Path $projectRoot 'M4/README.md'))) { throw 'M4 README is missing' }
$registry = Get-Content -Raw (Join-Path $projectRoot 'manifests/data_layers/registry.json') | ConvertFrom-Json
if (-not ($registry.layers.domain_common -contains 'M4/')) { throw 'M4 path is not registered as domain common' }
$readiness = Get-Content -Raw (Join-Path $projectRoot 'reports/m3_readiness_report.json') | ConvertFrom-Json
if ($readiness.status -ne 'ready' -or -not $readiness.next_phase_allowed) { throw 'M3 readiness does not permit M4' }
Write-Host 'M4 contract verification: PASS'
