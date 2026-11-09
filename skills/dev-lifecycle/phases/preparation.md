# 前置准备：环境检查与补全

> [SKILL.md](../SKILL.md) §1.1 **步骤 1 之后** Read 本文件。
> **禁止**在 Shell `preflight` 之前 Read 本项目内任何文件。

---

## 一、执行顺序（固定，Shell 优先）

```
步骤 1  Shell preflight（本会话第一个工具调用）
    → 步骤 2  Read preparation.md + 00-pre-flight-check-report.md
    → 步骤 3  首个回复输出门禁报告（§1 引用 Shell 输出）
    → 环境 ❌：仅环境 AskUserQuestion（#1a / #1b / #2）→ 停止，禁止 Phase
    → 环境 ✅：Read exploration.md → 进入 §二场景判定 / Phase 1
```

| 步 | 名称 | 完成标志 |
|----|------|----------|
| **1** | Shell preflight | `openspec-cli-installed`、`openspec-list-ok`、`openspec-ready`、路径 True/False（含 `openspec/`）；缺 `openspec/` 时 ensure-openspec 已尝试 init |
| **2** | Read 规则与报告模板 | preparation + 00-pre-flight 已读 |
| **3** | 门禁报告 | 首个回复已输出，§1 非猜测 |
| **4** | 环境 AskUserQuestion（若有 ❌） | 仅 #1a → #1b → #2，**不得**混入 Phase 提问 |
| **5** | exploration.md | **仅**门禁「可以」后读取 |

**未完成步骤 1** → 禁止输出门禁 §1、禁止 Glob/Grep 仓库、禁止写产物、禁止 Phase AskUserQuestion。

---

## 二、禁止项

| 类别 | 禁止 |
|------|------|
| **Skill** | **Read / 调用 Superpowers `brainstorming`**（dev-lifecycle 优先；「制定开发计划」走 Phase 1→2，不是 brainstorming） |
| **顺序** | Shell 之前 Read 项目文件、`validate-project-config`、`safe-list-files` |
| **本步骤扫描** | Glob 扫描项目仓库（`Glob **/*`、`backend/**` 等） |
| **手写替代** | OpenSpec / Superpowers 未就绪时手写等价产物「凑合」；不调用 explore/propose/apply/archive、writing-plans、executing-plans | 见 [mandatory-tooling.md](../reference/mandatory-tooling.md) |
| **自编命令** | Agent 手写或自编 `opsx-*.md`；命令仅由官方 `openspec init` / `openspec update` 生成 |
| **AskUserQuestion** | 环境 AskUserQuestion 与 Phase AskUserQuestion 同批提问；合并 OpenSpec + Superpowers；环境 ❌ 时问 Phase 续航 |
| **插件代装** | Agent 代替用户安装 Cursor Superpowers 插件（仅可创建 `plans/` 目录并给出官方步骤） |

---

## 三、步骤 1：环境定点检查（首个 Shell）

> §1 环境检查表的 ✅/❌ **必须**来自脚本输出，**禁止凭猜测填写**。

在项目根目录执行（**推荐 preflight**，含 Rules 恢复）：

```powershell
& <skill_root>/scripts/preflight.ps1
# 或 JSON：& <skill_root>/scripts/preflight.ps1 -Json
```

```bash
bash <skill_root>/scripts/preflight.sh
```

单独检查（不含 Rules 恢复）：

```powershell
& <skill_root>/scripts/check-env.ps1
```

```bash
bash <skill_root>/scripts/check-env.sh
```

脚本说明：[scripts/README.md](../scripts/README.md)

### OpenSpec 两项检查（脚本汇总行）

| 检查项 | Shell 键 | 就绪条件 |
|--------|----------|----------|
| **a. CLI 全局安装** | `openspec-cli-installed` | `True`；`openspec-cli` 有版本号（非 `not found`） |
| **b. 项目可用** | `openspec-list-ok` | `True`：`openspec list` 退出码 0 |
| **c. 项目目录** | 路径 `openspec` | `True`：项目根存在 `openspec/`（缺失时 preflight **ensure-openspec** 自动 `openspec init --tools <agent-slug>`） |
| **汇总** | `openspec-ready` | a **且** b **且** c 均为 `True` |

### 其他判定摘要

