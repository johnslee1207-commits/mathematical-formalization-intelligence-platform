[CmdletBinding()]
param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
Set-Location -LiteralPath $projectRoot

$contract = Get-Content -Raw (Join-Path $projectRoot 'M1/phase_contract.json') | ConvertFrom-Json
$manifest = Get-Content -Raw (Join-Path $projectRoot 'benchmarks/m1_benchmark_05.json') | ConvertFrom-Json
$benchmarkSource = Get-Content -Raw (Join-Path $projectRoot 'M1/Benchmark.lean')
$negativeSource = Get-Content -Raw (Join-Path $projectRoot 'M1/Negative.lean')
if ($contract.schema -ne 'm1-task-contract.v1') { throw 'M1 contract schema mismatch' }
if ($contract.phase -ne 'M1') { throw 'M1 phase mismatch' }
if ($contract.status -notin @('started', 'in_progress')) { throw 'M1 contract must be started before implementation' }
if ($contract.deliverables.Count -lt 5) { throw 'M1 contract must contain at least five deliverables' }
if ($contract.negative_corpus_requirements.minimum_distinct_checks -lt 2) { throw 'M1 negative corpus minimum is too small' }
if (-not $contract.independent_verifier.must_run_without_lake_build) { throw 'M1 verifier must be independent of lake build' }
if (-not $contract.replay_policy.hash_manifest) { throw 'M1 replay must hash the manifest' }
if (-not $contract.replay_policy.hash_sources) { throw 'M1 replay must hash sources' }
if (-not $contract.replay_policy.hash_data_layer_registry) { throw 'M1 replay must hash the registry' }
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'M1/README.md'))) { throw 'M1 README is missing' }
if ($manifest.benchmark_id -ne 'm1-lean-formalization-05') { throw 'M1 benchmark ID mismatch' }
if ($manifest.cases.Count -ne 5) { throw 'M1 benchmark must contain exactly five cases' }
$caseIds = @($manifest.cases.id)
$declarations = @($manifest.cases.lean_declaration)
$negativeChecks = @($manifest.cases.negative_check | Sort-Object -Unique)
if (($caseIds | Sort-Object -Unique).Count -ne $caseIds.Count) { throw 'M1 case IDs must be unique' }
if (($declarations | Sort-Object -Unique).Count -ne $declarations.Count) { throw 'M1 declarations must be unique' }
if ($negativeChecks.Count -lt 2) { throw 'M1 must reference at least two distinct negative checks' }
foreach ($case in $manifest.cases) {
  foreach ($field in @('id', 'class', 'lean_declaration', 'target', 'negative_check')) {
    if ([string]::IsNullOrWhiteSpace([string]$case.$field)) { throw "M1 case $($case.id) missing $field" }
  }
  if (-not $benchmarkSource.Contains("theorem $($case.lean_declaration)")) { throw "M1 declaration missing: $($case.lean_declaration)" }
  if (-not $negativeSource.Contains("theorem $($case.negative_check)")) { throw "M1 negative check missing: $($case.negative_check)" }
}
$registry = Get-Content -Raw (Join-Path $projectRoot 'manifests/data_layers/registry.json') | ConvertFrom-Json
foreach ($requiredPath in @('M1/', 'benchmarks/', 'reports/', 'scripts/')) {
  $matches = @($registry.layers.PSObject.Properties | Where-Object { $_.Value -contains $requiredPath })
  if ($matches.Count -ne 1) { throw "M1 data-layer classification count for $requiredPath is $($matches.Count)" }
}
Write-Host 'M1 contract verification: PASS'

