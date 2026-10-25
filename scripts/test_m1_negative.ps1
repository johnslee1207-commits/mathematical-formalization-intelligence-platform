[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$originalLocation = (Get-Location).Path
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("m1-negative-" + [guid]::NewGuid().ToString('N'))

try {
  New-Item -ItemType Directory -Force -Path (Join-Path $tempRoot 'M1') | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $tempRoot 'benchmarks') | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $tempRoot 'manifests\data_layers') | Out-Null
  Copy-Item (Join-Path $projectRoot 'M1\phase_contract.json') (Join-Path $tempRoot 'M1\phase_contract.json')
  Copy-Item (Join-Path $projectRoot 'M1\README.md') (Join-Path $tempRoot 'M1\README.md')
  Copy-Item (Join-Path $projectRoot 'M1\Benchmark.lean') (Join-Path $tempRoot 'M1\Benchmark.lean')
  Copy-Item (Join-Path $projectRoot 'M1\Negative.lean') (Join-Path $tempRoot 'M1\Negative.lean')
  Copy-Item (Join-Path $projectRoot 'benchmarks\m1_benchmark_05.json') (Join-Path $tempRoot 'benchmarks\m1_benchmark_05.json')
  Copy-Item (Join-Path $projectRoot 'manifests\data_layers\registry.json') (Join-Path $tempRoot 'manifests\data_layers\registry.json')

  $manifestPath = Join-Path $tempRoot 'benchmarks\m1_benchmark_05.json'
  $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
  $manifest.cases[1].id = $manifest.cases[0].id
  $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding utf8

  $failed = $false
  try {
    & "$PSScriptRoot\check_m1_contract.ps1" -ProjectRoot $tempRoot
  }
  catch {
    $failed = $true
  }
  if (-not $failed) { throw 'Negative test failed: duplicate case ID was accepted' }
  Write-Host 'M1 negative contract test: PASS'
}
finally {
  Set-Location -LiteralPath $originalLocation
  if (Test-Path -LiteralPath $tempRoot) {
    for ($attempt = 1; $attempt -le 5; $attempt++) {
      try {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction Stop
        break
      }
      catch {
        if ($attempt -eq 5) { throw }
        Start-Sleep -Milliseconds 250
      }
    }
  }
}
