#
# =============================================================================
# run-lint.ps1 — Phase 5 Lint 检测与报告生成（PowerShell）
# =============================================================================
# 【功能】执行 backend/frontend 四项 Lint/构建检测，追加日志，解析并生成 5.lint-report.md。
# 【调用阶段】Phase 5（phase5.md）。
# 【输入】-PlanDir（必填）；脚本会自动切到仓库根目录
# 【输出】
#   lint-results/*.log、lint-counts.json、5.lint-report.md
#   stdout：执行进度与总体结果
# 【流程】
#   1. 创建 lint-results/，写入批次分隔符
#   2. golangci-lint → eslint → vue-tsc -b → npm run build
#   3. 调用 parse-lint-results（node/go/python 自动选择）
#   4. 生成 5.lint-report.md
# 【用法】& <skill_root>/scripts/run-lint.ps1 -PlanDir <plan-dir>
# =============================================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$PlanDir
)

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
if (-not (Test-Path $PlanDir)) {
    Write-Error "错误: 目录 $PlanDir 不存在"
    exit 1
}
$PlanDir = (Resolve-Path $PlanDir).Path

$LintDir = Join-Path $PlanDir "lint-results"
New-Item -ItemType Directory -Path $LintDir -Force | Out-Null

$ReportFile = Join-Path $PlanDir "5.lint-report.md"
$GolintLog = Join-Path $LintDir "golangci-lint.log"
$EslintLog = Join-Path $LintDir "eslint.log"
$VuetscLog = Join-Path $LintDir "vue-tsc.log"
$BuildLog = Join-Path $LintDir "build.log"

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$runSeparator = '>>>>>>>>>> LINT RUN @ ' + $timestamp + ' <<<<<<<<<<'

$golintExit = 0
$eslintExit = 0
$vuetscExit = 0
$buildExit = 0

function Append-LintLog {
    param([string]$LogFile, [string]$Line)
    # 始终用绝对 LiteralPath，避免 "../d:\..." 被 PS 误解析
    Add-Content -LiteralPath $LogFile -Value $Line -Encoding utf8
}

function Count-Runs {
    param([string]$LogFile)
    if (Test-Path $LogFile) {
        $content = Get-Content -LiteralPath $LogFile -ErrorAction SilentlyContinue
        if ($content) {
            return ($content | Where-Object { $_ -match "^>>>>>>>>>> LINT RUN @" }).Count
        }
    }
    return 0
}

function Extract-LastRun {
    param([string]$LogFile)
    if (-not (Test-Path $LogFile)) { return "" }
    $lines = Get-Content -LiteralPath $LogFile -ErrorAction SilentlyContinue
    if (-not $lines) { return "" }

    $lastSepIdx = -1
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i] -match "^>>>>>>>>>> LINT RUN @") {
            $lastSepIdx = $i
            break
        }
    }

    if ($lastSepIdx -ge 0 -and $lastSepIdx -lt $lines.Count - 1) {
        return ($lines[($lastSepIdx + 1)..($lines.Count - 1)] | Out-String).TrimEnd()
    }
    return ""
}

$totalRun = (Count-Runs $GolintLog) + 1

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Lint 检测开始（第 $totalRun 次运行）" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. golangci-lint ──────────────────────────
Write-Host "[1/4] 运行 golangci-lint (backend/) ..." -ForegroundColor Yellow
Append-LintLog -LogFile $GolintLog -Line $runSeparator
if (Test-Path "backend") {
    Push-Location "backend"
    $golintCmd = Get-Command golangci-lint -ErrorAction SilentlyContinue
    if ($golintCmd) {
        & golangci-lint run ./... 2>&1 | ForEach-Object {
            Write-Host $_
            Append-LintLog -LogFile $GolintLog -Line "$_"
        }
        $golintExit = $LASTEXITCODE
    }
    else {
        $goVetCmd = Get-Command go -ErrorAction SilentlyContinue
        if ($goVetCmd) {
            $msg = "golangci-lint 未安装，使用 go vet -tags http2legacy"
            Write-Host $msg
            Append-LintLog -LogFile $GolintLog -Line $msg
            & go vet -tags http2legacy ./... 2>&1 | ForEach-Object {
                Write-Host $_
                Append-LintLog -LogFile $GolintLog -Line "$_"
            }
            $golintExit = $LASTEXITCODE
        }
        else {
            $msg = "golangci-lint 和 go 均未安装，跳过"
            Write-Host $msg
            Append-LintLog -LogFile $GolintLog -Line $msg
        }
    }
    Pop-Location
}
else {
    $msg = "backend/ 目录不存在，跳过"
    Write-Host $msg
    Append-LintLog -LogFile $GolintLog -Line $msg
}
Write-Host ""

