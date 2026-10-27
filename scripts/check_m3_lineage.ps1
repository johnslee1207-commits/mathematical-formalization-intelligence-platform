[CmdletBinding()]
param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$manifestPath = Join-Path $projectRoot 'benchmarks/m3_benchmark_05.json'
$registryPath = Join-Path $projectRoot 'manifests/data_layers/registry.json'
$sourcePath = Join-Path $projectRoot 'M3/Benchmark.lean'
$negativePath = Join-Path $projectRoot 'M3/Negative.lean'
$manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
$sourceText = Get-Content -Raw $sourcePath
$negativeText = Get-Content -Raw $negativePath
$registry = Get-Content -Raw $registryPath | ConvertFrom-Json
if (-not ($registry.layers.domain_common -contains 'benchmarks/')) { throw 'Benchmark data layer is not registered' }
if (-not ($registry.layers.domain_common -contains 'M3/')) { throw 'M3 data layer is not registered' }
if ($manifest.schema) { throw 'M3 manifest must not embed a report schema' }
if ($manifest.benchmark_id -notlike 'm3-*' -or $manifest.cases.Count -ne 5) { throw 'M3 manifest metadata mismatch' }
$ids = @{}
foreach ($case in $manifest.cases) {
  foreach ($field in @('id','class','lean_declaration','target','negative_check')) {
    if ([string]::IsNullOrWhiteSpace([string]$case.$field)) { throw "M3 case missing $field" }
  }
  if (-not ([string]$case.id).StartsWith('M3-')) { throw "M3 case ID prefix mismatch: $($case.id)" }
  if ($ids.ContainsKey([string]$case.id)) { throw "Duplicate M3 case ID: $($case.id)" }
  $ids[[string]$case.id] = $true
  if (-not $sourceText.Contains("theorem $($case.lean_declaration)")) { throw "M3 declaration missing: $($case.lean_declaration)" }
  if (-not $negativeText.Contains("theorem $($case.negative_check)")) { throw "M3 negative check missing: $($case.negative_check)" }
}
Write-Host 'M3 independent lineage verification: PASS'
