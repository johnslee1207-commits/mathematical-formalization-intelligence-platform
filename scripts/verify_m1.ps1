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

$manifestPath = Join-Path $projectRoot 'benchmarks/m1_benchmark_05.json'
$registryPath = Join-Path $projectRoot 'manifests/data_layers/registry.json'
$sourcePath = Join-Path $projectRoot 'M1/Benchmark.lean'
$negativePath = Join-Path $projectRoot 'M1/Negative.lean'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$sourceText = Get-Content -Raw -LiteralPath $sourcePath
$negativeText = Get-Content -Raw -LiteralPath $negativePath
$registry = Get-Content -Raw -LiteralPath $registryPath | ConvertFrom-Json
if ($profile.profile_scope -eq 'ci' -and ($profile.elan_home -or $profile.elan_bin)) { throw 'CI profile must not contain machine-specific Elan paths' }
if ($profile.profile_scope -eq 'local' -and (-not $profile.elan_home -or -not $profile.elan_bin)) { throw 'Local profile must contain Elan paths' }
if (-not ($registry.layers.domain_common -contains 'M1/')) { throw 'M1 data layer is not registered' }
if ($manifest.cases.Count -ne 5) { throw 'M1 benchmark must contain exactly 5 cases' }
if (@($manifest.cases.id | Sort-Object -Unique).Count -ne $manifest.cases.Count) { throw 'M1 case IDs must be unique' }
if (@($manifest.cases.lean_declaration | Sort-Object -Unique).Count -ne $manifest.cases.Count) { throw 'M1 declarations must be unique' }
foreach ($case in $manifest.cases) {
  foreach ($field in @('id', 'class', 'lean_declaration', 'target', 'negative_check')) {
    if ([string]::IsNullOrWhiteSpace([string]$case.$field)) { throw "M1 case $($case.id) missing $field" }
  }
  if (-not $sourceText.Contains("theorem $($case.lean_declaration)")) { throw "M1 declaration missing: $($case.lean_declaration)" }
  if (-not $negativeText.Contains("theorem $($case.negative_check)")) { throw "M1 negative check missing: $($case.negative_check)" }
}
$lean = Get-Command lean -ErrorAction Stop
$lake = Get-Command lake -ErrorAction Stop
if ($profile.elan_bin -and -not (Test-Path -LiteralPath $profile.elan_bin)) { throw "Configured Elan bin path is unavailable: $($profile.elan_bin)" }
$classCounts = [ordered]@{}
$manifest.cases | Group-Object -Property class | Sort-Object Name | ForEach-Object { $classCounts[$_.Name] = $_.Count }
Write-Host "Lean: $(& $lean.Source --version)"
Write-Host "Lake: $(& $lake.Source --version)"
lake build M1
if ($LASTEXITCODE -ne 0) { throw "M1 Lean build failed with exit code $LASTEXITCODE" }
$reportDir = Join-Path $projectRoot 'reports'
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
[pscustomobject]@{
  schema = 'm1-acceptance-report.v1'
  benchmark_id = $manifest.benchmark_id
  case_count = $manifest.cases.Count
  class_counts = $classCounts
  negative_check_count = @($manifest.cases.negative_check | Sort-Object -Unique).Count
  profile_scope = $profile.profile_scope
  data_layer_registry_sha256 = (Get-FileHash $registryPath -Algorithm SHA256).Hash
  manifest_sha256 = (Get-FileHash $manifestPath -Algorithm SHA256).Hash
  benchmark_source_sha256 = (Get-FileHash $sourcePath -Algorithm SHA256).Hash
  negative_source_sha256 = (Get-FileHash $negativePath -Algorithm SHA256).Hash
  toolchain = (Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'lean-toolchain')).Trim()
  lean = (& $lean.Source --version | Out-String).Trim()
  lake = (& $lake.Source --version | Out-String).Trim()
  status = 'pass'
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $reportDir 'm1_acceptance_report.json') -Encoding utf8
Write-Host 'M1 Lean/Mathlib acceptance: PASS'