| 检查项 | 就绪条件 |
|--------|----------|
| **agent** | Shell：`agent: <claude-code\|cursor\|codex>`（探测不准时用 `--agent=<id>` / `DEVLC_AGENT` 覆盖） |
| **规则（可选项）** | Shell：`rules-kind` + `rules-ok` —— **信息项，不参与门禁**。`mdc`（Cursor）由 restore-rules 自动补；`memory-file`（Claude Code `CLAUDE.md` / Codex `AGENTS.md`）仅提示 |
| **Superpowers writing-plans** | Shell：`writing-plans:` 有命中路径 |
| **Superpowers executing-plans** | Shell：`executing-plans:` 有命中路径 |
| **Superpowers 汇总** | Shell：`superpowers_ready: True`（两个 Skill 均命中） |
| **门禁汇总** | Shell：`environment-ready: True`（**= OpenSpec ∧ Superpowers**，规则不计入） |
| **Skill 实际可用** | 新会话后 Agent 可用 Skill 列表含 `writing-plans`（会话级，脚本不检测） |

---

## 四、规则与 OpenSpec 目录自动补全（preflight 内含）

> **硬性规则**：
>
> - **规则（Cursor `.mdc`）** 缺失项 **自动从 reference 复制**，**不询问用户**，**不覆盖**已存在文件。
>   Claude Code / Codex 下 restore-rules **只打印提示**，不写 `CLAUDE.md` / `AGENTS.md`（用户自有文件，不得代改）。
> - **`openspec/` 目录**缺失且 CLI 已装时，**自动**执行 `openspec init --tools <agent-slug>` + `openspec update`，**不询问用户**。
> - **Superpowers 不自动安装** —— 仅在环境检查输出中打印 `npx skills add ...` 命令，
>   由 AskUserQuestion #2 让用户选择「代为执行 / 手动执行 / 暂停」。

preflight 顺序：`check-env` → `restore-rules` → `ensure-openspec` → `check-env`。

单独恢复 Rules：

```powershell
& <skill_root>/scripts/restore-rules.ps1
```

```bash
bash <skill_root>/scripts/restore-rules.sh
```

单独补全 OpenSpec 目录：

```powershell
& <skill_root>/scripts/ensure-openspec.ps1
```

```bash
bash <skill_root>/scripts/ensure-openspec.sh
```

门禁报告 §1 注明 Rules：`✅ 已存在` 或 `✅ 已从 reference 自动恢复`；OpenSpec 目录：`✅ 已存在` 或 `✅ 已由 ensure-openspec 自动 init`。

---

## 五、环境不合规 — 逐项 AskUserQuestion（**仅环境，禁止与 Phase 混搭**）

### 5.1 询问顺序

```
门禁报告含 ❌
    │
    ├─ openspec-cli-installed: False？ ──→ AskUserQuestion #1a（仅 CLI 安装）→ 处理 → 重跑 preflight
    │
    ├─ CLI 已就绪 &（openspec-list-ok: False 或 openspec/ 仍缺失）？ ──→ AskUserQuestion #1b（init / list 失败）→ 处理 → 重跑 preflight
    │     （注：openspec/ 缺失时 preflight 已自动 ensure-openspec；仅自动 init 失败才问 #1b）
    │
    ├─ OpenSpec 已就绪 & Superpowers 未就绪？ ──→ AskUserQuestion #2（仅 Superpowers）→ 处理 → 重跑 preflight
    │
    └─ 全部 ✅（`environment-ready: True`）→ 门禁「可以」→ Read exploration.md → **方允许**进入 Phase 1
```

**环境 ❌ 时回复末尾只允许环境 AskUserQuestion**，禁止附带「开始 Phase 1」「制定方案」「结束会话」等 Phase 续航选项。

### 5.2 AskUserQuestion #1a：OpenSpec CLI 未全局安装

**触发**：`openspec-cli-installed: False`

```
问题："检测到 OpenSpec CLI 未全局安装（openspec 命令不可用），请选择处理方式："
选项：
  - 🤖 由 Agent 代为执行 npm install -g @fission-ai/openspec@latest
  - 📋 查看官方手动安装步骤，我自行操作
  - ⏸️ 暂停，待环境补全后再继续
```

