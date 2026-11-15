﻿# =============================================================================
# gate-phase3.ps1 — Phase 3 worktree 状态查询（PowerShell）
# =============================================================================
# 【功能】查询某 change 在指定 git 仓库内是否已有 active worktree，并输出其上下文。
#         注意：**本脚本只做状态查询，不做决策**——决策由 phase3.md §〇 读 project-config
#         （detect-repos 前置记录）+ AskUserQuestion 决定。
# 【调用阶段】Phase 3：worktree-create 之后确认 / 续做（resume）定位 / 状态一致性校验。
# 【输入】-ChangeName <name>（必需）；-Repo <path>（可选，显式指定 git 仓库根）
# 【输出】GATE_PHASE3: pass|block + git/worktree + 上下文；exit 0/1
# 【用法】& <skill_root>/scripts/gate-phase3.ps1 -ChangeName user-management [-Repo /path/to/repo]
# =============================================================================
param([string]$ChangeName, [string]$Repo = '')

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole
. (Join-Path $PSScriptRoot '_agent-lib.ps1')
. (Join-Path $PSScriptRoot '_worktree-lib.ps1')

$ErrorActionPreference = "Continue"

if (-not $ChangeName) {
  Write-Output '错误: 需要 -ChangeName'
  exit 2
}

# ── 解析 git 根：-Repo → cwd → 嵌套仓库探测 ────────────────────────────────
$gitRoot = ''
if ($Repo) {
  $gitRoot = Get-DlcWtRepoRoot -Target $Repo
  if (-not $gitRoot) {
    Write-Output 'GATE_PHASE3: block'
    Write-Output 'git: false'
    Write-Output 'worktree: false'
    Write-Output "reason: -Repo 指定的路径不是 git 仓库（repo=$Repo）"
    exit 1
  }
} else {
  $gitRoot = Get-DlcWtGitRoot
  if (-not $gitRoot) {
    $repos = @(Find-DlcWtRepos)
    if ($repos.Count -eq 0) {
      Write-Output 'GATE_PHASE3: block'
      Write-Output 'git: false'
      Write-Output 'worktree: false'
      Write-Output "reason: 当前目录不是 git 仓库（cwd=$(Get-Location)），且未发现嵌套 git 仓库"
      exit 1
    }
    Write-Output 'GATE_PHASE3: block'
    Write-Output 'git: true'
    Write-Output 'nested_repos: true'
    Write-Output 'reason: cwd 不是 git 仓库，但发现子目录 git 仓库（多仓库场景）'
    foreach ($r in $repos) { Write-Output "repo: $r" }
    exit 1
  }
}

$reg = Get-DlcWtRegistry -GitRoot $gitRoot
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
    Write-Output 'git: true'
    Write-Output 'worktree: true'
    Write-Output "target_branch: $branch"
    Write-Output "base_branch: $base"
    Write-Output "worktree_path: $(Join-Path $gitRoot $path)"
    exit 0
  }
  Write-Output 'GATE_PHASE3: block'
  Write-Output 'git: true'
  Write-Output 'worktree: false'
  Write-Output 'reason: 登记表有 active 记录但 worktree 路径缺失（状态不一致，请 worktree remove 后重建）'
  exit 1
}

Write-Output 'GATE_PHASE3: block'
Write-Output 'git: true'
Write-Output 'worktree: false'
Write-Output 'reason: 该 change 无 active worktree（如需隔离，先 worktree-create）'
exit 1
