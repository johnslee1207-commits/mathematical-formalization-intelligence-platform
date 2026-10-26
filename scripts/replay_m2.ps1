[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

& "$PSScriptRoot\check_m2_contract.ps1"
& "$PSScriptRoot\verify_m2_evidence.ps1"

$indexPath = Join-Path $projectRoot 'reports/m2_evidence_index.json'
$registryPath = Join-Path $projectRoot 'manifests/data_layers/registry.json'
$index = Get-Content -Raw $indexPath | ConvertFrom-Json
if ($index.status -ne 'pass') { throw 'M2 replay failed: evidence index is not pass' }

[pscustomobject]@{
  schema = 'm2-replay-report.v1'
  index_sha256 = (Get-FileHash $indexPath -Algorithm SHA256).Hash
  registry_sha256 = (Get-FileHash $registryPath -Algorithm SHA256).Hash
  phase_count = @($index.phases).Count
  acceptance_status = 'pass'
  replay_status = 'pass'
} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $projectRoot 'reports/m2_replay_report.json') -Encoding utf8

Write-Host 'M2 deterministic replay: PASS'

