[CmdletBinding()]
param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$reports = Join-Path $projectRoot 'reports'

function Read-Report([string]$name) {
  $path = Join-Path $reports $name
  if (-not (Test-Path -LiteralPath $path)) { throw "Missing evidence report: $name" }
  return Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
}

$m0Acceptance = Read-Report 'm0_acceptance_report.json'
$m0Replay = Read-Report 'm0_replay_report.json'
$m1Acceptance = Read-Report 'm1_acceptance_report.json'
$m1Replay = Read-Report 'm1_replay_report.json'

if ($m0Acceptance.schema -ne 'm0-acceptance-report.v1') { throw 'M0 acceptance schema mismatch' }
if ($m0Replay.schema -ne 'm0-replay-report.v1') { throw 'M0 replay schema mismatch' }
if ($m1Acceptance.schema -ne 'm1-acceptance-report.v1') { throw 'M1 acceptance schema mismatch' }
if ($m1Replay.schema -ne 'm1-replay-report.v1') { throw 'M1 replay schema mismatch' }
if ($m0Acceptance.status -ne 'pass' -or $m0Replay.replay_status -ne 'pass') { throw 'M0 evidence is not passing' }
if ($m1Acceptance.status -ne 'pass' -or $m1Replay.replay_status -ne 'pass') { throw 'M1 evidence is not passing' }

foreach ($pair in @(@($m0Acceptance, $m0Replay), @($m1Acceptance, $m1Replay))) {
  if ($pair[0].benchmark_id -ne $pair[1].benchmark_id) { throw 'Acceptance/replay benchmark ID mismatch' }
  foreach ($field in @('manifest_sha256', 'benchmark_source_sha256', 'negative_source_sha256')) {
    if ($pair[0].$field -ne $pair[1].$field) { throw "Acceptance/replay hash mismatch: $field" }
  }
  if ($pair[0].toolchain -ne $pair[1].toolchain) { throw 'Acceptance/replay toolchain mismatch' }
  foreach ($field in @('environment_profile', 'workflow_entry_point', 'replay_entry_point', 'profile_scope')) {
    if ([string]::IsNullOrWhiteSpace([string]$pair[1].$field)) { throw "Replay report is missing CI evidence binding: $field" }
  }
}

$registryHash = (Get-FileHash (Join-Path $projectRoot 'manifests/data_layers/registry.json') -Algorithm SHA256).Hash
if ($m0Acceptance.data_layer_registry_sha256 -ne $registryHash) { throw 'M0 registry hash is stale' }
if ($m1Acceptance.data_layer_registry_sha256 -ne $registryHash) { throw 'M1 registry hash is stale' }

$entries = @(
  [pscustomobject]@{
    phase = 'M0'
    benchmark_id = $m0Acceptance.benchmark_id
    case_count = $m0Acceptance.case_count
    acceptance_status = $m0Acceptance.status
    replay_status = $m0Replay.replay_status
    manifest_sha256 = $m0Acceptance.manifest_sha256
    benchmark_source_sha256 = $m0Acceptance.benchmark_source_sha256
    negative_source_sha256 = $m0Acceptance.negative_source_sha256
    toolchain = $m0Acceptance.toolchain
    profile_scope = $m0Replay.profile_scope
    environment_profile = $m0Replay.environment_profile
    workflow_entry_point = $m0Replay.workflow_entry_point
    replay_entry_point = $m0Replay.replay_entry_point
  },
  [pscustomobject]@{
    phase = 'M1'
    benchmark_id = $m1Acceptance.benchmark_id
    case_count = $m1Acceptance.case_count
    acceptance_status = $m1Acceptance.status
    replay_status = $m1Replay.replay_status
    manifest_sha256 = $m1Acceptance.manifest_sha256
    benchmark_source_sha256 = $m1Acceptance.benchmark_source_sha256
    negative_source_sha256 = $m1Acceptance.negative_source_sha256
    toolchain = $m1Acceptance.toolchain
    profile_scope = $m1Acceptance.profile_scope
    environment_profile = $m1Replay.environment_profile
    workflow_entry_point = $m1Replay.workflow_entry_point
    replay_entry_point = $m1Replay.replay_entry_point
  }
)

[pscustomobject]@{
  schema = 'm2-evidence-index.v1'
  generated_by = 'scripts/verify_m2_evidence.ps1'
  registry_sha256 = $registryHash
  phases = $entries
  status = 'pass'
} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $reports 'm2_evidence_index.json') -Encoding utf8

Write-Host 'M2 evidence index verification: PASS'

