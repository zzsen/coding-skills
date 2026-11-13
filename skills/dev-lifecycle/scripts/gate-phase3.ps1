# =============================================================================
# gate-phase3.ps1 — Phase 3 硬门禁（worktree 隔离决策，PowerShell）
# =============================================================================
# 【功能】进入 Phase 3 前校验 worktree 隔离状态：
#         非 git 项目 → 放行（单工作树，按 change 目录隔离）；
#         git 项目且该 change 已有 active worktree → 放行并输出 worktree 上下文；
#         git 项目但无 active worktree → block，由 Agent AskUserQuestion 确认
#         是否使用 worktree 及源分支（默认当前分支），确认后再 worktree-create。
# 【调用阶段】Phase 3 入口（phase3.md §〇），首个脚本。
# 【输入】-ChangeName <name>（必需，kebab-case）
# 【输出】GATE_PHASE3: pass|block + worktree: true|false + 上下文
#   exit 0：pass；exit 1：block（git 且无 active worktree）
# 【用法】& <skill_root>/scripts/gate-phase3.ps1 -ChangeName user-management
# =============================================================================
param([string]$ChangeName)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole
. (Join-Path $PSScriptRoot '_agent-lib.ps1')
. (Join-Path $PSScriptRoot '_worktree-lib.ps1')

$ErrorActionPreference = "Continue"

if (-not $ChangeName) {
  Write-Output '错误: 需要 -ChangeName'
  exit 2
}

# 非 git 项目 → 放行（单工作树，按 change 目录隔离）
$gitRoot = Get-DlcWtGitRoot
if (-not $gitRoot) {
  Write-Output 'GATE_PHASE3: pass'
  Write-Output 'worktree: false'
  Write-Output 'reason: 非 git 项目（单工作树，按 change 目录隔离）'
  exit 0
}

$reg = Get-DlcWtRegistry
$row = $null
if (Test-Path -LiteralPath $reg -PathType Leaf) {
  foreach ($line in (Get-Content -LiteralPath $reg -Encoding UTF8)) {
    $c = $line -split "`t"
    if ($c.Count -ge 8 -and $c[0] -eq $ChangeName -and $c[7] -eq 'active') {
      $row = $c
      break
    }
  }
}

if ($row) {
  $branch = $row[2]
  $path   = $row[3]
  $base   = $row[4]
  if (Test-Path -LiteralPath (Join-Path $gitRoot $path) -PathType Container) {
    Write-Output 'GATE_PHASE3: pass'
    Write-Output 'worktree: true'
    Write-Output "target_branch: $branch"
    Write-Output "base_branch: $base"
    Write-Output "worktree_path: $(Join-Path $gitRoot $path)"
    exit 0
  }
  Write-Output 'GATE_PHASE3: block'
  Write-Output 'worktree: false'
  Write-Output 'reason: 登记表有 active 记录但 worktree 路径缺失（状态不一致，请 worktree remove 后重建）'
  exit 1
}

Write-Output 'GATE_PHASE3: block'
Write-Output 'worktree: false'
Write-Output 'reason: 该 change 无 active worktree'
Write-Output 'action: 由 Agent AskUserQuestion 确认是否使用 worktree 及源分支（默认当前分支），确认后 worktree-create'
exit 1
