# =============================================================================
# check-superpowers.ps1 — 检测 Superpowers（writing-plans / executing-plans）可用性
# =============================================================================
# 【功能】按当前 agent（claude-code / cursor / codex）在其 skills 目录中查找
#         writing-plans 与 executing-plans 两个 Skill。
# 【调用阶段】前置 preparation；亦被 check-env 调用。
# 【输入】-Json 可选；-Agent <id> 可选（覆盖自动探测）
# 【输出】agent、superpowers-plugin-installed / -enabled / superpowers-ready、
#         两个 Skill 的命中路径、未就绪时的安装命令提示；exit 0
# 【用法】& <skill_root>/scripts/check-superpowers.ps1 [-Json] [-Agent cursor]
# =============================================================================
param(
    [switch]$Json,
    [string]$Agent
)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole
. (Join-Path $PSScriptRoot '_superpowers-lib.ps1')

if (-not $Agent) { $Agent = Get-DlcAgent }
$st = Get-SuperpowersStatus -Agent $Agent

if ($Json) {
    [PSCustomObject]@{
        agent                        = $Agent
        superpowers_plugin_installed = $st.Installed
        superpowers_plugin_enabled   = $st.Enabled
        superpowers_ready            = $st.Ready
        writing_plans_path           = $(if ($st.WritingPlans)   { $st.WritingPlans }   else { '' })
        executing_plans_path         = $(if ($st.ExecutingPlans) { $st.ExecutingPlans } else { '' })
    } | ConvertTo-Json -Depth 3
    exit 0
}

"agent:`t$Agent ($(Get-DlcAgentLabel -Agent $Agent))"
"superpowers-plugin-installed:`t$($st.Installed)"
"superpowers-plugin-enabled:`t$($st.Enabled)"
"superpowers-ready:`t$($st.Ready)"
if ($st.WritingPlans)   { "writing-plans:`t$($st.WritingPlans)" }
if ($st.ExecutingPlans) { "executing-plans:`t$($st.ExecutingPlans)" }
if (-not $st.Ready) {
    "HINT: 安装 Superpowers（writing-plans / executing-plans）："
    "  $(Get-SuperpowersInstallHint -Agent $Agent)"
}
exit 0