# ── 2. ESLint ─────────────────────────────────
Write-Host "[2/4] 运行 ESLint (frontend/) ..." -ForegroundColor Yellow
Append-LintLog -LogFile $EslintLog -Line $runSeparator
if (Test-Path "frontend") {
    Push-Location "frontend"
    & npx eslint . 2>&1 | ForEach-Object {
        Write-Host $_
        Append-LintLog -LogFile $EslintLog -Line "$_"
    }
    $eslintExit = $LASTEXITCODE
    Pop-Location
}
else {
    $msg = "frontend/ 目录不存在，跳过"
    Write-Host $msg
    Append-LintLog -LogFile $EslintLog -Line $msg
}
Write-Host ""

# ── 3. vue-tsc ────────────────────────────────
Write-Host "[3/4] 运行 vue-tsc (frontend/) ..." -ForegroundColor Yellow
Append-LintLog -LogFile $VuetscLog -Line $runSeparator
if (Test-Path "frontend") {
    Push-Location "frontend"
    & npx vue-tsc -b --noEmit 2>&1 | ForEach-Object {
        Write-Host $_
        Append-LintLog -LogFile $VuetscLog -Line "$_"
    }
    $vuetscExit = $LASTEXITCODE
    Pop-Location
}
else {
    $msg = "frontend/ 目录不存在，跳过"
    Write-Host $msg
    Append-LintLog -LogFile $VuetscLog -Line $msg
}
Write-Host ""

# ── 4. npm run build ──────────────────────────
Write-Host "[4/4] 运行 npm run build (frontend/) ..." -ForegroundColor Yellow
Append-LintLog -LogFile $BuildLog -Line $runSeparator
if (Test-Path "frontend") {
    Push-Location "frontend"
    & npm run build 2>&1 | ForEach-Object {
        Write-Host $_
        Append-LintLog -LogFile $BuildLog -Line "$_"
    }
    $buildExit = $LASTEXITCODE
    Pop-Location
}
else {
    $msg = "frontend/ 目录不存在，跳过"
    Write-Host $msg
    Append-LintLog -LogFile $BuildLog -Line $msg
}
Write-Host ""

# ── 调用解析脚本提取错误数量 ──────────────────
Write-Host "[解析] 调用 parse-lint-results 提取错误数量 ..." -ForegroundColor Yellow

$GOLINT_ERRORS = -1; $GOLINT_WARNINGS = 0; $GOLINT_RUNS = 0
$ESLINT_ERRORS = -1; $ESLINT_WARNINGS = 0; $ESLINT_RUNS = 0
$VUETSC_ERRORS = -1; $VUETSC_RUNS = 0
$BUILD_ERRORS = -1; $BUILD_RUNS = 0
$TOTAL_ERRORS = -1; $PASSED = $false
$parseOk = $false

function Parse-OutputLine {
    param([string]$Line)
    if ($Line -match "^(\w+)=(.+)$") {
        $key = $Matches[1]
        $val = $Matches[2]
        switch ($key) {
            "GOLINT_ERRORS"   { $script:GOLINT_ERRORS = [int]$val }
            "GOLINT_WARNINGS" { $script:GOLINT_WARNINGS = [int]$val }
            "GOLINT_RUNS"     { $script:GOLINT_RUNS = [int]$val }
            "ESLINT_ERRORS"   { $script:ESLINT_ERRORS = [int]$val }
            "ESLINT_WARNINGS" { $script:ESLINT_WARNINGS = [int]$val }
            "ESLINT_RUNS"     { $script:ESLINT_RUNS = [int]$val }
            "VUETSC_ERRORS"   { $script:VUETSC_ERRORS = [int]$val }
            "VUETSC_RUNS"     { $script:VUETSC_RUNS = [int]$val }
            "BUILD_ERRORS"    { $script:BUILD_ERRORS = [int]$val }
            "BUILD_RUNS"      { $script:BUILD_RUNS = [int]$val }
            "TOTAL_ERRORS"    { $script:TOTAL_ERRORS = [int]$val }
            "PASSED"          { $script:PASSED = ($val -eq "true") }
        }
    }
}

$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
$goCmd = Get-Command go -ErrorAction SilentlyContinue
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
$python3Cmd = Get-Command python3 -ErrorAction SilentlyContinue

