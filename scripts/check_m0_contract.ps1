[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

$manifest = Get-Content -Raw 'benchmarks\m0_benchmark_10.json' | ConvertFrom-Json
$registry = Get-Content -Raw 'manifests\data_layers\registry.json' | ConvertFrom-Json
$benchmarkSource = Get-Content -Raw 'M0\Benchmark.lean'
$negativeSource = Get-Content -Raw 'M0\Negative.lean'

if ($manifest.benchmark_id -ne 'm0-lean-formalization-10') { throw 'Contract failed: unexpected benchmark ID' }
if ($manifest.cases.Count -ne 10) { throw 'Contract failed: expected 10 benchmark cases' }

$ids = @($manifest.cases.id)
$declarations = @($manifest.cases.lean_declaration)
if (($ids | Sort-Object -Unique).Count -ne $ids.Count) { throw 'Contract failed: duplicate case ID' }
if (($declarations | Sort-Object -Unique).Count -ne $declarations.Count) { throw 'Contract failed: duplicate Lean declaration' }

foreach ($case in $manifest.cases) {
  foreach ($field in @('id', 'class', 'lean_declaration', 'target', 'negative_check')) {
    if ([string]::IsNullOrWhiteSpace([string]$case.$field)) { throw "Contract failed: missing $field in $($case.id)" }
  }
  if (-not $benchmarkSource.Contains("theorem $($case.lean_declaration)")) {
    throw "Contract failed: missing declaration $($case.lean_declaration)"
  }
  if (-not $negativeSource.Contains("theorem $($case.negative_check)")) {
    throw "Contract failed: missing negative check $($case.negative_check)"
  }
}

foreach ($requiredPath in @('scripts/', 'benchmarks/', 'M0/', 'reports/', 'config/local/', 'config/ci/')) {
  $found = @($registry.layers.PSObject.Properties | Where-Object { $_.Value -contains $requiredPath })
  if ($found.Count -ne 1) { throw "Contract failed: path classification count for $requiredPath is $($found.Count)" }
}

Write-Host 'M0 contract verification: PASS'

