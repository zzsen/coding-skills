# =============================================================================
# worktree-create.ps1 — 创建隔离 worktree（PowerShell）
# =============================================================================
# 【功能】从源分支（默认当前分支）创建功能/修复隔离 worktree 并登记，
#         等价于 .sh 版 worktree-create.sh。
# 【调用阶段】Phase 2 确认后、Phase 3 前（源分支须由 Agent 先与用户确认）。
# 【输入】-ChangeName <name>（必填） -Kind feature|fix（必填）
#         -BaseBranch <branch>（可选，默认当前分支） -WorktreesRoot <dir>（可选）
#         -Repo <path>（可选，显式指定 git 仓库根，多仓库场景用）
# 【输出】stdout：WORKTREE_CREATED 行 + RESULT: OK；失败 exit 非 0。
# 【用法】& <skill_root>/scripts/worktree-create.ps1 -ChangeName user-management -Kind feature -BaseBranch main
# =============================================================================
param(
  [Parameter(Mandatory = $true)]
  [string]$ChangeName,
  [Parameter(Mandatory = $true)]
  [ValidateSet('feature', 'fix')]
  [string]$Kind,
  [string]$BaseBranch = '',
  [string]$WorktreesRoot = '',
  [string]$Repo = ''
)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole
. (Join-Path $PSScriptRoot '_agent-lib.ps1')
. (Join-Path $PSScriptRoot '_worktree-lib.ps1')

if (-not $WorktreesRoot) { $WorktreesRoot = Get-DlcWtRoot }

if ($Repo) {
  $gitRoot = Get-DlcWtRepoRoot -Target $Repo
  if (-not $gitRoot) { Write-Error "RESULT: FAIL（-Repo 不是 git 仓库: $Repo）"; exit 1 }
} else {
  $gitRoot = Get-DlcWtGitRoot
  if (-not $gitRoot) { Write-Error "RESULT: FAIL（当前目录不是 git 仓库）"; exit 1 }
}

if (-not $BaseBranch) {
  $BaseBranch = Get-DlcWtCurrentBranch
  if (-not $BaseBranch) { Write-Error "RESULT: FAIL（无法确定当前分支）"; exit 1 }
}

$branch = Get-DlcWtBranch -Kind $Kind -ChangeName $ChangeName
$wtRel = Join-Path $WorktreesRoot $branch
$wtPath = Join-Path $gitRoot $wtRel

& git -C $gitRoot show-ref --verify --quiet "refs/heads/$branch"
if ($LASTEXITCODE -eq 0) { Write-Error "RESULT: FAIL（分支 $branch 已存在）"; exit 1 }
if (Test-Path -LiteralPath $wtPath) { Write-Error "RESULT: FAIL（路径 $wtPath 已存在）"; exit 1 }

& git -C $gitRoot worktree add -b $branch $wtPath $BaseBranch
if ($LASTEXITCODE -ne 0) { Write-Error "RESULT: FAIL（worktree add 失败，exit=${LASTEXITCODE}）"; exit $LASTEXITCODE }

$baseCommit = (& git -C $gitRoot rev-parse --short $BaseBranch).Trim()

$reg = Get-DlcWtRegistry -GitRoot $gitRoot
$regDir = Split-Path $reg -Parent
if ($regDir -and -not (Test-Path -LiteralPath $regDir)) {
  New-Item -ItemType Directory -Path $regDir -Force | Out-Null
}
$createdAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$row = (@($ChangeName, $Kind, $branch, $wtRel, $BaseBranch, $baseCommit, $createdAt, 'active', $gitRoot) -join "`t")
[System.IO.File]::AppendAllText($reg, ($row + "`n"), $script:Utf8NoBom)

Write-Output "WORKTREE_CREATED: branch=$branch path=$wtPath base=$BaseBranch base_commit=$baseCommit"
Write-Output "RESULT: OK"
