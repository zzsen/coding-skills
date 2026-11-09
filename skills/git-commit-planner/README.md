# Git Commit Planner

> Agent Skill（Claude Code / Cursor / Codex 通用）— 自动扫描 Git 仓库变更，生成结构化提交计划，逐步安全执行 `git add` / `git commit`。

## 安装

```bash
npx skills add <owner>/<repo> --skill git-commit-planner -a claude-code -g
# -a 可选 claude-code | cursor | codex；-g 装到全局，去掉则装到当前项目
```

`<skill_root>` = 安装后本 SKILL.md 所在目录：

| agent | 全局 | 项目 |
|-------|------|------|
| claude-code | `~/.claude/skills/git-commit-planner` | `.claude/skills/git-commit-planner` |
| cursor | `~/.cursor/skills/git-commit-planner` | `.agents/skills/git-commit-planner` |
| codex | `~/.agents/skills/git-commit-planner` | `.agents/skills/git-commit-planner` |


## 适用场景

- 开发了一段时间，积累了大量未提交的文件改动，需要按功能模块整理成多个有意义的 commit
- 项目包含多个独立 Git 仓库（如 `backend/`、`frontend/`、`ai-service/`），需要跨仓库协调提交顺序
- 希望在提交前先预览计划、确认文件归属和 commit message，再逐个执行

## 如何使用

### 1. 生成提交计划

在 Agent 对话中输入：

```
生成提交计划
```

或：

```
帮我整理一下代码提交
```

Agent 会自动执行以下流程：

