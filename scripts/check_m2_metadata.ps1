[CmdletBinding()]
param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$contractPath = Join-Path $projectRoot 'benchmarks/m2_metadata_contract.json'
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
if ($contract.schema -ne 'm2-benchmark-metadata-contract.v1') { throw 'M2 metadata contract schema mismatch' }
$registry = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'manifests/data_layers/registry.json') | ConvertFrom-Json

$entries = @()
foreach ($phase in @('M0', 'M1')) {
  $relativePath = $contract.manifest_paths.$phase
  $registered = @($registry.layers.domain_common | Where-Object { $relativePath.StartsWith([string]$_) }).Count -gt 0
  if (-not $registered) { throw "$phase manifest path is not registered: $relativePath" }
  $path = Join-Path $projectRoot $relativePath
  if (-not (Test-Path -LiteralPath $path)) { throw "$phase manifest is missing: $relativePath" }
  $manifest = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
  foreach ($field in $contract.required_manifest_fields) {
    if ($null -eq $manifest.$field) { throw "$phase manifest is missing required field: $field" }
  }
  if (-not ([string]$manifest.benchmark_id).StartsWith([string]$contract.benchmark_id_prefixes.$phase)) { throw "$phase benchmark ID prefix mismatch" }
  if ($manifest.cases.Count -eq 0) { throw "$phase manifest has no cases" }

  $caseIds = @{}
  foreach ($case in $manifest.cases) {
    foreach ($field in $contract.required_case_fields) {
      if ($null -eq $case.$field -or [string]::IsNullOrWhiteSpace([string]$case.$field)) {
        throw "$phase case is missing required field: $field"
      }
    }
    if (-not ([string]$case.id).StartsWith([string]$contract.id_prefixes.$phase)) { throw "$phase case ID prefix mismatch: $($case.id)" }
    if ($caseIds.ContainsKey([string]$case.id)) { throw "Duplicate $phase case ID: $($case.id)" }
    $caseIds[[string]$case.id] = $true
  }

  $entries += [pscustomobject]@{
    phase = $phase
    manifest_path = $relativePath
    benchmark_id = $manifest.benchmark_id
    version = $manifest.version
    oracle = $manifest.oracle
    case_count = $manifest.cases.Count
    manifest_sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    profile_scope = [string]$contract.profile_scope
  }
}

[pscustomobject]@{
  schema = 'm2-benchmark-metadata-report.v1'
  generated_by = 'scripts/check_m2_metadata.ps1'
  contract_sha256 = (Get-FileHash -LiteralPath $contractPath -Algorithm SHA256).Hash
  manifests = $entries
  status = 'pass'
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $projectRoot 'reports/m2_benchmark_metadata_report.json') -Encoding utf8

Write-Host 'M2 benchmark metadata verification: PASS'
