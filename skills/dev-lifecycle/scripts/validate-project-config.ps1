# =============================================================================
# validate-project-config.ps1 — 校验 project-config.md（PowerShell）
# =============================================================================
# 【功能】按 templates/project-config.md 末尾有效性校验表机器判定配置是否可进入 Propose。
# 【调用阶段】Phase 1 前；SKILL §2.1。
# 【输入】-Path 可选（默认 .dev-lifecycle/project-config.md，回落 <skill_root>/project-config.md）
# 【输出】stdout：逐项 ✅/❌ + RESULT: valid|invalid；exit 0/1
# 【流程】
#   1. 检查文件存在
#   2. 扫描 {{ 占位符
#   3. 对比 go.mod module、package.json name
#   4. 检查 §7 探索约定
# 【用法】& <skill_root>/scripts/validate-project-config.ps1 [-Path <file>]
# =============================================================================
param([string]$Path = (Get-DlcProjectConfigPath))

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole
. (Join-Path $PSScriptRoot '_agent-lib.ps1')

$fail = 0
function Check($msg) { Write-Output $msg }

if (-not (Test-Path $Path)) {
  Write-Output "❌ 文件不存在: $Path"
  exit 1
}

$content = Get-Content $Path -Raw -Encoding UTF8
if ($content -match '\{\{') {
  Check "❌ 存在未替换占位符 {{"
  $fail = 1
} else {
  Check "✅ 无 {{ 占位符"
}

if (Test-Path "backend/go.mod") {
  $mod = (Select-String -Path "backend/go.mod" -Pattern '^module\s+(\S+)' | ForEach-Object { $_.Matches.Groups[1].Value })
  if ($mod -and $content -match [regex]::Escape($mod)) {
    Check "✅ go.mod module 一致: $mod"
  } else {
    Check "❌ go.mod module 不一致（期望含: $mod）"
    $fail = 1
  }
} else {
  Check "⚠️ 跳过 go.mod"
}

if (Test-Path "frontend/package.json") {
  $pkg = Get-Content "frontend/package.json" -Raw | ConvertFrom-Json
  if ($pkg.name -and $content -match [regex]::Escape($pkg.name)) {
    Check "✅ package.json name 一致: $($pkg.name)"
  } elseif ($pkg.name) {
    Check "❌ package.json name 不一致（期望含: $($pkg.name)）"
    $fail = 1
  }
} else {
  Check "⚠️ 跳过 package.json"
}

if ($content -match '## 7\. 探索约定' -and $content -match '\|.*前端探索范围.*\|') {
  Check "✅ §7 探索约定已填写"
} else {
  Check "❌ §7 探索约定未填写"
  $fail = 1
}

if ($content -match '\| 仓库类型 \|[^\r\n]*(single|multi|none)') {
  Check "✅ 仓库类型已填写（single/multi/none）"
} else {
  Check "❌ 仓库类型未填写或非法（须 single / multi / none）"
  $fail = 1
}

if ($fail -eq 0) { "RESULT: valid" } else { "RESULT: invalid" }
exit $fail