| 用户选择 | Agent 行为 |
|----------|-----------|
| 🤖 代为安装 | 执行 `npm install -g @fission-ai/openspec@latest`；若仅缺 CLI 则重跑 preflight |
| 📋 手动安装 | 输出 [§六 CLI 安装](#六openspec-安装)；**等待用户确认**后重跑 preflight |
| ⏸️ 暂停 | **停止流程**；门禁保持「不可以」 |

### 5.3 AskUserQuestion #1b：OpenSpec 项目未就绪（list 失败或目录仍缺失）

**触发**：`openspec-cli-installed: True`，且（`openspec-list-ok: False` **或** 路径 `openspec` 仍为 False）。  
> 正常情况：缺 `openspec/` 已由 preflight `ensure-openspec` 自动 init；本问仅在自动 init 失败、或目录在但 `openspec list` 仍失败时触发。

```
问题："检测到 OpenSpec CLI 已安装，但项目 OpenSpec 仍未就绪（openspec/ 缺失或 openspec list 失败），请选择处理方式："
选项：
  - 🤖 由 Agent 在项目根执行 openspec init --tools <agent-slug>
  - 📋 查看官方手动 init 步骤，我自行操作
  - ⏸️ 暂停，待环境补全后再继续
```

| 用户选择 | Agent 行为 |
|----------|-----------|
| 🤖 代为 init | 执行 `ensure-openspec.ps1`（或 `openspec init --tools <agent-slug>` + `openspec update`） |
| 📋 手动 init | 输出 [§六 项目 init](#六openspec-安装)；**等待用户确认**后重跑 preflight |
| ⏸️ 暂停 | **停止流程** |

> 若 CLI 与项目 init **同时**缺失：先 #1a，CLI 就绪后再 #1b；**不得**一次 AskUserQuestion 覆盖两项。

### 5.4 AskUserQuestion #2：Superpowers 未就绪

**触发**（`openspec-ready: True` 后，满足**任一**条）：

- `superpowers_ready: False`（`writing-plans` / `executing-plans` 未齐）
- 可用 Skill 列表无 `writing-plans`（新会话后复检）

```
问题："检测到 Superpowers TDD 环境未就绪（writing-plans / executing-plans Skill 缺失），请选择处理方式："
选项：
  - 🤖 由 Agent 代为执行 npx skills add obra/superpowers
  - 📋 查看安装命令，我自行操作
  - ⏸️ 暂停，待环境补全后再继续
```

| 用户选择 | Agent 行为 |
|----------|-----------|
| 🤖 代为安装 | 执行 `bash <skill_root>/scripts/enable-superpowers.sh --run`（PowerShell：`enable-superpowers.ps1 -Run`）→ 重跑 preflight |
| 📋 手动安装 | 输出 [§七 Superpowers 安装](#七superpowers-安装)；**等待用户确认**后重跑 preflight |
| ⏸️ 暂停 | **停止流程**；**禁止** Phase 1~7 |

> **跨 agent 说明**：Superpowers 本质是一组 SKILL.md，`skills` CLI 可装到 claude-code / cursor / codex 任一目标，
> 命令中的 `-a <agent>` 由脚本按探测结果自动填充。

> **硬性**：Superpowers 任一项 ❌ → `environment-ready: False` → **禁止进入 Phase 1**（不是「仅阻塞 Phase 2」）。须补全并重跑 preflight 直至 `environment-ready: True`。

---

## 六、OpenSpec 安装

> **权威来源**：
>
> - [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec)
> - [Getting Started](https://github.com/Fission-AI/OpenSpec/blob/main/docs/getting-started.md)
> - [Supported Tools](https://github.com/Fission-AI/OpenSpec/blob/main/docs/supported-tools.md)

**前置**：Node.js **20.19.0+**。

### a. CLI 全局安装

```bash
npm install -g @fission-ai/openspec@latest
openspec --version
```

### b. 项目 init（须在项目根）

```bash
cd <项目根目录>
openspec init --tools <agent-slug>
openspec update
```

**`<agent-slug>` 取值**（由 preflight 自动解析并传入，手动执行时按下表填）

| agent | slug | 生成物落点 |
|-------|------|-----------|
| claude-code | `claude` | `.claude/commands/opsx-*.md`、`.claude/skills/openspec-*/` |
| cursor | `cursor` | `.cursor/commands/opsx-*.md`、`.cursor/skills/openspec-*/` |
| codex | `codex` | `.agents/skills/openspec-*/`（Codex 无 slash command） |
| 其他 / 未知 | `agents` | `.agents/skills/`（vendor-neutral，多数 agent 可读） |

> `openspec init --tools` 还支持 `amp`、`gemini`、`opencode`、`kilocode`、`roocode`、`trae`、
> `qwen`、`iflow`、`zed`、`copilot-cloud`、`windsurf`，以及 `all` / `none`。
> 权威列表以 `openspec init --help` 为准。

若 `openspec init` 需交互且无法在非 TTY 完成 → 改输出手动路径，请用户本地执行后回复「已 init」。

### 验证（安装后必须）

1. `openspec-cli-installed: True`
2. `openspec-list-ok: True`
3. `openspec-ready: True`
4. Claude Code / Cursor：聊天输入 `/opsx` 有自动补全（需重载窗口）；Codex：确认 `<agent-skills-dir>/openspec-*/SKILL.md` 存在
5. **重跑 preflight**

---

## 七、Superpowers 安装

> **权威来源**：
>
> - [obra/superpowers](https://github.com/obra/superpowers)
> - [skills CLI — 支持的 agent 与安装路径](https://github.com/vercel-labs/skills/blob/main/docs/agents.md)

**通用安装（任一 agent）**：Superpowers 本质是一组 SKILL.md，用 `skills` CLI 装即可。

```bash
# <agent> = claude-code | cursor | codex；-g 装到全局，去掉则装到当前项目
npx skills add obra/superpowers --skill writing-plans --skill executing-plans -a <agent> -g
mkdir -p docs/superpowers/plans
```

**各 agent 的安装落点**

| agent | 全局路径 | 项目路径 |
|-------|----------|----------|
| claude-code | `~/.claude/skills/` | `.claude/skills/` |
| cursor | `~/.cursor/skills/` | `.agents/skills/` |
| codex | `~/.agents/skills/` | `.agents/skills/` |

**Cursor 插件方式（可选，向后兼容）**：Cursor 用户也可继续用插件市场的 `/add-plugin superpowers`，
检测脚本保留了对 `~/.cursor/plugins/cache/cursor-public/superpowers` 的回落识别。

**检测 / 代为安装脚本**（项目根）：

```bash
bash <skill_root>/scripts/check-superpowers.sh
bash <skill_root>/scripts/enable-superpowers.sh          # 仅打印命令
bash <skill_root>/scripts/enable-superpowers.sh --run    # 代为执行
```

```powershell
& <skill_root>/scripts/check-superpowers.ps1
& <skill_root>/scripts/enable-superpowers.ps1 -Run
New-Item -ItemType Directory -Force -Path docs/superpowers/plans
```

**验证**：`superpowers_ready: True` 且 `environment-ready: True`；新会话后 Skill 列表含 `writing-plans`；**重跑 preflight**。

---

## 八、就绪声明与速查

### 8.1 全部就绪后在回复中声明

```
🔧 环境检查：
  - Agent：claude-code / cursor / codex（引用 preflight 首行）
  - 常驻规则：✅ / ⚠️ 缺失 / ➖ 该 agent 无等价机制（**信息项，不影响门禁**）
  - OpenSpec CLI：✅ 全局已安装
  - OpenSpec 项目：✅ 已 init（--tools <agent-slug>）
  - Superpowers：writing-plans ✅ | executing-plans ✅（须 `superpowers_ready: True`）
  - 门禁汇总：✅ `environment-ready` / ❌ 不可以
  - 写文件许可：✅ 仅当 `environment-ready: True`
```

任一项未就绪且用户选择暂停 → 门禁 **⛔ 不可以**，直至补全并重跑 preflight。

### 8.2 检查项速查

**OpenSpec 就绪**（脚本判定，全部满足）：

| 检查项 | 路径 / 条件 |
|--------|-------------|
| CLI 全局 | `openspec-cli-installed: True` |
| 项目目录 | 路径 `openspec` 为 True（preflight `ensure-openspec` 可自动 init） |
| 项目可用 | `openspec-list-ok: True`（`openspec list` 成功） |
| 汇总 | `openspec-ready: True` |

> 工作流规范（Cursor `.cursor/rules/01|02|03-*.mdc`）为 **agent 可选项**，`rules-ok` 不参与门禁。

**Superpowers 环境就绪**（脚本判定，全部满足）：

| 检查项 | 路径 / 条件 |
|--------|-------------|
| writing-plans | `writing-plans:` 有命中路径 |
| executing-plans | `executing-plans:` 有命中路径 |
| 汇总 | `superpowers_ready: True` |
| Skill 实际可用 | 新会话后 Agent 可用 Skill 列表含 `writing-plans` |

**验证**：`environment-ready: True`；**重跑 preflight**。
