#Requires -Version 5.1
<#
.SYNOPSIS
  在指定 Git 仓库中执行 git add + git commit（仅此两项写操作）。

.DESCRIPTION
  供 git-commit-planner Skill 阶段 5 调用。使用 UTF-8（无 BOM）临时文件写入
  commit message，避免 PowerShell 中文编码导致 commit 失败。

.PARAMETER RepoPath
  Git 仓库根目录（绝对或相对路径）。

.PARAMETER Files
  待 add 的文件列表。可为：
  - 字符串数组：-Files a.go,b.go 或 -Files @('a.go','b.go')
  - 单个逗号分隔字符串：-Files "a.go,b.go"

.PARAMETER CommitMsg
  Commit message（与提交计划中的文案完全一致）。

.EXAMPLE
  .\git_add_commit.ps1 "D:\proj\backend" "pkg/a.go,pkg/b.go" "fix: 修复时长解析"

.EXAMPLE
  .\git_add_commit.ps1 -RepoPath "D:\proj\backend" -Files @("pkg/a.go","pkg/b.go") -CommitMsg "fix: 修复时长解析"

.OUTPUTS
  成功时 stdout 含：
    RESULT: OK
    COMMIT: <short_hash> <subject>
  失败时非零退出码，stderr/stdout 含 RESULT: FAIL 与原因。
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$RepoPath,

    [Parameter(Mandatory = $true, Position = 1)]
    [string[]]$Files,

    [Parameter(Mandatory = $true, Position = 2)]
    [string]$CommitMsg
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Fail([string]$Reason) {
    Write-Host "RESULT: FAIL"
    Write-Host "REASON: $Reason"
    exit 1
}

function Normalize-FileList([string[]]$Raw) {
    $list = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $Raw) {
        if ([string]::IsNullOrWhiteSpace($item)) { continue }
        foreach ($part in ($item -split ",")) {
            $p = $part.Trim().Trim('"').Trim("'")
            if (-not [string]::IsNullOrWhiteSpace($p)) {
                $list.Add($p)
            }
        }
    }
    return , $list.ToArray()
}

# ─── 参数规范化 ───
$resolved = Resolve-Path -LiteralPath $RepoPath -ErrorAction SilentlyContinue
if (-not $resolved) {
    Write-Fail "RepoPath 不存在或无法解析"
}
$RepoPath = $resolved.Path

$fileList = Normalize-FileList $Files
if ($fileList.Count -eq 0) {
    Write-Fail "Files 为空，至少需要一个待提交文件"
}

$CommitMsg = $CommitMsg.Trim()
if ([string]::IsNullOrWhiteSpace($CommitMsg)) {
    Write-Fail "CommitMsg 为空"
}

# 去掉计划文档可能包在两侧的反引号
if ($CommitMsg.Length -ge 2 -and [int][char]$CommitMsg[0] -eq 96 -and [int][char]$CommitMsg[$CommitMsg.Length - 1] -eq 96) {
    $CommitMsg = $CommitMsg.Substring(1, $CommitMsg.Length - 2)
}

# ─── 仓库校验 ───
$gitDir = & git -C $RepoPath rev-parse --git-dir 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail "路径不是 Git 仓库: $RepoPath ($gitDir)"
}

Write-Host "REPO: $RepoPath"
Write-Host "FILES ($($fileList.Count)):"
foreach ($f in $fileList) { Write-Host "  - $f" }
Write-Host "MSG: $CommitMsg"

# ─── 暂存区预检 ───
$stagedRaw = & git -C $RepoPath diff --cached --name-only 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail "无法读取暂存区: $stagedRaw"
}
$staged = @($stagedRaw | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() -replace '\\', '/' })
$planned = @($fileList | ForEach-Object { $_.Trim() -replace '\\', '/' })

$skipAdd = $false
if ($staged.Count -gt 0) {
    $stagedSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$staged, [StringComparer]::Ordinal)
    $plannedSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$planned, [StringComparer]::Ordinal)
    $unexpected = @($staged | Where-Object { -not $plannedSet.Contains($_) })
    $missing = @($planned | Where-Object { -not $stagedSet.Contains($_) })

    if ($unexpected.Count -gt 0) {
        Write-Host "UNEXPECTED_STAGED:"
        foreach ($u in $unexpected) { Write-Host "  - $u" }
        Write-Fail "暂存区存在不属于本次 Commit 的文件，已中止（不自动 reset）"
    }
    if ($missing.Count -eq 0) {
        Write-Host "STAGED_MATCH: skip git add"
        $skipAdd = $true
    }
    else {
        Write-Fail "暂存区与计划文件不完全一致（缺少: $($missing -join ', ')），已中止"
    }
}

# ─── git add ───
if (-not $skipAdd) {
    & git -C $RepoPath add -- @fileList
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "git add 失败 (exit=$LASTEXITCODE)"
    }
}

$stagedAfter = @(& git -C $RepoPath diff --cached --name-only | Where-Object { $_ })
if ($stagedAfter.Count -eq 0) {
    Write-Fail "暂存区为空，无法 commit（请确认文件路径相对于仓库根目录且存在变更）"
}

# ─── git commit（UTF-8 无 BOM 临时文件）───
$msgFile = Join-Path $RepoPath ".git\COMMIT_MSG_TEMP"
try {
    if (Test-Path -LiteralPath $msgFile) {
        Remove-Item -LiteralPath $msgFile -Force
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($msgFile, $CommitMsg + "`n", $utf8NoBom)

    & git -C $RepoPath commit -F $msgFile
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "git commit 失败 (exit=$LASTEXITCODE)"
    }
}
finally {
    if (Test-Path -LiteralPath $msgFile) {
        Remove-Item -LiteralPath $msgFile -Force -ErrorAction SilentlyContinue
    }
}

$head = & git -C $RepoPath log -1 --oneline
Write-Host "RESULT: OK"
Write-Host "COMMIT: $head"
Write-Host "STAGED_FILES: $($stagedAfter.Count)"
exit 0
