---
name: git-commit-planner
description: Git 代码提交计划管理工具。扫描工作区内所有 Git 仓库，按功能模块和时间线分析文件改动，生成结构化的多提交点计划，并通过 Todo 逐步执行 git add/commit。当用户要求整理代码提交、规划 Git 提交、批量提交代码或生成 commit 计划时使用此技能。
---

# Git 提交计划管理

扫描工作区代码仓库，分析文件改动，生成结构化提交计划，通过 Todo 安全执行提交。

## 安全红线

**绝对禁止执行以下命令：**
- `git push`（任何形式）
- `git merge`
- `git rebase`
- `git reset --hard`
- `git reset HEAD~`（回退提交）
- `git checkout` / `git switch`（切换分支）
- `git branch -D` / `-d`（删除分支）
- `git stash drop`
- `git clean`（任何形式，会不可逆删除未跟踪文件）
- `git rm`（任何形式，会从仓库中删除文件）
- `git remote` 的任何修改操作
- `git config` 的任何修改操作

**仅允许执行：**
- `git status`、`git diff`、`git log`（只读查询）
- `git init`（仅在用户明确要求初始化时）
- `git add <files>`（添加指定文件到暂存区）
- `git commit -m "<message>"`（提交暂存区文件，优先使用此方式）
- `git commit -F <file>`（当 `-m` 因 Shell 编码问题失败时的回退方式，**禁止**使用 `--trailer` 参数）

## 术语对照（多 IDE）

本文档使用规范名，实际工具名按当前 IDE 取用：

| 文档用语 | Claude Code | Cursor | Codex |
|----------|-------------|--------|-------|
| **按串替换的改文件工具** | `Edit` | `StrReplace` | `apply_patch` |
| **待办清单工具** | `TodoWrite`（**无 `id` 字段、用户不可勾选**）| `todo_write`（有 id、可勾选）| 无 → 在回复正文维护编号清单 |
| **写文件工具** | `Write` | `Write` | `apply_patch` |
| 执行命令 | `Bash` | `Shell` | `shell` |

> 若当前 IDE 没有待办清单工具，或其待办不可被用户勾选，按「阶段 4」的**正文编号清单**降级方案执行。

## 通用常量

以下常量在多个阶段的脚本中复用，**新增排除项时只需修改此处**：

- **排除目录**：`node_modules`、`.venv`、`vendor`、`__pycache__`、`.cursor`、`.claude`、`.agents`、`.worktrees`、`dist`、`.vite`、`logs`、`log`、`.git`
- **排除扩展名**：`.exe`、`.dll`、`.so`、`.dylib`、`.pyc`

## 执行脚本（阶段 5 必用）

| 脚本 | 环境 | 参数 |
|------|------|------|
| `scripts/git_add_commit.ps1` | Windows PowerShell | `(1) RepoPath` `(2) Files`（逗号分隔） `(3) CommitMsg` |
| `scripts/git_add_commit.sh` | Bash / Git Bash | 同上，位置参数 |

详见「阶段 5：执行提交」。

## 工作流程

### 阶段 1：仓库识别

**必须同时执行以下两步**，不能只查根目录就停止：

**步骤 1 - 检查根目录：**
```bash
git -C "<workspace_root>" rev-parse --git-dir 2>&1
```

**步骤 2 - 扫描所有子目录（无论步骤 1 结果如何都要执行）：**

使用以下脚本扫描项目目录下所有 Git 仓库（排除项见「通用常量」）：

```powershell
# PowerShell - 扫描 Git 仓库（排除项见通用常量）
$rootPath = "<workspace_root>"
$excludeDirs = @("node_modules", ".venv", "vendor", "__pycache__", ".cursor", ".claude", ".agents", ".worktrees", "dist", ".vite")
$gitRepos = @()

# 检查根目录
if (Test-Path (Join-Path $rootPath ".git")) {
    $gitRepos += $rootPath
}

# 递归扫描子目录（深度 3 层），排除依赖目录
Get-ChildItem -Path $rootPath -Directory -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
    Where-Object {
        $dir = $_
        -not ($excludeDirs | Where-Object { $dir.FullName -match "\\$_" })
    } |
    ForEach-Object {
        if (Test-Path (Join-Path $_.FullName ".git")) {
            $gitRepos += $_.FullName
        }
    }

# 输出结果
$gitRepos | ForEach-Object { Write-Output $_ }
```

