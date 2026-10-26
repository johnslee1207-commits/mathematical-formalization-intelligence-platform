[CmdletBinding()]
param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$fixture = Join-Path ([IO.Path]::GetTempPath()) ("m2-corruption-" + [guid]::NewGuid().ToString('N'))

function Copy-Fixture {
  New-Item -ItemType Directory -Path (Join-Path $fixture 'reports') -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $fixture 'manifests/data_layers') -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $fixture 'benchmarks') -Force | Out-Null
  Copy-Item (Join-Path $projectRoot 'reports/*.json') (Join-Path $fixture 'reports')
  Copy-Item (Join-Path $projectRoot 'manifests/data_layers/registry.json') (Join-Path $fixture 'manifests/data_layers')
  Copy-Item (Join-Path $projectRoot 'benchmarks/*.json') (Join-Path $fixture 'benchmarks')
  Copy-Item (Join-Path $projectRoot 'benchmarks/m2_metadata_contract.json') $fixture
}

function Expect-Failure([scriptblock]$Action, [string]$Name) {
  try {
    & $Action
    throw "Corruption case was accepted: $Name"
  } catch {
    if ($_.Exception.Message -like "Corruption case was accepted: $Name") { throw }
  }
}

try {
  New-Item -ItemType Directory -Path $fixture -Force | Out-Null

  Copy-Fixture
  $path = Join-Path $fixture 'reports/m0_replay_report.json'
  $report = Get-Content -Raw $path | ConvertFrom-Json
  $report.benchmark_id = 'm0-corrupted-id'
  $report | ConvertTo-Json -Depth 8 | Set-Content $path -Encoding utf8
  Expect-Failure { & (Join-Path $projectRoot 'scripts/verify_m2_evidence.ps1') -ProjectRoot $fixture } 'benchmark ID mismatch'

  Remove-Item -LiteralPath $fixture -Recurse -Force
  Copy-Fixture
  $path = Join-Path $fixture 'reports/m1_acceptance_report.json'
  $report = Get-Content -Raw $path | ConvertFrom-Json
  $report.manifest_sha256 = ('0' * 64)
  $report | ConvertTo-Json -Depth 8 | Set-Content $path -Encoding utf8
  Expect-Failure { & (Join-Path $projectRoot 'scripts/verify_m2_evidence.ps1') -ProjectRoot $fixture } 'hash mismatch'

  Remove-Item -LiteralPath $fixture -Recurse -Force
  Copy-Fixture
  $path = Join-Path $fixture 'reports/m0_acceptance_report.json'
  $report = Get-Content -Raw $path | ConvertFrom-Json
  $report.schema = 'corrupted-schema.v1'
  $report | ConvertTo-Json -Depth 8 | Set-Content $path -Encoding utf8
  Expect-Failure { & (Join-Path $projectRoot 'scripts/verify_m2_evidence.ps1') -ProjectRoot $fixture } 'schema mismatch'

  Remove-Item -LiteralPath $fixture -Recurse -Force
  Copy-Fixture
  New-Item -ItemType Directory -Path (Join-Path $fixture 'unregistered') -Force | Out-Null
  Copy-Item (Join-Path $fixture 'benchmarks/m0_benchmark_10.json') (Join-Path $fixture 'unregistered/m0.json')
  $path = Join-Path $fixture 'benchmarks/m2_metadata_contract.json'
  $contract = Get-Content -Raw $path | ConvertFrom-Json
  $contract.manifest_paths.M0 = 'unregistered/m0.json'
  $contract | ConvertTo-Json -Depth 8 | Set-Content $path -Encoding utf8
  Expect-Failure { & (Join-Path $projectRoot 'scripts/check_m2_metadata.ps1') -ProjectRoot $fixture } 'unregistered path'

  Write-Host 'M2 corruption and replay gates: PASS'
} finally {
  if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
