[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference='Stop'; $projectRoot=(Resolve-Path $ProjectRoot).Path
$c=Get-Content -Raw (Join-Path $projectRoot 'M7/phase_contract.json')|ConvertFrom-Json
if($c.schema -ne 'm7-task-contract.v1' -or $c.phase -ne 'M7' -or $c.deliverables.Count -ne 5){throw 'M7 contract mismatch'}
$r=Get-Content -Raw (Join-Path $projectRoot 'manifests/data_layers/registry.json')|ConvertFrom-Json
if(-not ($r.layers.domain_common -contains 'M7/')){throw 'M7 path is not registered'}
$ready=Get-Content -Raw (Join-Path $projectRoot 'reports/m6_readiness_report.json')|ConvertFrom-Json
if($ready.status -ne 'ready' -or -not $ready.next_phase_allowed){throw 'M6 readiness does not permit M7'}
Write-Host 'M7 contract verification: PASS'
