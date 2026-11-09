# =============================================================================
# check-wave-sync.ps1 — Wave 表一致性检查（PowerShell）
# =============================================================================
# 【功能】对比 2.plan.md 中 Wave 镜像表与 TDD 计划「Wave 汇总」是否一致。
# 【调用阶段】Phase 3 每 Wave 完成后 / Phase 7 联动更新前。
# 【输入】-PlanDir（必填）；-TddPath 可选（缺省从 2.plan.md 解析）
# 【输出】stdout：对比结果 + WAVE_SYNC: pass|block；exit 0/1
# 【流程】
#   1. 定位 TDD 计划路径
#   2. 提取两文件 Wave 表格行
#   3. 排序后比较
# 【用法】& .../check-wave-sync.ps1 -PlanDir <path> [-TddPath <file>]
# =============================================================================
param(
  [Parameter(Mandatory = $true)][string]$PlanDir,
  [string]$TddPath = ""
)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole

$planFile = Join-Path $PlanDir "2.plan.md"
if (-not (Test-Path $planFile)) { Write-Error "缺少 2.plan.md"; exit 1 }

if (-not $TddPath) {
  if ((Get-Content $planFile -Raw) -match '(docs/superpowers/plans/[^\)]+\-tdd\.md)') {
    $TddPath = $Matches[1]
  }
}
if (-not (Test-Path $TddPath)) { Write-Error "无法定位 TDD 计划: $TddPath"; exit 1 }

function Get-WaveRows($file) {
  Get-Content $file | Where-Object { $_ -match '^\|\s*Wave\s+\d+' } | ForEach-Object {
    $parts = $_ -split '\|'
    if ($parts.Count -ge 5) {
      "$($parts[1].Trim())`t$($parts[3].Trim())"
    }
  } | Sort-Object
}

$planWaves = Get-WaveRows $planFile
$tddWaves = Get-WaveRows $TddPath
$fail = 0

if (($planWaves -join "`n") -ne ($tddWaves -join "`n")) {
  Write-Output "❌ Wave 表不一致"
  Write-Output "--- 2.plan.md ---"
  $planWaves
  Write-Output "--- TDD ---"
  $tddWaves
  $fail = 1
} else {
  Write-Output "✅ Wave 表一致"
  $planWaves
}

if ($fail -eq 0) { "WAVE_SYNC: pass" } else { "WAVE_SYNC: block" }
exit $fail