if ($nodeCmd) {
    Write-Host "  使用 Node.js 解析 ..."
    try {
        $output = & node "$ScriptDir/parse-lint-results.js" $PlanDir 2>&1
        $output | ForEach-Object { Parse-OutputLine $_ }
        $parseOk = $true
    } catch {}
}
elseif ($goCmd) {
    Write-Host "  使用 Go 解析 ..."
    try {
        $output = & go run "$ScriptDir/parse-lint-results.go" $PlanDir 2>&1
        $output | ForEach-Object { Parse-OutputLine $_ }
        $parseOk = $true
    } catch {}
}
elseif ($python3Cmd) {
    Write-Host "  使用 Python3 解析 ..."
    try {
        $output = & python3 "$ScriptDir/parse-lint-results.py" $PlanDir 2>&1
        $output | ForEach-Object { Parse-OutputLine $_ }
        $parseOk = $true
    } catch {}
}
elseif ($pythonCmd) {
    Write-Host "  使用 Python 解析 ..."
    try {
        $output = & python "$ScriptDir/parse-lint-results.py" $PlanDir 2>&1
        $output | ForEach-Object { Parse-OutputLine $_ }
        $parseOk = $true
    } catch {}
}

if ($parseOk) {
    Write-Host "  解析完成 → lint-counts.json 已生成"
}
else {
    Write-Host "  ⚠️ 解析脚本未成功运行，使用退出码作为降级判断" -ForegroundColor Red
    if ($golintExit -ne 0) { $GOLINT_ERRORS = 1 } else { $GOLINT_ERRORS = 0 }
    if ($eslintExit -ne 0) { $ESLINT_ERRORS = 1 } else { $ESLINT_ERRORS = 0 }
    if ($vuetscExit -ne 0) { $VUETSC_ERRORS = 1 } else { $VUETSC_ERRORS = 0 }
    if ($buildExit -ne 0) { $BUILD_ERRORS = 1 } else { $BUILD_ERRORS = 0 }
    $TOTAL_ERRORS = [Math]::Max(0, $GOLINT_ERRORS) + [Math]::Max(0, $ESLINT_ERRORS) + [Math]::Max(0, $VUETSC_ERRORS) + [Math]::Max(0, $BUILD_ERRORS)
    $PASSED = ($TOTAL_ERRORS -eq 0 -and $golintExit -eq 0 -and $eslintExit -eq 0 -and $vuetscExit -eq 0 -and $buildExit -eq 0)
    $GOLINT_RUNS = Count-Runs $GolintLog
    $ESLINT_RUNS = Count-Runs $EslintLog
    $VUETSC_RUNS = Count-Runs $VuetscLog
    $BUILD_RUNS = Count-Runs $BuildLog
}

# 退出码兜底：解析认为 0 但工具失败时仍判失败
if ($golintExit -ne 0 -and $GOLINT_ERRORS -eq 0) { $GOLINT_ERRORS = 1; $PASSED = $false }
if ($eslintExit -ne 0 -and $ESLINT_ERRORS -eq 0) { $ESLINT_ERRORS = 1; $PASSED = $false }
if ($vuetscExit -ne 0 -and $VUETSC_ERRORS -eq 0) { $VUETSC_ERRORS = 1; $PASSED = $false }
if ($buildExit -ne 0 -and $BUILD_ERRORS -eq 0) { $BUILD_ERRORS = 1; $PASSED = $false }
if (-not $PASSED -and $TOTAL_ERRORS -le 0) {
    $TOTAL_ERRORS = 0
    foreach ($n in @($GOLINT_ERRORS, $ESLINT_ERRORS, $VUETSC_ERRORS, $BUILD_ERRORS)) {
        if ($n -gt 0) { $TOTAL_ERRORS += $n }
    }
}
Write-Host ""

# ── 生成汇总报告 ──────────────────────────────

function Get-StatusIcon($errors) {
    if ($errors -eq -1) { "⚠️ 未执行" }
    elseif ($errors -eq 0) { "✅ 通过" }
    else { "❌ 未通过" }
}

$golintStatus = Get-StatusIcon $GOLINT_ERRORS
$eslintStatus = Get-StatusIcon $ESLINT_ERRORS
$vuetscStatus = Get-StatusIcon $VUETSC_ERRORS
$buildStatus = Get-StatusIcon $BUILD_ERRORS

if ($PASSED) {
    $overallStatus = "✅ 全部通过"
} elseif ($TOTAL_ERRORS -eq -1) {
    $overallStatus = "⚠️ 存在未执行的检测项"
} else {
    $overallStatus = "❌ 存在未通过项（共 $TOTAL_ERRORS 个错误）"
}