```bash
# Bash/Linux - 扫描 Git 仓库（同时匹配 .git 目录和 submodule 文件，排除项见通用常量）
find "<workspace_root>" -maxdepth 4 -name ".git" \( -type d -o -type f \) \
    -not -path "*/node_modules/*" \
    -not -path "*/.venv/*" \
    -not -path "*/vendor/*" \
    -not -path "*/__pycache__/*" \
    -not -path "*/.cursor/*" \
    -not -path "*/.claude/*" \
    -not -path "*/.agents/*" \
    -not -path "*/.worktrees/*" \
    2>/dev/null | xargs -I{} dirname {}
```

**常见项目结构（都要能识别）：**

| 结构类型 | 示例 | 说明 |
|----------|------|------|
| 单仓库 | 根目录就是 Git 仓库 | 直接分析根目录 |
| 多仓库（Polyrepo） | 根目录非仓库，`backend/`、`frontend/` 各自独立仓库 | 分别分析每个子仓库 |
| Monorepo + 子仓库 | 根目录是仓库，子目录也有独立仓库 | 注意区分，避免重复提交 |
| Submodule | 根目录是仓库，子目录通过 submodule 引入 | `.git` 为文件而非目录，需特殊识别；submodule 内部改动不建议在父仓库中提交 |

**输出格式：**
```
🔍 仓库扫描结果：

根目录: <workspace_root>
├── [✓ Git 仓库] 或 [✗ 非 Git 仓库]

子目录仓库：
1. <子仓库路径1> [分支: main]
2. <子仓库路径2> [分支: dev]
3. <子仓库路径3> [分支: main]

共发现 N 个 Git 仓库。
```

**对每个发现的仓库**，获取分支信息：
```bash
git -C "<repo_path>" branch --show-current 2>&1
```

若整个工作区均未找到 Git 仓库，按「边界场景 - 未初始化 Git 仓库」处理。

### 阶段 2：变更分析

**逐个仓库分析**，对每个仓库分别执行（**统一用 `git -C <repo_path>` 指定仓库路径**，不要依赖「切换工作目录」类参数——各 IDE 的 shell 工具未必支持）：

**情况 A：已有提交历史的仓库**
```bash
git -C "<repo_path>" status --porcelain
git -C "<repo_path>" diff --name-only
git -C "<repo_path>" diff --cached --name-only
git -C "<repo_path>" log --oneline -20
```

**情况 B：新初始化/无提交历史的仓库**
```bash
# 列出所有未跟踪文件
git -C "<repo_path>" status --porcelain
```

**情况 C：目录不是 Git 仓库**

⚠️ 该目录非 Git 仓库，无法直接生成提交计划。按以下优先级处理：

1. **优先建议初始化**：按「边界场景 - 未初始化 Git 仓库」处理，初始化后转入情况 B 的流程
2. **仅在用户明确要求时**才执行文件修改时间分析（作为辅助参考，不产出可执行的 git 指令）：

```powershell
# PowerShell - 辅助分析（排除项见通用常量）
Get-ChildItem -Path "<dir_path>" -Recurse -File |
  Where-Object { $_.FullName -notmatch '(node_modules|\.venv|vendor|__pycache__|\.cursor|\.claude|\.agents|\.worktrees|dist|\.vite|logs|log|\.git)' -and $_.Extension -notin '.exe','.dll','.so','.dylib','.pyc' } |
  Sort-Object LastWriteTime -Descending | Select-Object LastWriteTime, FullName
```

```bash
# Bash/Linux - 辅助分析（排除项见通用常量）
EXCLUDE="node_modules|\.venv|vendor|__pycache__|\.cursor|\.claude|\.agents|\.worktrees|dist|\.vite|logs|log|\.git"
find "<dir_path>" -type f | grep -Ev "$EXCLUDE" | while read f; do stat --format="%Y %y %n" "$f" 2>/dev/null; done | sort -rn | head -200
```

