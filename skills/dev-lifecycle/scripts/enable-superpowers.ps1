# =============================================================================
# enable-superpowers.ps1 — 安装 Superpowers（writing-plans / executing-plans）
# =============================================================================
# 【变更说明】原版做的是「在 .cursor/settings.json 写 plugins.superpowers.enabled=true」，
#   这是 Cursor 插件开关特有概念。Superpowers 本身只是一组 SKILL.md，可通过 skills CLI
#   装到任意 agent，因此本脚本改为按 agent 安装对应 Skill。
# 【默认行为】只打印命令，不执行（对应 preparation AskUserQuestion #2 的「手动步骤」）。
#   加 -Run 才实际执行（对应「由 Agent 代为安装」）。
# 【输入】-Run / -Agent <id> / -Project（装到项目目录，默认全局 -g）
# 【输出】RESULT: ALREADY_READY | PRINTED | INSTALLED | ERROR
# 【用法】& <skill_root>/scripts/enable-superpowers.ps1 [-Run] [-Agent cursor] [-Project]
# =============================================================================
param(
    [switch]$Run,
    [string]$Agent,
    [switch]$Project
)

. (Join-Path $PSScriptRoot "_init-ps.ps1")
Initialize-DevLifecycleConsole
. (Join-Path $PSScriptRoot "_superpowers-lib.ps1")

if (-not $Agent) { $Agent = Get-DlcAgent }
$target = $Agent
if (-not $target -or $target -eq 'unknown') { $target = 'claude-code' }

$st = Get-SuperpowersStatus -Agent $Agent
if ($st.Ready) {
    Write-Output 'RESULT: ALREADY_READY'
    exit 0
}

$cmdArgs = @('skills', 'add', 'obra/superpowers', '--skill', 'writing-plans', '--skill', 'executing-plans', '-a', $target)
if (-not $Project) { $cmdArgs += '-g' }
$cmdText = "npx $($cmdArgs -join ' ')"

if (-not $Run) {
    Write-Output 'RESULT: PRINTED'
    Write-Output 'HINT: 请执行（或改用 -Run 让 Agent 代为执行）：'
    Write-Output "  $cmdText"
    exit 0
}

if ($null -eq (Get-Command npx -ErrorAction SilentlyContinue)) {
    Write-Output 'RESULT: ERROR'
    Write-Output 'HINT: 未找到 npx，请先安装 Node.js 22.20+'
    exit 1
}

Write-Output "Superpowers: running $cmdText"
& npx @cmdArgs
if ($LASTEXITCODE -ne 0) {
    Write-Output "RESULT: ERROR (npx exit $LASTEXITCODE)"
    exit 1
}

$st = Get-SuperpowersStatus -Agent $Agent
if ($st.Ready) {
    Write-Output 'RESULT: INSTALLED'
    exit 0
}
Write-Output 'RESULT: ERROR'
Write-Output 'HINT: 命令已执行但仍未检测到 writing-plans / executing-plans，请检查安装目标目录'
exit 1
