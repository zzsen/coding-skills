# =============================================================================
# check-env.ps1 — 环境定点检查（PowerShell，多 agent：claude-code / cursor / codex）
# =============================================================================
# 【功能】检查 dev-lifecycle 前置环境：agent 识别、OpenSpec（CLI + list + 目录）、
#         Superpowers（writing-plans / executing-plans）、Rules（可选项）、project-config；
#         供门禁报告 §1 引用，禁止 Agent 凭猜测填写 ✅/❌。
# 【调用阶段】前置首个命令（preflight 内嵌调用 / 单独 check-env）；
#             须在任何项目 Read、文件搜索之前执行。
# 【输入】
#   -Json          可选，输出 JSON 对象（供自动化解析）
#   -Agent <id>    可选，覆盖自动探测（claude-code | cursor | codex）
#   须在项目根目录执行（相对路径基于 cwd）
# 【输出】
#   stdout：agent、固定路径 True/False、openspec-cli-installed、openspec-list-ok、
#           openspec-ready、superpowers_installed / _enabled / _ready、
#           rules-kind / rules-ok、environment-ready、openspec-cli 版本
#   exit 0：脚本正常结束（不表示环境全部就绪，须 Agent 解读 True/False）
# 【流程】
#   1. 初始化控制台编码（_init-ps.ps1）
#   2. 遍历固定路径列表，逐行输出 True/False
#   3. 检测 openspec CLI 是否全局安装（Get-Command openspec），并读取版本号
#   4. CLI 已装时执行 openspec list；退出码 0 → openspec-list-ok: True
#   5. 汇总 openspec-ready = cli-installed ∧ list-ok ∧ openspec/ 目录存在
#      （openspec/ 缺失由 preflight ensure-openspec 自动 init，不扫 changes/specs）
#   6. 按 agent 在 skills 目录查找 writing-plans / executing-plans
#   7. 汇总 superpowers_ready = 两个 Skill 均命中
#   8. 汇总 environment-ready = openspec-ready ∧ superpowers_ready
#   9. 按 -Json 输出结构化 JSON 或人类可读文本
# 【门禁口径变更】Rules 已从硬门禁降级为 agent 可选项：rules-ok 仅作信息项输出，
#   **不参与** environment-ready 计算（Cursor 以外的 agent 无等价强制机制）。
# 【用法】& <skill_root>/scripts/check-env.ps1 [-Json] [-Agent cursor]
# =============================================================================
param([switch]$Json, [string]$Agent)

# 步骤 1：初始化控制台
. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole
. (Join-Path $PSScriptRoot '_superpowers-lib.ps1')   # 内部已 dot-source _agent-lib.ps1

$ErrorActionPreference = "Continue"

if (-not $Agent) { $Agent = Get-DlcAgent }
$skillRoot    = Get-DlcSkillRoot
$openspecTool = Get-DlcOpenspecTool -Agent $Agent
$rulesKind    = Get-DlcRulesKind -Agent $Agent

# 步骤 2：固定路径列表（Rules / openspec 根目录 / project-config；不扫 openspec 子树）
$paths = @(
  "openspec",
  (Get-DlcProjectConfigPath)
)

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 步骤 3：OpenSpec CLI 检测（多安装方式：PATH / nvm / volta / fnm / npm-global）
$openspecBin = Resolve-DlcOpenspec
$cliInstalled = $null -ne $openspecBin
if ($cliInstalled) {
  $openspecCli = (openspec --version 2>&1 | Out-String).Trim()
} else {
  $openspecCli = "not found"
}

# 步骤 4：openspec list 检测（CLI 未装时跳过，list-ok 保持 False）
$openspecListOk = $false
if ($cliInstalled) {
  & openspec list 2>&1 | Out-Null
  $openspecListOk = ($LASTEXITCODE -eq 0)
}

