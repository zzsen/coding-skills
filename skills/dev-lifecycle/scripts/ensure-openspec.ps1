# =============================================================================
# ensure-openspec.ps1 — 项目根缺少 openspec/ 时自动 init（PowerShell）
# =============================================================================
# 【功能】若项目根不存在 openspec/ 目录，且 openspec CLI 可用，则执行
#         openspec init --tools <按 agent 解析>（及 openspec update）；已存在则跳过。
# 【调用阶段】前置 preparation；preflight 在 restore-rules 之后调用。
# 【输入】-DryRun 可选，只打印将执行的动作
# 【输出】stdout：OpenSpec init: ... / already present / CLI missing；exit 0（缺 CLI 时 exit 1）
# 【流程】
#   1. 检测 openspec/ 是否存在
#   2. 不存在则检测 CLI（Get-Command openspec）
#   3. 执行 openspec init --tools <slug>，再 openspec update
# 【用法】& <skill_root>/scripts/ensure-openspec.ps1 [-DryRun]
# =============================================================================
param([switch]$DryRun, [string]$Agent)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole
. (Join-Path $PSScriptRoot '_agent-lib.ps1')

if (-not $Agent) { $Agent = Get-DlcAgent }
$tool = Get-DlcOpenspecTool -Agent $Agent

$openspecDir = 'openspec'

if (Test-Path -LiteralPath $openspecDir -PathType Container) {
  Write-Output 'OpenSpec: openspec/ already present'
  exit 0
}

$cli = Get-Command openspec -ErrorAction SilentlyContinue
if ($null -eq $cli) {
  Write-Output 'RESULT: OPENSPEC_CLI_MISSING'
  Write-Output 'HINT: Install with npm install -g @fission-ai/openspec@latest'
  exit 1
}

if ($DryRun) {
  Write-Output "[dry-run] would run: openspec init --tools $tool"
  Write-Output '[dry-run] would run: openspec update'
  exit 0
}

Write-Output "OpenSpec: openspec/ missing — running openspec init --tools $tool (agent=$Agent)"
& openspec init --tools $tool
if ($LASTEXITCODE -ne 0) {
  Write-Output "RESULT: INIT_FAILED (exit $LASTEXITCODE)"
  exit $LASTEXITCODE
}

Write-Output 'OpenSpec: running openspec update'
& openspec update
if ($LASTEXITCODE -ne 0) {
  Write-Output "RESULT: UPDATE_FAILED (exit $LASTEXITCODE)"
  exit $LASTEXITCODE
}

if (-not (Test-Path -LiteralPath $openspecDir -PathType Container)) {
  Write-Output 'RESULT: INIT_OK_BUT_OPENSPEC_DIR_MISSING'
  exit 1
}

Write-Output 'OpenSpec: initialized (openspec/ created)'
exit 0