3. 分析结果仅作为后续 `git init` + 首次提交的参考，不生成正式的提交计划

**分析维度：**
1. **文件修改时间线**：按日期分组
2. **功能模块归属**：按目录结构和文件名推断所属模块
3. **跨仓库关联**：若多个子仓库属于同一项目（如 backend + frontend），识别同一功能在不同仓库中的关联文件，在计划中标注关联关系

**多仓库场景：**
- 每个仓库**独立生成提交计划**（因为 git commit 是仓库级别的操作）
- 按仓库分组输出，标题注明仓库名
- 若存在跨仓库的功能关联，在备注中说明建议的提交顺序（如先 backend 再 frontend）

### 阶段 2.5：文件预检

对所有待提交文件进行以下检查，在生成计划前识别潜在问题：

**1. 二进制文件检测**：以下扩展名的文件标记为 ⚠️ 可疑：

`.exe`、`.dll`、`.so`、`.dylib`、`.bin`、`.dat`、`.zip`、`.tar`、`.tar.gz`、`.rar`、`.7z`、`.png`、`.jpg`、`.jpeg`、`.gif`、`.bmp`、`.ico`、`.mp4`、`.mp3`、`.wav`、`.avi`、`.pdf`、`.doc`、`.docx`、`.xls`、`.xlsx`、`.ppt`、`.pptx`、`.woff`、`.woff2`、`.ttf`、`.eot`

**2. 大文件检测**：文件体积超过 **1MB** 的标记为 ⚠️ 可疑：
```powershell
# PowerShell - 检查大文件（>1MB）
Get-ChildItem -Path "<repo_path>" -Recurse -File | Where-Object { $_.Length -gt 1MB } | Select-Object @{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}}, FullName
```
```bash
# Bash - 检查大文件（>1MB）
find "<repo_path>" -type f -size +1M -exec ls -lh {} \; 2>/dev/null
```

**3. 敏感文件检测**：以下文件名模式标记为 🔴 高危：

`.env`、`.env.*`、`credentials.*`、`*secret*`、`*password*`、`*.pem`、`*.key`、`id_rsa*`、`*.p12`、`*.pfx`

**处理方式**：
- ⚠️ 可疑文件：在计划中标注 `⚠️`，提示用户确认是否需要提交，并建议加入 `.gitignore`
- 🔴 高危文件：在计划中标注 `🔴 敏感文件`，**默认不纳入提交计划**，需用户明确要求才加入
- 提交计划的文件列表中标注示例：
  ```
  - `build/app.exe` - 新增 ⚠️ 二进制文件 (50MB)，建议加入 .gitignore
  - `assets/logo.png` - 新增 ⚠️ 图片文件 (2.1MB)
  - `.env.production` - 修改 🔴 敏感文件，已排除（需手动确认才纳入）
  ```

---

### 阶段 3：生成提交计划

**核心原则：**
1. 每个提交点是一个逻辑完整的功能单元
2. 提交点之间文件**不允许有交集**（同一文件只能出现在一个提交点中）
3. 按时间线从早到晚排序
4. 同一功能的前后端文件归入同一提交点
5. 基础设施变更（配置、脚本、文档）可单独成一个提交点

**输出文件路径：**

提交计划必须以 Markdown 文件形式输出到项目根目录下的 `commit-plan/` 目录，按年月分组：

- 目录：`<workspace_root>/commit-plan/<YYYYMM>/`
- 文件名格式：`YYYYMMDDHHmmss_commit_plan.md`（如 `20260327231542_commit_plan.md`）
- 完整路径示例：`commit-plan/202603/20260327231542_commit_plan.md`
- 若 `commit-plan/<YYYYMM>/` 目录不存在，自动创建

**⚠️ 获取精确时间（必须执行）：** AI 不具备内置实时时钟，**严禁自行编造或估算时间戳**。必须通过 Shell 命令获取当前精确时间，将输出作为文件名、目录名和文档中"分析时间"的唯一来源：

