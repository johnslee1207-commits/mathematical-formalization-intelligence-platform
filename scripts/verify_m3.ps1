[CmdletBinding()]
param(
  [string]$EnvironmentProfilePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'config/local/m0_environment.json')
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$profile = Get-Content -Raw -LiteralPath $EnvironmentProfilePath | ConvertFrom-Json
if ($profile.elan_home) { $env:ELAN_HOME = $profile.elan_home }
if ($profile.elan_bin) { $env:Path = $profile.elan_bin + [IO.Path]::PathSeparator + $env:Path }
Set-Location -LiteralPath $projectRoot
& "$PSScriptRoot\check_m3_lineage.ps1" -ProjectRoot $projectRoot

$manifestPath = Join-Path $projectRoot 'benchmarks/m3_benchmark_05.json'
$registryPath = Join-Path $projectRoot 'manifests/data_layers/registry.json'
$sourcePath = Join-Path $projectRoot 'M3/Benchmark.lean'
$negativePath = Join-Path $projectRoot 'M3/Negative.lean'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$sourceText = Get-Content -Raw -LiteralPath $sourcePath
$negativeText = Get-Content -Raw -LiteralPath $negativePath
$registry = Get-Content -Raw -LiteralPath $registryPath | ConvertFrom-Json
if (-not ($registry.layers.domain_common -contains 'M3/')) { throw 'M3 data layer is not registered' }
if ($manifest.cases.Count -ne 5) { throw 'M3 benchmark must contain exactly 5 cases' }
if (@($manifest.cases.id | Sort-Object -Unique).Count -ne $manifest.cases.Count) { throw 'M3 case IDs must be unique' }
foreach ($case in $manifest.cases) {
  foreach ($field in @('id', 'class', 'lean_declaration', 'target', 'negative_check')) {
    if ([string]::IsNullOrWhiteSpace([string]$case.$field)) { throw "M3 case $($case.id) missing $field" }
  }
  if (-not $sourceText.Contains("theorem $($case.lean_declaration)")) { throw "M3 declaration missing: $($case.lean_declaration)" }
  if (-not $negativeText.Contains("theorem $($case.negative_check)")) { throw "M3 negative check missing: $($case.negative_check)" }
}
$lean = Get-Command lean -ErrorAction Stop
$lake = Get-Command lake -ErrorAction Stop
lake build M3
if ($LASTEXITCODE -ne 0) { throw "M3 Lean build failed with exit code $LASTEXITCODE" }
$classCounts = [ordered]@{}
$manifest.cases | Group-Object -Property class | Sort-Object Name | ForEach-Object { $classCounts[$_.Name] = $_.Count }
[pscustomobject]@{
  schema = 'm3-acceptance-report.v1'
  benchmark_id = $manifest.benchmark_id
  case_count = $manifest.cases.Count
  class_counts = $classCounts
  negative_check_count = @($manifest.cases.negative_check | Sort-Object -Unique).Count
  profile_scope = $profile.profile_scope
  data_layer_registry_sha256 = (Get-FileHash $registryPath -Algorithm SHA256).Hash
  manifest_sha256 = (Get-FileHash $manifestPath -Algorithm SHA256).Hash
  benchmark_source_sha256 = (Get-FileHash $sourcePath -Algorithm SHA256).Hash
  negative_source_sha256 = (Get-FileHash $negativePath -Algorithm SHA256).Hash
  toolchain = (Get-Content -Raw (Join-Path $projectRoot 'lean-toolchain')).Trim()
  lean = (& $lean.Source --version | Out-String).Trim()
  lake = (& $lake.Source --version | Out-String).Trim()
  status = 'pass'
} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $projectRoot 'reports/m3_acceptance_report.json') -Encoding utf8
Write-Host 'M3 Lean/Mathlib acceptance: PASS'
