# =============================================================================
# check-tasks-sync.ps1 — OpenSpec tasks.md 勾选状态检查（PowerShell）
# =============================================================================
# 【功能】统计 tasks.md 未勾选项；可选对比 2.plan.md Wave 未完成行。
# 【调用阶段】Phase 3 收尾 / apply 前。
# 【输入】-ChangeName（必填）；-PlanDir 可选
# 【输出】stdout：checked/unchecked + TASKS_SYNC: pass|block；exit 0/1
# 【流程】
#   1. 定位 changes/ 或 archive/ 下 tasks.md
#   2. 统计 - [ ] 与 - [x]
#   3. 可选检查 2.plan.md Wave 未完成
# 【用法】& .../check-tasks-sync.ps1 -ChangeName <name> [-PlanDir <path>]
# =============================================================================
param(
  [Parameter(Mandatory = $true)][string]$ChangeName,
  [string]$PlanDir = ""
)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole

$tasks = "openspec/changes/$ChangeName/tasks.md"
if (-not (Test-Path $tasks)) {
  $arch = Get-ChildItem -Path "openspec/archive" -Filter "*-$ChangeName" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($arch) { $tasks = Join-Path $arch.FullName "tasks.md" }
}
if (-not (Test-Path $tasks)) { Write-Error "找不到 tasks.md"; exit 1 }

$content = Get-Content $tasks
$unchecked = ($content | Where-Object { $_ -match '^\- \[ \]' }).Count
$checked = ($content | Where-Object { $_ -match '^\- \[[xX]\]' }).Count
Write-Output "tasks.md: checked=$checked unchecked=$unchecked"

if ($PlanDir -and (Test-Path "$PlanDir/2.plan.md")) {
  $plan = Get-Content "$PlanDir/2.plan.md" -Raw
  $incomplete = ([regex]::Matches($plan, '⬜ 未开始|🔄 进行中')).Count
  Write-Output "2.plan.md: incomplete_waves=$incomplete"
}

if ($unchecked -eq 0) {
  "TASKS_SYNC: pass"
  exit 0
}
$content | Select-String -Pattern '^\- \[ \]' | ForEach-Object { $_.Line }
"TASKS_SYNC: block"
exit 1
