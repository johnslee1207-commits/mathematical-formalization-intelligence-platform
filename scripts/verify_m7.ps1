[CmdletBinding()]
param([string]$EnvironmentProfilePath=(Join-Path (Split-Path -Parent $PSScriptRoot) 'config/local/m0_environment.json'))
$ErrorActionPreference='Stop'; $projectRoot=Split-Path -Parent $PSScriptRoot; $profile=Get-Content -Raw $EnvironmentProfilePath|ConvertFrom-Json
if($profile.elan_home){$env:ELAN_HOME=$profile.elan_home}; if($profile.elan_bin){$env:Path=$profile.elan_bin+[IO.Path]::PathSeparator+$env:Path}; Set-Location $projectRoot
$mp=Join-Path $projectRoot 'benchmarks/m7_benchmark_05.json'; $sp=Join-Path $projectRoot 'M7/Benchmark.lean'; $np=Join-Path $projectRoot 'M7/Negative.lean'; $rp=Join-Path $projectRoot 'manifests/data_layers/registry.json'; $m=Get-Content -Raw $mp|ConvertFrom-Json; $s=Get-Content -Raw $sp; $n=Get-Content -Raw $np
if($m.cases.Count -ne 5){throw 'M7 case count mismatch'}; $ids=@{}
foreach($c in $m.cases){if($ids.ContainsKey($c.id)){throw 'M7 duplicate case ID'};$ids[$c.id]=$true;foreach($f in @('id','class','lean_declaration','target','negative_check')){if([string]::IsNullOrWhiteSpace([string]$c.$f)){throw "M7 missing $f"}};if(-not $s.Contains("theorem $($c.lean_declaration)")){throw 'M7 proof mapping missing'};if(-not $n.Contains("theorem $($c.negative_check)")){throw 'M7 negative mapping missing'}}
lake build M7;if($LASTEXITCODE -ne 0){throw 'M7 build failed'}
[pscustomobject]@{schema='m7-acceptance-report.v1';benchmark_id=$m.benchmark_id;case_count=$m.cases.Count;profile_scope=$profile.profile_scope;manifest_sha256=(Get-FileHash $mp -Algorithm SHA256).Hash;registry_sha256=(Get-FileHash $rp -Algorithm SHA256).Hash;benchmark_source_sha256=(Get-FileHash $sp -Algorithm SHA256).Hash;negative_source_sha256=(Get-FileHash $np -Algorithm SHA256).Hash;toolchain=(Get-Content -Raw (Join-Path $projectRoot 'lean-toolchain')).Trim();status='pass'}|ConvertTo-Json|Set-Content (Join-Path $projectRoot 'reports/m7_acceptance_report.json')
Write-Host 'M7 Lean/Mathlib acceptance: PASS'
