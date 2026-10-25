[CmdletBinding()]
param(
  [string]$EnvironmentProfilePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'config\local\m0_environment.json')
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$profile = Get-Content -Raw -LiteralPath $EnvironmentProfilePath | ConvertFrom-Json
if ($profile.elan_home) { $env:ELAN_HOME = $profile.elan_home }
if ($profile.elan_bin) { $env:Path = $profile.elan_bin + [IO.Path]::PathSeparator + $env:Path }

Set-Location -LiteralPath $projectRoot
$manifestPath = Join-Path $projectRoot 'benchmarks\\m0_benchmark_10.json'
$registryPath = Join-Path $projectRoot 'manifests\\data_layers\\registry.json'
$benchmarkSourcePath = Join-Path $projectRoot 'M0\\Benchmark.lean'
$negativeSourcePath = Join-Path $projectRoot 'M0\\Negative.lean'
$sourceText = Get-Content -Raw -LiteralPath $benchmarkSourcePath
$negativeText = Get-Content -Raw -LiteralPath $negativeSourcePath
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$registry = Get-Content -Raw -LiteralPath $registryPath | ConvertFrom-Json
foreach ($requiredPath in @('scripts/', 'benchmarks/', 'M0/', 'reports/', 'config/local/', 'config/ci/')) {
  $registered = $false
  foreach ($layer in $registry.layers.PSObject.Properties) {
    if ($layer.Value -contains $requiredPath) { $registered = $true; break }
  }
  if (-not $registered) { throw "Data-layer registry is missing path classification: $requiredPath" }
}
if ($manifest.cases.Count -ne 10) { throw "M0 benchmark must contain exactly 10 cases" }
$caseIds = @($manifest.cases.id)
$declarations = @($manifest.cases.lean_declaration)
if (($caseIds | Sort-Object -Unique).Count -ne $caseIds.Count) { throw 'M0 benchmark case IDs must be unique' }
if (($declarations | Sort-Object -Unique).Count -ne $declarations.Count) { throw 'M0 Lean declarations must be unique' }
foreach ($case in $manifest.cases) {
  foreach ($field in @('id', 'class', 'lean_declaration', 'target', 'negative_check')) {
    if ([string]::IsNullOrWhiteSpace([string]$case.$field)) { throw "M0 benchmark case $($case.id) is missing field: $field" }
  }
  if (-not $sourceText.Contains("theorem $($case.lean_declaration)")) {
    throw "Missing Lean declaration: $($case.lean_declaration)"
  }
  if (-not $negativeText.Contains("theorem $($case.negative_check)")) {
    throw "Missing negative check: $($case.negative_check)"
  }
}
$lean = Get-Command lean -ErrorAction Stop
$lake = Get-Command lake -ErrorAction Stop
if ($profile.elan_bin -and -not (Test-Path -LiteralPath $profile.elan_bin)) { throw "Configured Elan bin path is unavailable: $($profile.elan_bin)" }
$classCounts = [ordered]@{}
$manifest.cases | Group-Object -Property class | Sort-Object Name | ForEach-Object { $classCounts[$_.Name] = $_.Count }
Write-Host "Lean: $(& $lean.Source --version)"
Write-Host "Lake: $(& $lake.Source --version)"
lake build
if ($LASTEXITCODE -ne 0) { throw "M0 Lean build failed with exit code $LASTEXITCODE" }
$reportDir = Join-Path $projectRoot 'reports'
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$report = [pscustomobject]@{
  schema = 'm0-acceptance-report.v1'
  benchmark_id = $manifest.benchmark_id
  case_count = $manifest.cases.Count
  class_counts = $classCounts
  negative_check_count = @($manifest.cases.negative_check | Sort-Object -Unique).Count
  data_layer_registry_sha256 = (Get-FileHash $registryPath -Algorithm SHA256).Hash
  data_layer_status = 'pass'
  manifest_sha256 = (Get-FileHash $manifestPath -Algorithm SHA256).Hash
  benchmark_source_sha256 = (Get-FileHash $benchmarkSourcePath -Algorithm SHA256).Hash
  negative_source_sha256 = (Get-FileHash $negativeSourcePath -Algorithm SHA256).Hash
  toolchain = (Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'lean-toolchain')).Trim()
  lean = (& $lean.Source --version | Out-String).Trim()
  lake = (& $lake.Source --version | Out-String).Trim()
  status = 'pass'
}
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $reportDir 'm0_acceptance_report.json') -Encoding utf8
Write-Host 'M0 Lean/Mathlib acceptance: PASS'