1. **扫描仓库** — 递归发现项目目录下所有 Git 仓库（支持单仓库、多仓库、Monorepo、Submodule）
2. **分析变更** — 对每个仓库执行 `git status`、`git diff`、`git log`，按时间线和功能模块归类
3. **文件预检** — 自动检测二进制文件、大文件（>1MB）和敏感文件（`.env`、`*.key` 等），标记风险并给出建议
4. **生成计划文件** — 将提交计划写入 `commit-plan/` 目录（见 [产物说明](#流程产物)）
5. **创建待办清单** — 每个提交点一项；Claude Code 的待办不可勾选，需用户文字确认序号

### 2. 确认或调整计划

计划生成后，你可以：

- **直接勾选 Todo** 让 Agent 执行对应提交
- 要求 **调整文件归属**（把某文件从 Commit 2 移到 Commit 3）
- 要求 **修改 commit message**
- 要求 **合并或拆分** 某些提交点

### 3. 执行提交

勾选某个 Todo 或说「执行 backend Commit 1」，Agent 会：

1. 检查暂存区是否干净（防止意外提交非计划文件）
2. **调用** `scripts/git_add_commit.ps1`（Windows）或 `scripts/git_add_commit.sh`（Bash）执行 `git add` + `git commit`
3. 验证提交结果（脚本输出 `RESULT: OK` / `COMMIT: ...`）
4. 自动更新计划文件中的状态标记（⬜ → ✅）和填写提交 ID
5. 标记 Todo 为已完成

#### 执行脚本

| 参数 | 说明 | 示例 |
|------|------|------|
| 1. 执行路径 | 仓库根目录 | `D:\proj\backend` |
| 2. add 的文件 | 逗号分隔相对路径 | `pkg/a.go,pkg/b.go` |
| 3. commit-msg | 提交说明 | `fix: 修复时长解析` |

```powershell
# Windows PowerShell
& "<skill_root>\scripts\git_add_commit.ps1" `
  "D:\proj\backend" `
  "pkg/a.go,pkg/b.go" `
  "fix: 修复时长解析"
```

```bash
# Bash / Git Bash
bash "<skill_root>/scripts/git_add_commit.sh" \
  "/path/to/backend" \
  "pkg/a.go,pkg/b.go" \
  "fix: 修复时长解析"
```

脚本成功输出 `RESULT: OK` 与 `COMMIT: <hash> <subject>`；暂存区混入非计划文件时失败且不自动 reset。

### 4. 更新状态

如果你在终端手动提交了某些 Commit，可以让 Agent 刷新状态：

```
更新一下状态
```

Agent 会通过 `git log --grep --fixed-strings` 精确检查每个 Commit 是否已存在于仓库历史中，自动同步计划文件和 Todo 状态。

## 流程产物

### 提交计划文件

| 属性 | 说明 |
|------|------|
| 输出目录 | `<项目根目录>/commit-plan/<YYYYMM>/` |
| 文件名格式 | `YYYYMMDDHHmmss_commit_plan.md` |
| 示例 | `commit-plan/202603/20260328120834_commit_plan.md` |

文件结构如下：

```markdown
# Git 提交计划

> 分析时间：2026-03-28 12:08
> 发现仓库：3 个（backend、frontend、ai-service）
> 工作区路径：/Users/dev/my-project
> 操作系统：macOS

## 提交进度

| 序号 | 仓库 | Commit Message | 文件数 | 状态 | 提交 ID |
|------|------|----------------|--------|------|---------|
| 1 | backend | `chore: 更新 .gitignore` | 2 | ✅已完成 | a1b2c3d |
| 2 | backend | `fix: 修复分页查询` | 1 | ⬜未完成 | - |
| ... | ... | ... | ... | ... | ... |

---

## 📦 仓库 1：backend
> 路径：/Users/dev/my-project/backend
> 分支：main
> 基准 HEAD：e5f6g7h (feat: 上次提交的功能)
> 待提交文件数：3（新增 1 个 / 修改 2 个 / 删除 0 个）
> 提交点：2 个

✅### Commit 1: 更新 .gitignore
**Commit Message**: `chore: 更新 .gitignore`
**涉及文件** (2 个)：

| 文件路径 | 状态 | 变更量 |
|----------|------|--------|
| `.gitignore` | M 修改 | +5 -0 |
| `README.md` | M 修改 | +12 -3 |

**执行指令：**
git add ".gitignore" "README.md"
git commit -m "chore: 更新 .gitignore"

---

⬜### Commit 2: 修复分页查询
...

---

## 📊 变更总览

| Commit | 端 | 功能模块 | 变更类型 | 文件数 | 新增行 | 删除行 |
|--------|----|----------|----------|--------|--------|--------|
| 1 | 通用 | 基础设施 | chore | 2 | +17 | -3 |
| 2 | 后端 | 数据查询 | fix | 1 | +5 | -3 |
| 3 | 前端 | 登录页面 | feat | 4 | +220 | -0 |
```

**核心元素：**

- **提交进度汇总表** — 文件顶部一览所有 Commit 的状态和提交 ID
- **基准 HEAD** — 记录计划生成时的基准点，出问题时可快速回溯
- **状态标记** — 每个 Commit 章节标题前带 `⬜`（未完成）或 `✅`（已完成）
- **文件变更表** — 每个文件标注状态（A/M/D/R）和变更行数
- **执行指令** — 每个 Commit 包含可直接复制执行的 `git add` + `git commit -m` 命令
- **风险标记** — 自动识别并标注 ⚠️ 可疑文件（二进制/大文件）和 🔴 敏感文件
- **变更总览** — 计划末尾按 Commit 汇总端归属、功能模块、变更类型和代码行数，快速了解整体改动全貌

### Todo 清单

生成结构化待办清单，每个提交点对应一项（字段与 id 规则见 SKILL.md「阶段 4」）：

```
☐ [backend] Commit 1: chore: 更新 .gitignore (2 个文件)
☐ [backend] Commit 2: fix: 修复分页查询 (1 个文件)
☑ [frontend] Commit 1: chore: 更新工程配置 (5 个文件)
...
```

## 触发关键词

以下表述均可触发此 Skill：

| 说法 | 效果 |
|------|------|
| `生成提交计划` | 完整流程：扫描 → 预检 → 分析 → 生成计划 |
| `整理代码提交` | 同上 |
| `规划 Git 提交` | 同上 |
| `批量提交代码` | 同上 |
| `更新状态` / `刷新状态` | 检查已提交的 Commit，更新计划文件 |
| `执行 xxx Commit N` | 执行指定提交点 |

## 安全保证

此 Skill 严格限制 Git 操作范围：

| 允许 | 禁止 |
|------|------|
| `git status` / `diff` / `log` | `git push`（任何形式） |
| `git add <files>` | `git merge` / `rebase` |
| `git commit -m` / `-F` | `git reset --hard` / `reset HEAD~` |
| | `git checkout` / `switch`（切分支） |
| | `git clean`（删除未跟踪文件） |
| | `git rm`（删除仓库文件） |
| | `git config`（修改配置） |

**绝不会自动推送代码到远程仓库**，所有提交仅在本地执行。

## 文件预检

在生成计划前自动进行三项安全检查：

| 检查项 | 标记 | 处理方式 |
|--------|------|----------|
| 二进制文件（`.exe`/`.zip`/`.png` 等） | ⚠️ | 标注提醒，建议加入 `.gitignore` |
| 大文件（>1MB） | ⚠️ | 标注提醒，建议确认是否需要提交 |
| 敏感文件（`.env`/`*.key`/`*.pem` 等） | 🔴 | 默认排除，需手动确认才纳入 |

## 变更总览

每份提交计划末尾自动生成变更总览表格，从全局视角呈现本次提交的改动全貌：

| 字段 | 说明 |
|------|------|
| **Commit** | 提交序号 |
| **端** | `前端` / `后端` / `全栈`（同时涉及前后端）/ `通用`（配置、文档等） |
| **功能模块** | 根据目录结构推断，如 `用户认证`、`中间件`、`基础设施` 等 |
| **变更类型** | 与 Commit Message 的 type 前缀一致（feat / fix / refactor / chore ...） |
| **文件数** | 该 Commit 涉及的文件总数 |
| **新增行 / 删除行** | 汇总 `git diff --stat` 的行数统计 |

## 支持的项目结构

| 结构 | 示例 | 支持 |
|------|------|------|
| 单仓库 | 项目根目录即 Git 仓库 | ✅ |
| 多仓库（Polyrepo） | `backend/`、`frontend/` 各自独立仓库 | ✅ |
| Monorepo + 子仓库 | 根目录是仓库，子目录也有独立仓库 | ✅ |
| Submodule | 子目录通过 `git submodule` 引入 | ✅ |
| 非 Git 目录 | 建议先 `git init`，可辅助按修改时间分析 | ✅ |
