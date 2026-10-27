[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path $ProjectRoot).Path
$reportPath = Join-Path $projectRoot 'reports/m3_replay_report.json'
$report = Get-Content -Raw $reportPath | ConvertFrom-Json
if ($report.schema -ne 'm3-replay-report.v1' -or $report.replay_status -ne 'pass') { throw 'M3 replay evidence is not passing' }
$paths = @('benchmarks/m3_benchmark_05.json','M3/Benchmark.lean','M3/Negative.lean','manifests/data_layers/registry.json')
foreach ($path in $paths) { if (-not (Test-Path (Join-Path $projectRoot $path))) { throw "M3 evidence path missing: $path" } }
if ($report.manifest_sha256 -ne (Get-FileHash (Join-Path $projectRoot 'benchmarks/m3_benchmark_05.json') -Algorithm SHA256).Hash) { throw 'M3 manifest evidence hash mismatch' }
if ($report.registry_sha256 -ne (Get-FileHash (Join-Path $projectRoot 'manifests/data_layers/registry.json') -Algorithm SHA256).Hash) { throw 'M3 registry evidence hash mismatch' }
$readinessPath = Join-Path $projectRoot 'reports/m2_readiness_report.json'
$readiness = Get-Content -Raw $readinessPath | ConvertFrom-Json
if ($readiness.status -ne 'ready' -or $report.m2_readiness_sha256 -ne (Get-FileHash $readinessPath -Algorithm SHA256).Hash) { throw 'M2 readiness binding mismatch' }
if ($report.workflow_entry_point -ne '.github/workflows/lean_action_ci.yml' -or -not (Test-Path (Join-Path $projectRoot $report.workflow_entry_point))) { throw 'M3 CI workflow binding mismatch' }
if (-not (Test-Path (Join-Path $projectRoot $report.environment_profile))) { throw 'M3 environment profile binding missing' }
[pscustomobject]@{ schema='m3-evidence-binding-report.v1'; m2_readiness_sha256=$report.m2_readiness_sha256; registry_sha256=$report.registry_sha256; workflow_entry_point=$report.workflow_entry_point; environment_profile=$report.environment_profile; status='pass' } | ConvertTo-Json | Set-Content (Join-Path $projectRoot 'reports/m3_evidence_binding_report.json')
Write-Host 'M3 cross-phase evidence binding: PASS'