```powershell
# PowerShell
$yyyymm = Get-Date -Format "yyyyMM"
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
```

```bash
# Bash/Linux
YYYYMM=$(date +"%Y%m")
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
```

使用 Write 工具将计划写入文件，同时在对话中展示给用户。

**输出模板（多仓库时每个仓库独立一个区块）：**

```markdown
# Git 提交计划

> 分析时间：<当前时间>
> 发现仓库：<N> 个（仓库A、仓库B、...）
> 工作区路径：<workspace_root>
> 操作系统：<Windows/macOS/Linux>

## 提交进度

| 序号 | 仓库 | Commit Message | 文件数 | 状态 | 提交 ID |
|------|------|----------------|--------|------|---------|
| 1 | 仓库A | `<type>: <描述1>` | N | ⬜未完成 | - |
| 2 | 仓库A | `<type>: <描述2>` | N | ⬜未完成 | - |
| 3 | 仓库B | `<type>: <描述3>` | N | ⬜未完成 | - |
| ... | ... | ... | ... | ... | ... |

---

## 📦 仓库 1：<仓库名称>
> 路径：<仓库绝对路径>
> 分支：<分支名>
> 基准 HEAD：<commit_short_hash> (<commit_subject>)
> 待提交文件数：<总文件数>（新增 A 个 / 修改 M 个 / 删除 D 个）
> 提交点：<N> 个

⬜### Commit 1: <简要描述>
**Commit Message**: `<type>: <中文描述>`
**涉及文件** (<M> 个)：

| 文件路径 | 状态 | 变更量 |
|----------|------|--------|
| `path/to/file1` | M 修改 | +45 -12 |
| `path/to/file2` | A 新增 | +120 |

状态映射（对应 `git status --porcelain` 输出）：`A 新增`（`??` 或 `A`）、`M 修改`（`M`）、`D 删除`（`D`）、`R 重命名`（`R`）。变更量通过 `git diff --stat` 获取，未跟踪文件用 `wc -l` 估算。

**执行指令：**

```bash
cd <仓库绝对路径>
git add "path/to/file1" "path/to/file2"
git commit -m "<type>: <中文描述>"
```

---

⬜### Commit 2: <简要描述>
...

---

## 📦 仓库 2：<仓库名称>
> 路径：...
...

---

## 📊 变更总览

| Commit | 端 | 功能模块 | 变更类型 | 文件数 | 新增行 | 删除行 |
|--------|----|----------|----------|--------|--------|--------|
| 1 | 后端 | 用户认证 | feat | 3 | +180 | -12 |
| 2 | 后端 | 数据库 | fix | 1 | +5 | -3 |
| 3 | 前端 | 登录页面 | feat | 4 | +220 | -0 |
| 4 | 通用 | 基础设施 | chore | 2 | +15 | -0 |
| 5 | 后端 | 中间件 | test | 1 | +85 | -0 |

> **端分类**：`前端` / `后端` / `全栈`（同时涉及前后端） / `通用`（配置、文档、脚本等与端无关的文件）
>
> **功能模块**：根据文件所在目录和改动内容推断，如 `用户认证`、`订单管理`、`数据库`、`中间件`、`路由`、`基础设施` 等
>
> **变更类型**：与 Commit Message 的 type 前缀一致（feat / fix / refactor / docs / chore / perf / test / style）
>
> **关键文件**：该 Commit 中最核心的 1 个文件路径（变更量最大或最能代表该功能的文件）
```

**变更总览生成规则：**

提交计划文件的**末尾**必须包含「📊 变更总览」表格，汇总所有 Commit 的维度信息：

1. **端分类**（根据文件路径和仓库名推断）：
   - `前端`：文件位于 `frontend/`、`web/`、`src/views/`、`src/components/` 等目录，或扩展名为 `.vue`、`.tsx`、`.jsx`、`.css`、`.scss`、`.html`
   - `后端`：文件位于 `backend/`、`server/`、`api/`、`app/`、`cmd/` 等目录，或扩展名为 `.go`、`.java`、`.py`、`.rs`
   - `全栈`：同一个 Commit 中同时包含前端和后端文件
   - `通用`：与端无关的文件，如 `.gitignore`、`README.md`、`Makefile`、`Dockerfile`、CI 配置等
