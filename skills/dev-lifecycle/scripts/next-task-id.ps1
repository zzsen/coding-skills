# =============================================================================
# next-task-id.ps1 — 生成下一任务编号（PowerShell）
# =============================================================================
# 【功能】扫描 dev-plan 下已有 T-YYYYMMDD-N，返回当日下一个序号（禁止编造编号）。
# 【调用阶段】Phase 1~7 写入任务编号时。
# 【输入】-PlanDir 可选，限定扫描范围（默认 dev-plan）
# 【输出】stdout：T-YYYYMMDD-N；exit 0
# 【流程】
#   1. 获取当日日期
#   2. 递归扫描 .md 中 T-日期-序号
#   3. 最大序号 +1
# 【用法】& <skill_root>/scripts/next-task-id.ps1 [-PlanDir dev-plan]
# =============================================================================
param([string]$PlanDir = "dev-plan")

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole

$date = Get-Date -Format 'yyyyMMdd'
$pattern = "T-${date}-"
$searchPath = if ($PlanDir) { $PlanDir } else { "dev-plan" }
$max = 0
if (Test-Path $searchPath) {
  Get-ChildItem -Path $searchPath -Recurse -File -Include *.md -ErrorAction SilentlyContinue |
    ForEach-Object {
      [regex]::Matches((Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue), "${pattern}(\d+)") |
        ForEach-Object { $n = [int]$_.Groups[1].Value; if ($n -gt $max) { $max = $n } }
    }
}
Write-Output "${pattern}$($max + 1)"
