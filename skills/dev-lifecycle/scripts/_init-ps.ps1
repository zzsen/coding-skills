# =============================================================================
# _init-ps.ps1 — PowerShell 脚本公共初始化（由各 .ps1 dot-source）
# =============================================================================
# 【功能】在 Windows PowerShell 5.x 下将控制台输出设为 UTF-8，避免中文/emoji 乱码。
# 【用法】在 param 块之后：. (Join-Path $PSScriptRoot '_init-ps.ps1'); Initialize-DevLifecycleConsole
# =============================================================================

function Initialize-DevLifecycleConsole {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        return
    }
    try {
        $utf8 = [System.Text.UTF8Encoding]::new($false)
        [Console]::OutputEncoding = $utf8
        $global:OutputEncoding = $utf8
        if ($IsWindows -or $env:OS -match 'Windows') {
            $null = & cmd.exe /c chcp 65001 >$null 2>&1
        }
    } catch {
        # 忽略：无法改代码页时仍继续执行
    }
}