$lastGolint = Extract-LastRun $GolintLog
$lastEslint = Extract-LastRun $EslintLog
$lastVuetsc = Extract-LastRun $VuetscLog
$lastBuild = Extract-LastRun $BuildLog

$golintDetail = if ($GOLINT_ERRORS -eq -1) { "日志文件不存在，未执行 golangci-lint" } elseif ($GOLINT_ERRORS -gt 0 -and $lastGolint) { $lastGolint } else { "无错误" }
$eslintDetail = if ($ESLINT_ERRORS -eq -1) { "日志文件不存在，未执行 ESLint" } elseif ($ESLINT_ERRORS -gt 0 -and $lastEslint) { $lastEslint } else { "无错误" }
$vuetscDetail = if ($VUETSC_ERRORS -eq -1) { "日志文件不存在，未执行 vue-tsc" } elseif ($VUETSC_ERRORS -gt 0 -and $lastVuetsc) { $lastVuetsc } else { "无错误" }
$buildDetail = if ($BUILD_ERRORS -eq -1) { "日志文件不存在，未执行 npm run build" } elseif ($BUILD_ERRORS -gt 0 -and $lastBuild) { $lastBuild } else { "无错误" }

$fixSuggestions = @()
if ($GOLINT_ERRORS -ne 0) { $fixSuggestions += "- [ ] 修复 golangci-lint 报告的 $GOLINT_ERRORS 个错误" }
if ($ESLINT_ERRORS -ne 0) { $fixSuggestions += "- [ ] 修复 ESLint 报告的 $ESLINT_ERRORS 个错误" }
if ($VUETSC_ERRORS -ne 0) { $fixSuggestions += "- [ ] 修复 vue-tsc 报告的 $VUETSC_ERRORS 个类型错误" }
if ($BUILD_ERRORS -ne 0) { $fixSuggestions += "- [ ] 修复 npm run build 报告的 $BUILD_ERRORS 个构建错误" }
if ($fixSuggestions.Count -eq 0) { $fixSuggestions += "无需修复，全部通过。" }
$fixText = $fixSuggestions -join "`n"

$createdTime = $timestamp
if (Test-Path $ReportFile) {
    $existingLine = Get-Content -LiteralPath $ReportFile -Encoding UTF8 | Where-Object { $_ -match '^> 生成时间：' } | Select-Object -First 1
    if ($existingLine -match '^> 生成时间：(.+)$') {
        $createdTime = $Matches[1]
    }
}

$report = @"
# Lint 检测汇总报告

> 生成时间：$createdTime
> 最后更新：$timestamp
> 计划目录：$PlanDir
> 本次为第 $totalRun 次运行
> 错误数量来源：parse-lint-results 脚本正则提取（lint-counts.json）

## 总体结果：$overallStatus

## 检测明细

| 检测项 | 状态 | 错误数 | 警告数 | 退出码 | 累计运行次数 | 日志文件 |
|--------|------|--------|--------|--------|-------------|----------|
| golangci-lint (后端) | $golintStatus | $GOLINT_ERRORS | $GOLINT_WARNINGS | $golintExit | $GOLINT_RUNS | lint-results/golangci-lint.log |
| ESLint (前端) | $eslintStatus | $ESLINT_ERRORS | $ESLINT_WARNINGS | $eslintExit | $ESLINT_RUNS | lint-results/eslint.log |
| vue-tsc (前端类型检查) | $vuetscStatus | $VUETSC_ERRORS | 0 | $vuetscExit | $VUETSC_RUNS | lint-results/vue-tsc.log |
| npm run build (前端构建) | $buildStatus | $BUILD_ERRORS | 0 | $buildExit | $BUILD_RUNS | lint-results/build.log |

## 错误详情（仅最后一次运行）

### golangci-lint

``````
$golintDetail
``````

### ESLint

``````
$eslintDetail
``````

### vue-tsc

``````
$vuetscDetail
``````

### npm run build

``````
$buildDetail
``````

## 修复建议

$fixText
"@

$report | Set-Content -LiteralPath $ReportFile -Encoding UTF8

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Lint 检测完成（第 $totalRun 次运行）" -ForegroundColor Cyan
Write-Host "  总体结果：$overallStatus" -ForegroundColor $(if ($PASSED) { "Green" } else { "Red" })
Write-Host "  汇总报告：$ReportFile" -ForegroundColor Cyan
Write-Host "  错误统计：$LintDir\lint-counts.json" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

if (-not $PASSED) {
    exit 1
}
exit 0
