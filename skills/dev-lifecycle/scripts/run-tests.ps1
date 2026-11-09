# =============================================================================
# run-tests.ps1 - Phase 4 test runner (PowerShell)
# =============================================================================
# [Feature] Run go test in backend and vitest in frontend; parse results.
# [Phase] Phase 4 (phase4.md).
# [Input] -PlanDir (required); run from repo root
# [Output]
#   <plan-dir>/test-results/*.log, test-counts.json
#   stdout: TESTS: pass|fail; exit 0/1
# [Flow]
#   1. Create test-results/ and batch separator
#   2. backend go test (when go.mod exists)
#   3. frontend vitest (when package.json exists)
#   4. Call parse-test-results.js
# [Usage] & <skill_root>/scripts/run-tests.ps1 -PlanDir <plan-dir>
# =============================================================================
param([Parameter(Mandatory = $true)][string]$PlanDir)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# scripts → dev-lifecycle → skills → .cursor → repo root
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..\..\..")).Path
Set-Location $RepoRoot

if (-not [System.IO.Path]::IsPathRooted($PlanDir)) {
  $PlanDir = Join-Path $RepoRoot $PlanDir
}
if (-not (Test-Path $PlanDir)) { Write-Error "PlanDir not found: $PlanDir"; exit 1 }
$PlanDir = (Resolve-Path $PlanDir).Path

$TestDir = Join-Path $PlanDir "test-results"
New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$sep = ">>>>>>>>>> TEST RUN @ $ts <<<<<<<<<<"

$goExit = 0
$vitestExit = 0
$goLog = Join-Path $TestDir "backend-go-test.log"
$vitestLog = Join-Path $TestDir "frontend-vitest.log"
$goTmp = Join-Path $RepoRoot '.gotmp'
New-Item -ItemType Directory -Path $goTmp -Force | Out-Null
$env:GOTMPDIR = $goTmp

function Invoke-CmdLogged {
  param(
    [Parameter(Mandatory = $true)][string]$Command,
    [Parameter(Mandatory = $true)][string]$LogPath,
    [Parameter(Mandatory = $true)][string]$WorkDir
  )
  $outFile = Join-Path $goTmp ("cmd-" + [guid]::NewGuid().ToString() + ".txt")
  Push-Location $WorkDir
  cmd.exe /c "$Command > `"$outFile`" 2>&1"
  $script:LastCmdExit = [int]$LASTEXITCODE
  Pop-Location
  if (Test-Path $outFile) {
    $lines = @(Get-Content -Path $outFile -ErrorAction SilentlyContinue)
    foreach ($line in $lines) {
      Add-Content -Path $LogPath -Value $line -Encoding utf8 | Out-Null
      Write-Host $line
    }
  }
}

Add-Content -Path $goLog -Value $sep -Encoding utf8
if ((Test-Path "backend/go.mod")) {
  Write-Host '[backend] go test -tags http2legacy -p 1 ./...'
  # http2legacy: golang.org/x/net 0.54+ hides http2.TrailerPrefix used by grpc.
  # 不使用 -coverprofile：本机 WDAC 会拦截 covdata.exe/cover.exe。
  # GOTMPDIR 放到仓库内；-p 1 降低并行编译 OOM。
  # cmd.exe 重定向保留 go 真实退出码（PowerShell 2>&1 管道会污染 LASTEXITCODE）。
  $backendDir = Join-Path $RepoRoot 'backend'
  Invoke-CmdLogged -Command 'go test -v -p 1 -tags http2legacy ./...' -LogPath $goLog -WorkDir $backendDir
  $goExit = $script:LastCmdExit
  if ($goExit -ne 0) {
    $logRaw = Get-Content $goLog -Raw -ErrorAction SilentlyContinue
    $sepIdx = if ($null -ne $logRaw) { $logRaw.LastIndexOf('>>>>>>>>>> TEST RUN @') } else { -1 }
    $chunk = if ($sepIdx -ge 0) { $logRaw.Substring($sepIdx) } else { $logRaw }
    $retryPkgs = New-Object System.Collections.Generic.List[string]
    if ($null -ne $chunk) {
      $lines = $chunk -split "`n"
      for ($i = 0; $i -lt $lines.Count - 1; $i++) {
        if ($lines[$i] -match 'Application Control' -and $lines[$i + 1] -match 'FAIL\tairsky/(\S+)') {
          $retryPkgs.Add($Matches[1])
        }
      }
    }
    if ($retryPkgs.Count -gt 0) {
      Write-Host "[backend] retry WDAC-blocked packages: $($retryPkgs -join ', ')"
      Add-Content -Path $goLog -Value '>>>>>>>>>> RETRY WDAC-BLOCKED PACKAGES <<<<<<<<<<' -Encoding utf8
      $retryFail = $false
      foreach ($pkg in $retryPkgs) {
        $rel = './' + ($pkg -replace '\\', '/')
        Write-Host "[backend] retry $rel"
        Invoke-CmdLogged -Command "go test -v -p 1 -tags http2legacy $rel" -LogPath $goLog -WorkDir $backendDir
        if ($script:LastCmdExit -ne 0) { $retryFail = $true }
      }
      if (-not $retryFail) { $goExit = 0 }
    }
  }
} else {
  Add-Content -Path $goLog -Value "backend/ skipped" -Encoding utf8
}

Add-Content -Path $vitestLog -Value $sep -Encoding utf8
if (Test-Path "frontend/package.json") {
  $pkg = Get-Content "frontend/package.json" -Raw | ConvertFrom-Json
  $hasVitest = $false
  if ($null -ne $pkg.devDependencies) {
    $hasVitest = $pkg.devDependencies.PSObject.Properties.Name -contains 'vitest'
  }
  if (-not $hasVitest -and $null -ne $pkg.dependencies) {
    $hasVitest = $pkg.dependencies.PSObject.Properties.Name -contains 'vitest'
  }
  if ($hasVitest) {
    Write-Host '[frontend] vitest run'
    $frontendDir = Join-Path $RepoRoot 'frontend'
    Invoke-CmdLogged -Command 'npx vitest run --coverage --dangerouslyIgnoreUnhandledErrors' -LogPath $vitestLog -WorkDir $frontendDir
    $vitestExit = $script:LastCmdExit
  } else {
    Add-Content -Path $vitestLog -Value "frontend/ skipped (vitest not configured)" -Encoding utf8
    Write-Host '[frontend] skip (no vitest)'
  }
} else {
  Add-Content -Path $vitestLog -Value "frontend/ skipped" -Encoding utf8
}

Write-Host ""
Write-Host '[parse] parse-test-results ...'
if (Get-Command node -ErrorAction SilentlyContinue) {
  & node "$ScriptDir/parse-test-results.js" $PlanDir
}

$overall = 0
if ($goExit -ne 0 -or $vitestExit -ne 0) { $overall = 1 }
if ($overall -eq 0) { Write-Output "TESTS: pass" } else { Write-Output "TESTS: fail" }
exit $overall