2. **功能模块**：根据文件所在**一级/二级目录名**和文件内容推断，如 `用户认证`、`订单管理`、`数据库`、`中间件`、`路由`、`基础设施`、`构建部署` 等
3. **变更类型**：直接取 Commit Message 的 type 前缀
4. **新增行 / 删除行**：汇总该 Commit 所有文件的 `git diff --stat` 结果

**状态标记规则：**
1. 每个 `### Commit` 标题前必须带状态图标前缀：`⬜` 表示未完成，`✅` 表示已完成
2. 文件顶部的「提交进度」汇总表与各 Commit 章节的状态标记必须保持同步
3. **兼容性说明**：若用户反馈 emoji 显示异常，可切换为纯文本标记：`⬜` → `[ ]`，`✅` → `[x]`；汇总表中 `⬜未完成` → `未完成`，`✅已完成` → `已完成`

**指令生成规则：**
1. `git add` 列出该 Commit 涉及的**所有文件路径**（相对于仓库根目录），每个路径用双引号包裹
2. `git commit -m` 的消息与 **Commit Message** 字段完全一致
3. 文件路径过多时（超过 50 个），`git add` 拆分为多条命令，每条不超过 50 个路径
4. 若文件路径含空格或特殊字符，确保双引号转义正确

**Commit Message 风格（Conventional Commits + 中文）：**

