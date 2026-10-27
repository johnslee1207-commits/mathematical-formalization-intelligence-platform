[CmdletBinding()]
param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$fixture = Join-Path ([IO.Path]::GetTempPath()) ("m3-corruption-" + [guid]::NewGuid().ToString('N'))
function Copy-Fixture {
  New-Item -ItemType Directory -Path (Join-Path $fixture 'M3') -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $fixture 'benchmarks') -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $fixture 'manifests/data_layers') -Force | Out-Null
  Copy-Item (Join-Path $projectRoot 'M3/*.lean') (Join-Path $fixture 'M3')
  Copy-Item (Join-Path $projectRoot 'benchmarks/m3_benchmark_05.json') (Join-Path $fixture 'benchmarks')
  Copy-Item (Join-Path $projectRoot 'manifests/data_layers/registry.json') (Join-Path $fixture 'manifests/data_layers')
}
function Expect-Failure([scriptblock]$Action, [string]$Name) {
  try { & $Action; throw "Corruption case was accepted: $Name" } catch {
    if ($_.Exception.Message -like "Corruption case was accepted: $Name") { throw }
  }
}
try {
  New-Item -ItemType Directory -Path $fixture -Force | Out-Null
  Copy-Fixture
  $p = Join-Path $fixture 'benchmarks/m3_benchmark_05.json'
  $m = Get-Content -Raw $p | ConvertFrom-Json; $m.cases[0].lean_declaration = 'm3_01_corrupted'; $m | ConvertTo-Json -Depth 8 | Set-Content $p
  Expect-Failure { & (Join-Path $projectRoot 'scripts/check_m3_lineage.ps1') -ProjectRoot $fixture } 'manifest mutation'
  Remove-Item $fixture -Recurse -Force; Copy-Fixture
  $p = Join-Path $fixture 'M3/Benchmark.lean'; (Get-Content -Raw $p).Replace('m3_01_and_comm','m3_01_corrupted') | Set-Content $p
  Expect-Failure { & (Join-Path $projectRoot 'scripts/check_m3_lineage.ps1') -ProjectRoot $fixture } 'proof source mutation'
  Remove-Item $fixture -Recurse -Force; Copy-Fixture
  $p = Join-Path $fixture 'M3/Negative.lean'; (Get-Content -Raw $p).Replace('m3_neg_01_not_two_eq_three','m3_neg_01_corrupted') | Set-Content $p
  Expect-Failure { & (Join-Path $projectRoot 'scripts/check_m3_lineage.ps1') -ProjectRoot $fixture } 'negative source mutation'
  Write-Host 'M3 corruption replay gates: PASS'
} finally { if (Test-Path $fixture) { Remove-Item $fixture -Recurse -Force } }
