# =============================================================================
# worktree-merge-back.ps1 — 交付：rebase → merge 回源分支 → 清理 worktree
# =============================================================================
# 【功能】Phase 7 完成 archive + 验收通过后：rebase → merge 回源分支 → 移除 worktree
#         → 更新登记表 status=merged。等价于 .sh 版 worktree-merge-back.sh。
#         **冲突一律停下交用户，不自动 resolve。**
# 【调用阶段】Phase 7 完成 /opsx:archive 与验收之后。
# 【输入】-ChangeName <name>（必填） -Kind feature|fix（必填）
#         -BaseBranch <branch>（可选） -KeepBranch（可选） -Ff（fast-forward，默认 --no-ff）
#         -NoRebase（可选） -DryRun（可选）
# 【输出】stdout：每步 STEP/RESULT；exit 0 成功，非 0 失败。
# 【用法】& <skill_root>/scripts/worktree-merge-back.ps1 -ChangeName user-management -Kind feature
# =============================================================================
param(
  [Parameter(Mandatory = $true)]
  [string]$ChangeName,
  [Parameter(Mandatory = $true)]
  [ValidateSet('feature', 'fix')]
  [string]$Kind,
  [string]$BaseBranch = '',
  [switch]$KeepBranch,
  [switch]$Ff,
  [switch]$NoRebase,
  [switch]$DryRun
)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole
. (Join-Path $PSScriptRoot '_agent-lib.ps1')
. (Join-Path $PSScriptRoot '_worktree-lib.ps1')

$gitRoot = Get-DlcWtGitRoot
if (-not $gitRoot) { Write-Error "RESULT: FAIL（当前目录不是 git 仓库）"; exit 1 }

$branch = Get-DlcWtBranch -Kind $Kind -ChangeName $ChangeName
$wtPath = Join-Path $gitRoot (Get-DlcWtPath -Branch $branch)

$registry = Get-DlcWtRegistry
if (-not $BaseBranch -and (Test-Path -LiteralPath $registry -PathType Leaf)) {
  foreach ($ln in (Get-Content -LiteralPath $registry)) {
    $f = $ln -split "`t"
    if ($f.Count -ge 8 -and $f[2] -eq $branch) { $BaseBranch = $f[4]; break }
  }
}
if (-not $BaseBranch) {
  $BaseBranch = Get-DlcWtCurrentBranch
  if (-not $BaseBranch) { Write-Error "RESULT: FAIL（无法确定源分支，请用 -BaseBranch 指定）"; exit 1 }
}

Write-Output "STEP 定位: branch=$branch worktree=$wtPath base=$BaseBranch"

# worktree 存在性
$found = $false
foreach ($ln in (& git -C $gitRoot worktree list --porcelain)) {
  if ($ln -eq "worktree $wtPath") { $found = $true; break }
}
if (-not $found) { Write-Error "RESULT: FAIL（worktree 不存在: $wtPath）"; exit 1 }

$wtCur = Get-DlcWtCurrentBranch
# worktree 内当前分支
$wtCurWt = (& git -C $wtPath branch --show-current 2>$null).Trim()
if ($wtCurWt -ne $branch) { Write-Error "RESULT: FAIL（worktree 当前分支 $wtCurWt 与 $branch 不符）"; exit 1 }

if (& git -C $wtPath status --porcelain) {
  Write-Error "RESULT: FAIL（worktree 有未提交改动，先 git-commit-planner 提交后再交付）"; exit 1
}
$mainCur = (& git -C $gitRoot branch --show-current 2>$null).Trim()
if ($mainCur -ne $BaseBranch) {
  Write-Error "RESULT: FAIL（主工作树当前在 ${mainCur}，须切到源分支 ${BaseBranch} 再交付）"; exit 1
}
if (& git -C $gitRoot status --porcelain) {
  Write-Error "RESULT: FAIL（主工作树有未提交改动，先处理干净再交付）"; exit 1
}

if ($DryRun) {
  Write-Output "DRY_RUN: 将执行 — rebase=$(-not $NoRebase) → merge(--no-ff=$(-not $Ff)) → worktree remove → branch delete=$(-not $KeepBranch)"
  Write-Output "RESULT: DRY_RUN_OK"
  exit 0
}

# rebase
if (-not $NoRebase) {
  Write-Output "STEP rebase: $branch onto $BaseBranch"
  & git -C $wtPath rebase $BaseBranch
  if ($LASTEXITCODE -ne 0) {
    Write-Error "RESULT: FAIL（rebase 冲突或失败，exit=${LASTEXITCODE}；请在 $wtPath 内解决冲突后重跑本脚本）"
    exit $LASTEXITCODE
  }
  Write-Output "STEP rebase: 完成"
} else {
  Write-Output "STEP rebase: 跳过（-NoRebase）"
}

# merge
$mergeArgs = @('merge')
if (-not $Ff) { $mergeArgs += '--no-ff' }
$mergeArgs += $branch
Write-Output "STEP merge: $($mergeArgs -join ' ')"
& git -C $gitRoot @mergeArgs
if ($LASTEXITCODE -ne 0) {
  Write-Error "RESULT: FAIL（merge 冲突，exit=${LASTEXITCODE}；请在主工作树解决冲突后完成合并，再重跑本脚本）"
  exit $LASTEXITCODE
}
Write-Output "STEP merge: 完成"

# worktree remove
Write-Output "STEP worktree remove: $wtPath"
& git -C $gitRoot worktree remove $wtPath
if ($LASTEXITCODE -ne 0) {
  Write-Error "RESULT: FAIL（worktree remove 失败，exit=${LASTEXITCODE}）"
  exit $LASTEXITCODE
}
Write-Output "STEP worktree remove: 完成"

# branch delete
if (-not $KeepBranch) {
  Write-Output "STEP branch delete: $branch"
  & git -C $gitRoot branch -d $branch
  if ($LASTEXITCODE -ne 0) {
    Write-Output "WARN: 分支 $branch 未能安全删除（exit=${LASTEXITCODE}），请手动确认"
  } else {
    Write-Output "STEP branch delete: 完成"
  }
}

# 更新登记表
if (Test-Path -LiteralPath $registry -PathType Leaf) {
  if (Set-DlcWtRegistryStatus -Branch $branch -Status 'merged') {
    Write-Output "STEP 登记表: status=merged"
  } else {
    Write-Output "WARN: 登记表无该分支记录，跳过状态更新"
  }
}

Write-Output "RESULT: OK（$branch 已交付回 ${BaseBranch}）"