| 前缀 | 用途 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat: 实现用户认证模块` |
| `fix` | 修复 | `fix: 修复分页查询越界问题` |
| `refactor` | 重构 | `refactor: 重构数据源加载逻辑` |
| `docs` | 文档 | `docs: 更新系统架构文档` |
| `style` | 样式 | `style: 统一表格组件样式` |
| `chore` | 杂项 | `chore: 更新部署脚本` |
| `perf` | 性能 | `perf: 优化批量查询性能` |
| `test` | 测试 | `test: 添加限流中间件测试` |

可添加 scope：`feat(scenario): 实现场景步骤编排功能`

### 阶段 4：确认与执行

生成计划后，创建待办清单，**每个提交点一项**。

**清单项文案（所有 IDE 一致）**：

```
[<仓库目录名>] Commit <N>: <type>: <描述> (<M> 个文件)
```

单仓库时可省略 `[<仓库目录名>]` 前缀。仓库标识保持**原始目录名**，方便用户识别。

**按 IDE 的落地方式**

| IDE | 落地方式 |
|-----|----------|
| **Claude Code** | `TodoWrite`，字段仅 `content` / `status` / `activeForm`，**没有 `id`**。提交点的定位靠 `content` 里的 `[仓库名] Commit N` 前缀，**不要**臆造 id 字段 |
| **Cursor** | `todo_write`，可额外给 `id`（规则见下） |
| **Codex / 无待办工具** | 在回复正文输出编号清单，等待用户回复序号 |

**Cursor 的 Todo ID slug 化规则**（仅 Cursor 需要）：对仓库目录 basename 做 slug 化，确保 ID 只含 `[a-z0-9-]`：

1. 取仓库路径最后一级目录名 → 2. 转小写 → 3. 非字母数字替换为 `-` → 4. 合并连续 `-` 并去首尾 `-` → 5. 若结果为空（如纯中文目录名）则用 `repo1`、`repo2`

| 仓库目录名 | slug 化结果 | Todo ID 示例 |
|------------|-------------|-------------|
| `backend` | `backend` | `backend-commit-1` |
| `gin_core` | `gin-core` | `gin-core-commit-1` |
| `前端项目_v2.0` | `v2-0` | `v2-0-commit-1` |
| `my project (copy)` | `my-project-copy` | `my-project-copy-commit-1` |

**等待用户确认后再执行。**

> ⚠️ **不要假设用户能勾选待办项** —— Claude Code 的待办清单是只读展示，Codex 没有待办工具。
> 因此必须在回复中**明确问一句**「确认执行哪几个提交点？（可回复序号，如 `1,2` 或 `全部`）」，
> 并等待用户的**文字回复**。仅凭待办项状态变化推断用户意图是错误的。

用户可以：
- 回复要执行的提交点序号 → 执行对应提交
- 要求调整某个提交点的文件归属或 message
- 要求合并/拆分某些提交点

### 阶段 5：执行提交

当用户**文字确认**执行某个提交点时（见阶段 4 的确认要求）：

1. **读取提交计划文件**：从最新的计划文件中获取对应 Commit 的执行指令
2. **确定目标仓库路径**（从待办项的仓库标识解析），后续所有 git 命令必须用 `git -C "<repo_path>"` 指定仓库，**禁止**依赖 shell 工具的工作目录参数
3. **再次确认 commit message**，必须与计划中的完全一致，不可修改
4. **执行前暂存区预检**：
   ```bash
   git -C "<repo_path>" diff --cached --name-only
   ```
   - 若输出为空（暂存区干净）：正常继续下一步
   - 若输出不为空：列出已暂存的文件，与当前 Commit 计划的文件列表对比
     - 若完全一致：跳过 `git add`，直接执行 `git commit`
     - 若存在**不属于当前 Commit 计划的文件**：暂停执行，向用户报告异常暂存文件列表，等待用户选择：
       - (a) 先 `git reset HEAD` 清空暂存区再重新执行
       - (b) 将这些文件也纳入当前 Commit
       - (c) 取消当前 Commit

5. 暂存区确认干净后，**必须**调用本 Skill 自带脚本执行 `git add` + `git commit`（**禁止**在对话里手写零散 `git add`/`git commit`，避免 Windows 编码与暂存区竞态）：

   **脚本路径**（相对本 Skill 根目录）：
   - Windows / PowerShell：`scripts/git_add_commit.ps1`
   - Bash / Git Bash / macOS / Linux：`scripts/git_add_commit.sh`

   **参数（固定 3 个）**：

   | 序号 | 参数 | 说明 |
   |------|------|------|
   | 1 | 执行路径 | Git 仓库根目录绝对路径 |
   | 2 | add 的文件 | 逗号分隔的相对仓库根路径列表 |
   | 3 | commit-msg | 与计划中 Commit Message **完全一致** |

   ```powershell
   # PowerShell（推荐 Windows）
   & "<skill_root>\scripts\git_add_commit.ps1" `
     "<repo_path>" `
     "path/to/file1,path/to/file2" `
     "<type>: <中文描述>"
   ```

   ```bash
   # Bash
   bash "<skill_root>/scripts/git_add_commit.sh" \
     "<repo_path>" \
     "path/to/file1,path/to/file2" \
     "<type>: <中文描述>"
   ```

   **脚本行为**：
   - 校验路径为 Git 仓库；解析逗号分隔文件列表
   - 暂存区预检：有非计划文件则 `RESULT: FAIL` 并中止（**不**自动 `reset`）
   - 暂存区已与计划完全一致时跳过 `git add`，直接 `commit`
   - 使用 UTF-8（无 BOM）写入 `.git/COMMIT_MSG_TEMP` + `git commit -F`，提交后清理临时文件
   - 成功输出 `RESULT: OK` 与 `COMMIT: <hash> <subject>`；失败非零退出

   **仅在脚本不可用时**才允许回退到手写命令（须说明原因）：

   **回退方案 1（Bash/Zsh）— HEREDOC**：
   ```bash
   git -C "<repo_path>" add -- "path/to/file1" "path/to/file2"
   git -C "<repo_path>" commit -m "$(cat <<'EOF'
   <type>: <中文描述>
   EOF
   )"
   ```

   **回退方案 2（PowerShell）— -F 临时文件**：
   - 用 Write 工具将 commit message 写入 `<repo_path>/.git/COMMIT_MSG_TEMP`（UTF-8）
   - `git -C "<repo_path>" add -- ...` 后 `git -C "<repo_path>" commit -F .git/COMMIT_MSG_TEMP`
   - **无论成功或失败**都必须删除 `.git/COMMIT_MSG_TEMP`
