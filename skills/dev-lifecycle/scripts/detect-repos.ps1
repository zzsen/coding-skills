# =============================================================================
# detect-repos.ps1 — 探测项目仓库布局（PowerShell，Phase 1 前）
# =============================================================================
# 【功能】判断项目是 git 单仓库 / 多仓库 / 非 git，输出仓库类型与仓库列表，
#         供 agent 填入 project-config「仓库布局」。等价于 .sh 版 detect-repos.sh。
# 【调用阶段】exploration §四（project-config 生成时）。
# 【输入】无（在项目根目录执行）
# 【输出】REPO_TYPE: single|multi|none + repo 行（<相对路径>|<base>|<绝对路径>）；exit 0
# 【用法】& <skill_root>/scripts/detect-repos.ps1
# =============================================================================
param()

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole
. (Join-Path $PSScriptRoot '_agent-lib.ps1')
. (Join-Path $PSScriptRoot '_worktree-lib.ps1')

$ErrorActionPreference = "Continue"

$cwd = (Get-Location).Path

# 1. cwd 本身是 git 仓库
$gitRoot = Get-DlcWtGitRoot
if ($gitRoot) {
  $base = Get-DlcWtCurrentBranch
  if (-not $base) { $base = 'detached' }
  Write-Output 'REPO_TYPE: single'
  Write-Output "repo: .|$base|$gitRoot"
  exit 0
}

# 2. cwd 非 git，查嵌套仓库
$repos = @(Find-DlcWtRepos)
if ($repos.Count -eq 0) {
  Write-Output 'REPO_TYPE: none'
  exit 0
}

Write-Output 'REPO_TYPE: multi'
foreach ($r in $repos) {
  $base = (& git -C $r branch --show-current 2>$null).Trim()
  if (-not $base) { $base = 'detached' }
  $rel = $r
  if ($rel.StartsWith($cwd)) { $rel = $rel.Substring($cwd.Length).TrimStart('/', '\') }
  if (-not $rel) { $rel = '.' }
  Write-Output "repo: $rel|$base|$r"
}
exit 0