# 步骤 5：OpenSpec 汇总（须含项目根 openspec/ 目录）
$openspecDirOk = Test-Path -LiteralPath 'openspec' -PathType Container
$openspecReady = $cliInstalled -and $openspecListOk -and $openspecDirOk

# 步骤 6：Superpowers 插件安装与 settings 启用
$spStatus = Get-SuperpowersStatus -Agent $Agent
$superpowersInstalled = $spStatus.Installed
$superpowersEnabled   = $spStatus.Enabled

# 步骤 7：Superpowers 汇总
$superpowersReady = $spStatus.Ready

# 步骤 8：门禁汇总
# Rules 已降级为信息项，不参与 environment-ready
$rulesTargets = Get-DlcRulesTargets -Agent $Agent
if ($rulesKind -eq 'none') {
  $rulesOk = 'na'
} else {
  $missing = @($rulesTargets | Where-Object { -not (Test-Path -LiteralPath $_) })
  $rulesOk = if ($missing.Count -eq 0) { 'true' } else { 'false' }
}
$environmentReady = $openspecReady -and $superpowersReady

# 步骤 9：JSON 输出
if ($Json) {
  $pathObj = @{}
  foreach ($p in $paths) { $pathObj[$p] = Test-Path $p }
  [PSCustomObject]@{
    checked_at            = $ts
    agent                 = $Agent
    skill_root            = $skillRoot
    openspec_tool         = $openspecTool
    paths                 = $pathObj
    openspec_cli_installed = $cliInstalled
    openspec_list_ok      = $openspecListOk
    openspec_ready        = $openspecReady
    superpowers_installed = $superpowersInstalled
    superpowers_enabled   = $superpowersEnabled
    superpowers_ready     = $superpowersReady
    writing_plans_path    = $spStatus.WritingPlans
    executing_plans_path  = $spStatus.ExecutingPlans
    rules_kind            = $rulesKind
    rules_ok              = $rulesOk
    environment_ready     = $environmentReady
    openspec_cli          = $openspecCli
  } | ConvertTo-Json -Depth 4
  exit 0
}

# 步骤 9：文本输出
Write-Host "=== dev-lifecycle 环境定点检查 ==="
Write-Host $ts
"agent:`t$Agent ($(Get-DlcAgentLabel -Agent $Agent))"
"skill-root:`t$skillRoot"
"openspec-tool:`t$openspecTool"
foreach ($p in $paths) {
  "{0}`t{1}" -f $p, (Test-Path $p)
}
"openspec-cli-installed:`t$cliInstalled"
"openspec-list-ok:`t$openspecListOk"
"openspec-ready:`t$openspecReady"
"superpowers_installed:`t$superpowersInstalled"
"superpowers_enabled:`t$superpowersEnabled"
"superpowers_ready:`t$superpowersReady"
if ($spStatus.WritingPlans)   { "writing-plans:`t$($spStatus.WritingPlans)" }
if ($spStatus.ExecutingPlans) { "executing-plans:`t$($spStatus.ExecutingPlans)" }
"rules-kind:`t$rulesKind"
"rules-ok:`t$rulesOk (信息项，不参与门禁)"
if ($rulesTargets.Count -gt 0) { "rules-targets:`t$($rulesTargets -join ' ')" }
"environment-ready:`t$environmentReady"
"openspec-cli:`t$openspecCli"

# 未就绪时输出安装提示（运行时引导，不自动执行）
if (-not $environmentReady) {
  ""
  "=== 环境未就绪，安装提示 ==="
  if (-not $cliInstalled) { "  OpenSpec CLI: npm install -g @fission-ai/openspec@latest" }
  if ($cliInstalled -and (-not $openspecListOk -or -not $openspecDirOk)) {
    "  OpenSpec 项目: openspec init --tools $openspecTool"
  }
  if (-not $superpowersReady) { "  Superpowers: $(Get-SuperpowersInstallHint -Agent $Agent)" }
}
exit 0