6. 验证提交结果：
   ```bash
   git log -1 --oneline
   git status
   ```
7. **更新计划文件状态**：按「阶段 6：状态更新」步骤 3 的规则，使用**按串替换的改文件工具**（见「术语对照」）更新计划文件（替换状态标记 `⬜→✅` 和填写提交 ID）
8. 更新待办项状态为 `completed`（无待办工具时，在正文清单上标 ✅）
9. 输出执行结果摘要（含仓库名、commit hash、文件数量）

**单个提交失败时：**
- 输出错误信息
- 不继续后续提交
- 等待用户指示

### 阶段 6：状态更新

当用户要求「更新状态」或「刷新状态」时，执行以下流程：

1. **读取计划文件**：从计划目录中读取最新的提交计划文件
2. **逐仓库检查提交状态**：对计划中每个 Commit，用 `git log` 搜索对应的 commit message 是否已存在于仓库历史中：
   ```bash
   # 第一步：用 --grep + --fixed-strings 缩小范围（防止正则注入）
   git -C "<repo_path>" log --format="%h %s" --fixed-strings --grep="<commit_message>" -10
   ```
   **匹配规则**：`--format="%s"` 输出的 subject 必须与计划中的 Commit Message **完全一致**（去除首尾空格后），才视为已提交。若仅为子串包含关系（如计划为 `feat: 实现用户模块`，历史为 `feat: 实现用户模块权限校验`），**不算匹配**。
3. **更新计划文件**：对每个已提交的 Commit，使用**按串替换的改文件工具**（见「术语对照」）执行以下修改：
   - **汇总表格**：将对应行的 `⬜未完成` 替换为 `✅已完成`，同时将提交 ID 列从 `-` 替换为 `git log` 返回的 commit short hash（如 `a1b2c3d`）
   - **Commit 章节标题**：将 `⬜### Commit N:` 替换为 `✅### Commit N:`
4. **同步更新待办状态**：将对应待办项标记为 `completed`（无待办工具时在正文清单标 ✅）
5. **输出更新摘要**：列出哪些 Commit 状态发生了变化

**示例：**

更新前：
```markdown
| 1 | backend | `chore: 更新 .gitignore` | 2 | ⬜未完成 | - |

⬜### Commit 1: 更新 .gitignore 和 README
```

更新后：
```markdown
| 1 | backend | `chore: 更新 .gitignore` | 2 | ✅已完成 | a1b2c3d |

✅### Commit 1: 更新 .gitignore 和 README
```

**注意事项：**
- 若同一 message 在 log 中出现多次（如 amend 后），只要存在精确匹配即视为已完成
- 状态只能从 `⬜未完成` 变为 `✅已完成`，不支持反向变更
- 提交 ID 列：已完成时填写 commit short hash（7 位），未完成时显示 `-`

## .gitignore 建议

若仓库缺少 `.gitignore`，在首次提交前建议创建：

```gitignore
# 通用排除
*.exe
*.dll
*.so
*.dylib
*.log
*.tmp
.env
.env.*

# Go
vendor/

# Node.js
node_modules/
dist/
.vite/

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
Thumbs.db

# 项目特定
logs/
log/
*.log.*

# worktree 隔离目录（dev-lifecycle 并行开发）
.worktrees/

# Git 提交计划（由 git-commit-planner 生成的临时文件）
commit-plan/
```

## 边界场景处理

### 未初始化 Git 仓库
- 提示用户是否需要 `git init`
- 需用户明确确认后才执行
- 初始化后建议先提交 `.gitignore`

### 文件冲突归属
- 若某文件在时间线上跨多个功能迭代，归入**最后修改时间**对应的提交点
- 共用基础文件（如 `router.go`、`index.ts`）归入其**主要改动**关联的功能提交点

### 部分执行
- 用户可以只执行部分提交点
- 已完成和未完成的提交点状态独立
- 不会影响后续提交点的文件列表
